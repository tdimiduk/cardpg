{-# LANGUAGE FieldSelectors #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE RecursiveDo #-}

-- | CSS Generator
-- This executable generates the static CSS file from the atomic classes
-- defined in the Frontend.Style modules.
--
-- The approach: We combine runtime collection from the Catalog (to catch
-- dynamic/combinator classes like `flexCol`) with static source scanning
-- (to catch `atom` definitions not present in the catalog).
module Main where

import Control.Monad (forM)
import Data.Either (rights)
import Data.IORef (newIORef)
import Data.List qualified as List
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Void (Void)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath (takeExtension, (</>))
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L
import Web.Atomic (utility)
import Web.Atomic.Types (ClassName (..), Rule (..))
import Web.Atomic.Types.Selector (Media (..))
import Web.Atomic.Types.Style (Declaration (..), Property (..))
import Web.Atomic.Types.Style qualified as AWStyle
import Web.Atomic.Types.Styleable (CSS (..))

import Reflex (PostBuildT, runPostBuildT)
import Reflex.Dom.Builder.Static (StaticDomBuilderEnv (..))
import Reflex.Dom.Core (StaticDomBuilderT, blank, elAttr, runStaticDomBuilderT, (=:))
import Reflex.PerformEvent.Base (PerformEventT, hostPerformEventT)
import Reflex.Spider (Spider)
import Reflex.Spider.Internal (Global, SpiderHost, runSpiderHost)

import Frontend.App (uiWidget)
import Frontend.Catalog (catalogWidget)
import Frontend.MockData qualified as Mock
import Frontend.Style.T (StyleWriterT, runStyleWriterT)

import Api.Types (Phase (..))
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO)
import Core.Primitives (ActorId)
import Core.State (ActorState)
import Data.Map.Strict qualified as Map
import Frontend.Style (stagedActionCard, stagedResourceCard)
import Frontend.Style.Class (StyledDomBuilder)
import Frontend.Style.Common (Style, classes)
import Reflex.Dom.Core
  ( Adjustable
  , MonadHold
  , PostBuild
  , Prerender
  , Requester
  , constDyn
  , holdDyn
  , never
  , runRequesterT
  )
import Reflex.Requester.Base (RequesterT)
import Server.Game (GameState (..))
import Server.Scenario (loadScenario)

type Parser = Parsec Void Text

main :: IO ()
main = do
  putStrLn "Generating CSS..."

  -- 1. Scan source files
  files <- findHaskellFiles "client-reflex/src"
  putStrLn $ "Scanning " <> show (length files) <> " files..."

  foundRules <- fmap concat $ forM files $ \file -> do
    content <- T.readFile file
    case parse (many (try parseAtom <|> (anySingle >> return []))) "" content of
      Left _ -> return []
      Right ruleLists -> return (concat ruleLists)

  putStrLn $ "Found " <> show (length foundRules) <> " atomic rules from source."

  -- 2. Run the catalog widget to collect styles
  replaceKeyRef <- newIORef 0
  let env = StaticDomBuilderEnv True Nothing replaceKeyRef

  let widget =
        catalogWidget
          :: StaticDomBuilderT
               Spider
               (StyleWriterT (PostBuildT Spider (PerformEventT Spider (SpiderHost Global))))
               ()
  let runner = runStaticDomBuilderT widget env
  let pRunner = runStyleWriterT runner

  ((_, _), collectedRules) <- runSpiderHost $ do
    (res, _events) <- hostPerformEventT $ runPostBuildT pRunner never
    return res

  putStrLn $ "Collected " <> show (length collectedRules) <> " rules from Catalog."

  -- 3. Load Scenario and run mock game widget for each actor/phase
  gameReplaceKeyRef <- newIORef 0
  let gameEnv = StaticDomBuilderEnv True Nothing gameReplaceKeyRef

  -- Load the starter scenario to get real actor data
  putStrLn "Loading scenario data/scenarios/starter.yaml..."
  (gameState, _) <- loadScenario "data/scenarios/starter.yaml" Nothing
  let actorsMap = gameState.actors :: Map.Map ActorId ActorState
  let actorIds = Map.keys actorsMap

  putStrLn $ "Loaded " <> show (length actorIds) <> " actors."

  -- We need to encompass both phases to get all styles
  let phases = [Planning, Resolution]

  -- Iterate over Phases AND Actors to ensure coverage
  gameRulesNested <- forM phases $ \p -> do
    forM actorIds $ \aid -> do
      let gameWidget =
            mockGameWidget p (Just aid) actorsMap
              :: StaticDomBuilderT
                   Spider
                   (StyleWriterT (PostBuildT Spider (PerformEventT Spider (SpiderHost Global))))
                   ()
      let gameRunner = runStaticDomBuilderT gameWidget gameEnv
      let gamePRunner = runStyleWriterT gameRunner

      ((_, _), rules) <- runSpiderHost $ do
        (res, _events) <- hostPerformEventT $ runPostBuildT gamePRunner never
        return res
      return rules

  let gameRules = concat (concat gameRulesNested)

  putStrLn $ "Collected " <> show (length gameRules) <> " rules from MockGameWidget (Scenario-based)."

  -- 4. Combine
  let allRules = foundRules ++ collectedRules ++ gameRules
      uniqueRules = List.nub allRules
      cssOutput = renderCssList uniqueRules

  let header =
        "/* This file is auto-generated by client-reflex/app/GenCss.hs */\n/* Run 'cabal run gen-css' to update */\n"
  T.writeFile "client-reflex/static/atomic.css" (header <> cssOutput)
  putStrLn $
    "Done. Wrote client-reflex/static/atomic.css with " <> show (length uniqueRules) <> " rules."

