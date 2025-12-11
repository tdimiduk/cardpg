{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardCompiler where

import Control.Monad (forM_, unless)
import Data.Aeson (Result (..), Value (..), eitherDecode, fromJSON)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Either (partitionEithers)
import qualified Data.List.NonEmpty as NE
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Void (Void)
import Data.Yaml (encode)
import System.Directory (createDirectoryIfMissing)
import System.Exit (die)
import System.FilePath ((</>))
import Text.Megaparsec (Parsec, parseMaybe)

import CardCompiler.Parser
  ( ArmorType (..)
  , ParsedCard (..)
  , ParsedPassive (..)
  , RawCard (..)
  , convertCard
  , passiveParser
  )
import qualified CardCompiler.VttExporter as Vtt
import CardPG.Core.Card (ActorDefinitionT (..), CoreCard, ItemCard, NatureCard, NatureCardT (..))
import CardPG.Core.NonEmptyText (mkNonEmptyText)

type Parser = Parsec Void Text

run :: FilePath -> FilePath -> Maybe String -> IO ()
run inputFile outputDir tag = do
  content <- LBS.readFile inputFile
  case eitherDecode content of
    Left err -> die $ "Failed to parse JSON: " ++ err
    Right val -> do
      cards <- case val of
        Array _ -> case fromJSON val of
          Success cs -> return cs
          Error e -> die $ "Failed to parse list of cards: " ++ e
        Object _ -> case fromJSON val of
          Success (m :: Map.Map Text [RawCard]) -> return $ concat (Map.elems m)
          Error e -> die $ "Failed to parse map of cards: " ++ e
        _ -> die "Input JSON must be an array of cards or a map of character names to lists of cards"

      createDirectoryIfMissing True outputDir
      processCards outputDir cards tag

heroCard :: NatureCard
heroCard =
  NatureCard
    { _id = Nothing
    , _name = fromMaybe (error "Invalid hero name") $ mkNonEmptyText "Hero"
    , _tags = Nothing
    , _flavor = Nothing
    , _traits = Nothing
    , _passive = Nothing
    , _defense = Just 2
    , _resilience = Just 3
    , _specialDefend = Nothing
    }

processCards :: FilePath -> [RawCard] -> Maybe String -> IO ()
processCards outputDir cards tag = do
  let validCards = filter isValidCard cards
      cardsByActor = Map.fromListWith (++) [(fromMaybe "unknown" (actor c), [c]) | c <- validCards]

  forM_ (Map.toList cardsByActor) $ \(actorName, actorCards) -> do
    let results = map convertCard actorCards
        (failures, successes) = partitionEithers results

    -- Filter out "Skipping empty card row" messages to reduce noise
    let meaningfulFailures = filter (/= "Skipping empty card row") failures
    forM_ meaningfulFailures $ \err -> putStrLn $ "Failed to convert card for actor " ++ show actorName ++ ": " ++ err

    unless (null successes) $ do
      let (items, natureList, deck) = partitionCards successes

      let finalNature = case tag of
            Just "pc" -> heroCard : natureList
            Just "monster" -> map updateMonsterNature natureList
            _ -> natureList

      if length deck /= 24
        then
          putStrLn $
            "Warning: Actor "
              ++ show actorName
              ++ " has "
              ++ show (length deck)
              ++ " cards in deck. Expected 24. Skipping."
        else do
          let actorData =
                ActorDefinition
                  { _name = actorName
                  , _tags = fmap (\t -> NE.fromList [T.pack t]) tag
                  , _nature = finalNature
                  , _items = items
                  , _deck = deck
                  , _id = Just (Vtt.slugify actorName)
                  }
          let fileName = T.unpack (sanitize actorName) ++ ".yaml"
          let outputPath = outputDir </> fileName
          BS.writeFile outputPath (encode actorData)
          putStrLn $ "Wrote " ++ outputPath

isValidCard :: RawCard -> Bool
isValidCard c = case actor c of
  Nothing -> False
  Just t | T.null (T.strip t) -> False
  _ -> True

partitionCards :: [ParsedCard] -> ([ItemCard], [NatureCard], [CoreCard])
partitionCards = foldr f ([], [], [])
  where
    f (PItem i) (is, ns, cs) = (i : is, ns, cs)
    f (PNature n) (is, ns, cs) = (is, n : ns, cs)
    f (PCore c) (is, ns, cs) = (is, ns, c : cs)

sanitize :: Text -> Text
sanitize = T.replace " " "_" . T.toLower

armorDefenseMonster :: Maybe ArmorType -> Int
armorDefenseMonster Nothing = 2
armorDefenseMonster (Just LightArmor) = 3
armorDefenseMonster (Just HeavyArmor) = 4

updateMonsterNature :: NatureCard -> NatureCard
updateMonsterNature n@NatureCard{_passive = mPassive} =
  n
    { _defense = Just def
    , _resilience = Just 2
    , _passive = newPassive
    }
  where
    (def, newPassive) = case parseMaybe passiveParser =<< mPassive of
      Nothing -> (2, mPassive)
      Just ParsedPassive{..} -> (armorDefenseMonster armor, T.strip <$> remainder)
