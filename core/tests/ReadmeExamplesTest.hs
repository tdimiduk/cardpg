{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module ReadmeExamplesTest (test_readmeExamples) where

import Control.Monad (forM_)
import Data.Aeson (FromJSON, Result (..), Value (..), fromJSON)
import Data.Aeson.KeyMap qualified as KM
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Text.IO qualified as TIO
import Data.Vector qualified as V
import Data.Yaml (decodeEither')
import System.Directory (doesFileExist)
import Test.Tasty
import Test.Tasty.HUnit

import Core.Card
  ( ActorDefinition
  , ConsequenceCard
  , CoreCard
  , ItemCard
  , MasterCard
  , NatureCard
  )
import Core.DSL (parseText)
import Core.Rules (AttackDef, Rule (..))

-- | Keywords that indicate a structured rule rather than arbitrary narrative text.
structuredPrefixes :: [Text]
structuredPrefixes =
  [ "Action:"
  , "General:"
  , "Task:"
  , "When "
  , "Passive:"
  , "Ongoing "
  , "Attack "
  ]

-- | Assert that a rule string parses successfully as a Rule, and that if it begins
-- with a structured command keyword, it did NOT fall back to RuleNarrative.
checkRuleString :: Text -> Assertion
checkRuleString ruleStr = do
  case parseText @Rule ruleStr of
    Left err ->
      assertFailure $ "Failed to parse rule:\n  " ++ T.unpack ruleStr ++ "\nError: " ++ err
    Right (RuleNarrative _)
      | any (`T.isPrefixOf` T.strip ruleStr) structuredPrefixes ->
          assertFailure $
            "Structured keyword rule fell back to RuleNarrative:\n  "
              ++ T.unpack ruleStr
              ++ "\nCheck Mini-DSL syntax against grammar for structured keywords: "
              ++ unwords (map T.unpack structuredPrefixes)
    Right _ -> pure ()

-- | Assert that an attack formula string parses successfully as an AttackDef.
checkAttackString :: Text -> Assertion
checkAttackString atkStr = do
  case parseText @AttackDef atkStr of
    Left err ->
      assertFailure $ "Failed to parse attack formula:\n  " ++ T.unpack atkStr ++ "\nError: " ++ err
    Right _ -> pure ()

-- | Resolve path relative to either project root or core/ subdirectory.
resolvePath :: FilePath -> IO FilePath
resolvePath path = do
  exists <- doesFileExist path
  if exists
    then pure path
    else do
      let rel = "../" ++ path
      existsRel <- doesFileExist rel
      if existsRel
        then pure rel
        else pure path

-- | Extract all fenced ```yaml blocks from markdown content.
extractFencedYamlBlocks :: Text -> [Text]
extractFencedYamlBlocks content = go (T.lines content) False [] []
  where
    go [] _ current acc =
      case current of
        [] -> reverse acc
        _ -> reverse (T.unlines (reverse current) : acc)
    go (l : ls) inBlock current acc
      | not inBlock && "```yaml" `T.isPrefixOf` T.toLower (T.stripStart l) =
          go ls True [] acc
      | inBlock && "```" `T.isPrefixOf` T.stripStart l =
          go ls False [] (T.unlines (reverse current) : acc)
      | inBlock =
          go ls True (l : current) acc
      | otherwise =
          go ls False [] acc

-- | Assert that a JSON/YAML Value decodes into the expected schema type.
assertDecodesAs :: forall a. (FromJSON a) => String -> Value -> Assertion
assertDecodesAs typeLabel val =
  case fromJSON @a val of
    Error err ->
      assertFailure $
        "Failed to decode YAML object as " ++ typeLabel ++ ":\n  " ++ err ++ "\nValue: " ++ show val
    Success _ -> pure ()

-- | Structurally validate a parsed YAML Value:
-- 1. If an Object has a "name" field, dispatch schema validation based on its structural keys.
-- 2. Validate any "attack" string fields with checkAttackString.
-- 3. Validate any "rules" array items with checkRuleString (including non-RuleNarrative guard).
validateYamlValue :: Value -> Assertion
validateYamlValue (Array vec) = V.mapM_ validateYamlValue vec
validateYamlValue val@(Object km) = do
  -- 1. Structural schema dispatch for card/actor objects (identified by having a "name" key)
  case KM.lookup "name" km of
    Just _ ->
      if
        | KM.member "deck" km ->
            assertDecodesAs @ActorDefinition "ActorDefinition" val
        | KM.member "id" km && KM.member "stats" km ->
            assertDecodesAs @MasterCard "MasterCard" val
        | KM.member "stats" km ->
            assertDecodesAs @CoreCard "CoreCard" val
        | KM.member "severity" km ->
            assertDecodesAs @ConsequenceCard "ConsequenceCard" val
        | KM.member "burden" km || KM.member "weight" km || KM.member "value" km || KM.member "portions" km ->
            assertDecodesAs @ItemCard "ItemCard" val
        | KM.member "defense" km || KM.member "resilience" km || KM.member "traits" km ->
            -- NatureCard and ItemCard share overlapping table-card fields; accept either
            case (fromJSON @NatureCard val, fromJSON @ItemCard val) of
              (Success _, _) -> pure ()
              (_, Success _) -> pure ()
              (Error err, _) ->
                assertFailure $ "Failed to decode table card object as NatureCard or ItemCard:\n  " ++ err
        | otherwise -> pure ()
    Nothing -> pure ()

  -- 2. Validate "attack" field if present
  case KM.lookup "attack" km of
    Just (String atkTxt) -> checkAttackString atkTxt
    Just other -> assertFailure $ "Expected 'attack' field to be a String, got: " ++ show other
    Nothing -> pure ()

  -- 3. Validate "rules" list if present
  case KM.lookup "rules" km of
    Just (Array rulesVec) ->
      V.forM_ rulesVec $ \case
        String ruleTxt -> checkRuleString ruleTxt
        other -> assertFailure $ "Expected item in 'rules' list to be a String, got: " ++ show other
    Just other -> assertFailure $ "Expected 'rules' field to be an Array, got: " ++ show other
    Nothing -> pure ()
validateYamlValue _ = pure ()

-- | Validate all fenced YAML blocks in a markdown file.
validateMarkdownYamlExamples :: FilePath -> Assertion
validateMarkdownYamlExamples relPath = do
  docPath <- resolvePath relPath
  content <- TIO.readFile docPath
  let yamlBlocks = extractFencedYamlBlocks content
  assertBool
    ("Expected to find fenced YAML blocks in " ++ relPath)
    (not (null yamlBlocks))
  forM_ yamlBlocks $ \block ->
    case decodeEither' @Value (TE.encodeUtf8 block) of
      Left err ->
        assertFailure $
          "Failed to parse YAML block in " ++ relPath ++ ":\n" ++ T.unpack block ++ "\nError: " ++ show err
      Right val -> validateYamlValue val

test_readmeExamples :: TestTree
test_readmeExamples =
  testGroup
    "Documentation & Authoring Guide Examples"
    [ testCase "data/cards/README.md Syntax Examples" testReadme
    , testCase
        "design/authoring/card-schemas-and-syntax.md Mini-DSL & Schema Examples"
        (validateMarkdownYamlExamples "design/authoring/card-schemas-and-syntax.md")
    , testCase
        "design/authoring/consequences.md Mini-DSL & Schema Examples"
        (validateMarkdownYamlExamples "design/authoring/consequences.md")
    ]
  where
    testReadme = do
      readmePath <- resolvePath "data/cards/README.md"
      content <- TIO.readFile readmePath
      let ls = T.lines content
          isExampleHeader = T.isPrefixOf "- _Example:_" . T.strip
          examples = filter isExampleHeader ls
          cleanExample line =
            let stripped = T.strip line
                withoutPrefix = T.drop (T.length "- _Example:_ ") stripped
                withoutBackticks = T.replace "`" "" withoutPrefix
             in T.strip withoutBackticks

      forM_ examples $ \rawEx -> do
        let ex = cleanExample rawEx
        if "Attack " `T.isPrefixOf` ex
          then checkAttackString ex
          else checkRuleString ex