-- | Recursive file finder
findHaskellFiles :: FilePath -> IO [FilePath]
findHaskellFiles top = do
  isDir <- doesDirectoryExist top
  if isDir
    then do
      entries <- listDirectory top
      paths <- forM entries $ \e -> findHaskellFiles (top </> e)
      return $ concat paths
    else
      return [top | takeExtension top == ".hs"]

-- | Parser for `atom "name" "prop" "val"`
-- Returns a list of Rules
parseAtom :: Parser [Rule]
parseAtom = do
  _ <- string "atom"
  space
  name <- stringLiteral
  space
  prop <- stringLiteral
  space
  val <- stringLiteral

  -- Create the rule
  let (CSS rs) = utility (ClassName name) [Property prop :. AWStyle.Style (T.unpack val)] mempty :: CSS [Rule]
  return rs

-- | Parse a string literal (quoted)
stringLiteral :: Parser Text
stringLiteral = do
  _ <- char '"'
  content <- many (try escapedChar <|> noneOf ("\"\\" :: String))
  _ <- char '"'
  return $ T.pack content

escapedChar :: Parser Char
escapedChar = do
  _ <- char '\\'
  c <- anySingle
  return $ case c of
    'n' -> '\n'
    'r' -> '\r'
    't' -> '\t'
    '\\' -> '\\'
    '"' -> '"'
    _ -> c

-- | Render list of rules to CSS text
renderCssList :: [Rule] -> T.Text
renderCssList rs = T.unlines $ map renderRule rs

-- | Render a single rule
renderRule :: Rule -> T.Text
renderRule (Rule c _ med props) =
  let sel = case c of ClassName t -> escapeCssClass t
      block = "." <> sel <> " { " <> renderProps props <> " }"
   in case med of
        [] -> block
        ms -> "@media " <> renderMedia ms <> " { " <> block <> " }"

-- | Render properties
renderProps :: [Declaration] -> T.Text
renderProps ds = T.intercalate " " $ map renderDecl ds

renderDecl :: Declaration -> T.Text
renderDecl (Property p :. AWStyle.Style s) = p <> ": " <> T.pack s <> ";"

-- | Render media queries
renderMedia :: [Media] -> T.Text
renderMedia ms = T.intercalate " and " $ map renderOneMedia ms

renderOneMedia :: Media -> T.Text
renderOneMedia (MinWidth i) = "(min-width: " <> T.pack (show i) <> "px)"
renderOneMedia (MaxWidth i) = "(max-width: " <> T.pack (show i) <> "px)"

-- | Escape CSS class name (simple version)
escapeCssClass :: T.Text -> T.Text
escapeCssClass = T.concatMap escapeChar
  where
    escapeChar c
      | c `elem` ("!\"#$%&'()*+,./:;<=>?@[\\]^`{|}~" :: String) = "\\" <> T.singleton c
      | otherwise = T.singleton c

-- | Mock game widget that exercises staging and log UI for CSS collection
-- Uses the full uiWidget with mock data to capture all styles
mockGameWidget
  :: ( StyledDomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , Adjustable t m
     , MonadIO m
     , Prerender t m
     )
  => Phase
  -> Maybe ActorId
  -> Map.Map ActorId ActorState
  -> m ()
mockGameWidget phase agentId actorsMap = do
  -- Use mock actors with staged actions
  let actorsDyn = constDyn actorsMap
      logsDyn = constDyn Mock.mockLogs
      phaseDyn = constDyn phase

  -- We don't care about the return values/events for CSS generation
  -- Run with mock inputs
  rec (_, _) <-
        runRequesterT
          (uiWidget agentId actorsDyn logsDyn phaseDyn (constDyn 1) (constDyn 1))
          never
  return ()
