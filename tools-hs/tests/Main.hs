{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Core.Glossary
import Data.Text (Text)
import Data.Text qualified as T
import Design.Frontmatter
import Design.Index
import Design.TOC
import Design.Types
import KeywordMod hiding (main)
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "tools-hs tests"
    [ test_glossaryParser
    , test_chunking
    , test_normalization
    , test_renaming
    , test_frontmatter
    , test_scaffolding
    , test_indexOps
    , test_tocNormalization
    ]

sampleMarkdown :: Text
sampleMarkdown =
  "# Keyword Glossary\n\
  \\n\
  \Intro text.\n\
  \\n\
  \## The Three Colors\n\
  \\n\
  \### Color\n\
  \\n\
  \_Aliases: Colors_\n\
  \\n\
  \How approaches are classified.\n\
  \\n\
  \#### Red\n\
  \\n\
  \One of the game's [[Colors]].\n"

test_glossaryParser :: TestTree
test_glossaryParser =
  testGroup
    "Glossary Parser"
    [ testCase "Parses categories, aliases, and themes correctly" $ do
        let g = parseGlossaryText sampleMarkdown
        assertEqual "Total entries" 2 (length (allEntries g))

        case lookupGlossary "Color" g of
          Nothing -> assertFailure "Did not find 'Color'"
          Just e -> do
            assertEqual "Canonical" "Color" e.canonical
            assertEqual "Slug" "color" e.slug
            assertEqual "Aliases" ["Colors"] e.aliases
            assertEqual "Category" "The Three Colors" e.category
            assertEqual "Summary" "How approaches are classified." e.summary
            assertEqual "Theme is Nothing" Nothing e.theme

        case lookupGlossary "Red" g of
          Nothing -> assertFailure "Did not find 'Red'"
          Just e -> do
            assertEqual "Canonical" "Red" e.canonical
            assertEqual "Theme is red" (Just "red") e.theme
    ]

test_chunking :: TestTree
test_chunking =
  testGroup
    "Line Chunking"
    [ testCase "Separates protected markdown links and wikilinks from regular text" $ do
        let line = "See [[Color]] and [Link](url.md) here"
            chunks = chunkLine line
        assertEqual
          "Chunks"
          [ Unprotected "See "
          , Protected "[[Color]]"
          , Unprotected " and "
          , Protected "[Link](url.md)"
          , Unprotected " here"
          ]
          chunks
    , testCase "Protects multi-backtick spans" $ do
        let line = "Code: `` `literal` `` end"
            chunks = chunkLine line
        assertEqual
          "Chunks"
          [ Unprotected "Code: "
          , Protected "`` `literal` ``"
          , Unprotected " end"
          ]
          chunks
    ]

test_normalization :: TestTree
test_normalization =
  testGroup
    "Markdown Normalization"
    [ testCase "Replaces backticks and bold with wikilinks without duplicating brackets" $ do
        let terms = ["Color", "Colors", "Red"]
            pluralPairs = [("Colors", "Color")]
            line = "Use `Color` and `Color`s and **Red** and [[Color]]"
            transformed = transformLine terms pluralPairs line
        assertEqual "Result" "Use [[Color]] and [[Colors]] and [[Red]] and [[Color]]" transformed
    , testCase "Preserves headings" $ do
        let terms = ["Color"]
            pluralPairs = []
            line = "## The Color System"
            transformed = transformLine terms pluralPairs line
        assertEqual "Unchanged heading" line transformed
    , testCase "Preserves fenced code blocks" $ do
        let terms = ["Color"]
            content = "Before `Color`\n```\nInside `Color`\n```\nAfter `Color`\n"
            (newContent, count) = transformContent terms content
        assertEqual "Changed line count" 2 count
        assertEqual "Content" "Before [[Color]]\n```\nInside `Color`\n```\nAfter [[Color]]\n" newContent
    ]

test_renaming :: TestTree
test_renaming =
  testGroup
    "Keyword Renaming"
    [ testCase "Renames across wikilinks, backticks, and bold" $ do
        let content = "Use `OldKw` and [[OldKw]] and **OldKw**."
            (newContent, count) = renameContent "OldKw" "NewKw" content
        assertEqual "Changes" 1 count
        assertEqual "Result" "Use [[NewKw]] and [[NewKw]] and [[NewKw]]." newContent
    ]

test_frontmatter :: TestTree
test_frontmatter =
  testGroup
    "Frontmatter Parsing & Schema"
    [ testCase "Extracts valid frontmatter and body" $ do
        let sample =
              "---\ntitle: Test Doc\ndoc_type: rules\ntrack: ludology\norigin: Human authored\nepistemic_status:\n  confidence: high\n  vetted_by_human: true\n---\n\n# Body heading\nBody text."
        case extractFrontmatterText sample of
          Left err -> assertFailure err
          Right Nothing -> assertFailure "Expected frontmatter"
          Right (Just (yamlText, bodyText)) -> do
            assertBool "Body contains heading" ("# Body heading" `T.isInfixOf` bodyText)
            case parseFrontmatter yamlText of
              Left err -> assertFailure err
              Right (fm, errs) -> do
                assertEqual "Schema errors" [] errs
                assertEqual "Title" "Test Doc" fm.title
                assertEqual "DocType" "rules" fm.docType
                assertEqual "Track" (Just Ludology) fm.track
                assertEqual "Origin" (Just "Human authored") fm.origin
                case fm.epistemicStatus of
                  Nothing -> assertFailure "Expected epistemicStatus"
                  Just es -> do
                    assertEqual "Confidence" High es.confidence
                    assertEqual "Vetted" (VettedBool True) es.vettedByHuman
    , testCase "Catches obsolete 'status' in epistemic_status" $ do
        let sampleYaml =
              "title: Obsolete Test\ndoc_type: rules\ntrack: ludology\norigin: test\nepistemic_status:\n  status: active\n  confidence: high\n  vetted_by_human: true\n"
        case parseFrontmatter sampleYaml of
          Left err -> assertFailure err
          Right (_, errs) -> do
            assertBool "Contains obsolete status error" (any ("Obsolete field 'status'" `isInfixOfStr`) errs)
    , testCase "Catches invalid confidence tier" $ do
        let sampleYaml =
              "title: Bad Conf\ndoc_type: rules\ntrack: ludology\norigin: test\nepistemic_status:\n  confidence: ultra-high\n  vetted_by_human: true\n"
        case parseFrontmatter sampleYaml of
          Left err -> assertFailure err
          Right (_, errs) -> do
            assertBool "Contains invalid confidence error" (any ("Invalid 'confidence'" `isInfixOfStr`) errs)
    ]
  where
    isInfixOfStr needle haystack = needle `T.isInfixOf` T.pack haystack

test_scaffolding :: TestTree
test_scaffolding =
  testGroup
    "Frontmatter Scaffolding"
    [ testCase "Scaffolds synthesis doc under research/synthesis" $ do
        let content = "# Dynamic Injury Mechanics\n\nFirst paragraph of text."
            (fm, newContent) = scaffoldFrontmatter "research/synthesis/injury-mechanics.md" content
        assertEqual "Title from heading" "Dynamic Injury Mechanics" fm.title
        assertEqual "DocType" "synthesis" fm.docType
        assertEqual "Track" (Just Verisimilitude) fm.track
        assertBool "Contains --- fence" ("---\n" `T.isPrefixOf` newContent)
        assertBool "Contains body" ("First paragraph" `T.isInfixOf` newContent)
    ]

test_indexOps :: TestTree
test_indexOps =
  testGroup
    "Index Operations"
    [ testCase "Extracts leading comment header" $ do
        let yamlContent = "# Header line 1\n# Header line 2\n\nroot_key:\n  child: value\n"
            (header, rest) = extractHeaderComments yamlContent
        assertEqual "Header comments" "# Header line 1\n# Header line 2\n\n" header
        assertEqual "Rest" "root_key:\n  child: value\n" rest
    , testCase "Resolves index target based on path" $ do
        assertEqual
          "synthesis target"
          ("research/index.yaml", ["design_process_and_research", "research_synthesis"])
          (resolveIndexTarget "research/synthesis/foo.md" "synthesis")
        assertEqual
          "readings target"
          ("research/index.yaml", ["design_process_and_research", "design_theory_and_readings"])
          (resolveIndexTarget "research/theory/readings/bar.md" "literature-note")
        assertEqual
          "iteration target"
          ("iteration/index.yaml", ["active_design_exploration", "ideation_and_sketches"])
          (resolveIndexTarget "iteration/sketch.md" "iteration")
        assertEqual
          "module target"
          ("index.yaml", ["game_system_and_rules", "modules"])
          (resolveIndexTarget "rules/modules/mod.md" "module")
    ]

test_tocNormalization :: TestTree
test_tocNormalization =
  testGroup
    "TOC Normalization"
    [ testCase "Normalizes table separators and synced footers" $ do
        let block1 =
              "<!-- BEGIN AUTO-TOC -->\n| Col1 | Col2 |\n| :--- | :--- |\n| A | B |\n\n_Last synced from `design/index.yaml` via `tools/audit_index.py`._\n<!-- END AUTO-TOC -->"
            block2 =
              "<!-- BEGIN AUTO-TOC -->\n| Col1 | Col2 |\n| :--- | :--- |\n| A | B |\n\n*Last synced from `design/index.yaml` via `audit-index`.*\n<!-- END AUTO-TOC -->"
        assertEqual "Normalized equality" (normalizeMarkdownBlock block1) (normalizeMarkdownBlock block2)
    , testCase "Normalizes escaped markdown asterisks and underscores in cells" $ do
        let block1 =
              "<!-- BEGIN AUTO-TOC -->\n| Document | Summary |\n| :--- | :--- |\n| [Doc](doc.md) | \\*\\*Bold\\*\\* and \\_under\\_ |\n\n_Last synced from `design/index.yaml` via `tools/audit_index.py`._\n<!-- END AUTO-TOC -->"
            block2 =
              "<!-- BEGIN AUTO-TOC -->\n| Document | Summary |\n| :--- | :--- |\n| [Doc](doc.md) | **Bold** and _under_ |\n\n_Last synced from `design/index.yaml` via `tools/audit_index.py`._\n<!-- END AUTO-TOC -->"
        assertEqual "Normalized equality" (normalizeMarkdownBlock block1) (normalizeMarkdownBlock block2)
    ]
