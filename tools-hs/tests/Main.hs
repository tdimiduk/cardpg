{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Core.Card
  ( ActorDefinition (..)
  , CardReference (..)
  , CoreCard (..)
  , DeckEntry (..)
  , MasterCard (..)
  , RulesStatus (..)
  , Stats (..)
  , resolveDeckEntry
  )
import Core.DSL (toText)
import Core.Glossary
import Core.NonEmptyText (unsafeNonEmptyText)
import Data.ByteString qualified as BS
import Data.Either (rights)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Data.Yaml (ParseException, decodeEither', decodeFileEither, encode)
import Design.Bundle
  ( AuthorityTier (..)
  , BundleConfig (..)
  , FileBundleEntry (..)
  , LandscapeEntry (..)
  , classifyAuthority
  , computeDynamicFence
  , renderBundle
  )
import Design.Frontmatter
import Design.Glossary
  ( generateGlossaryHaskellSource
  , parseGlossaryEntries
  , validateGlossaryReferences
  )
import Design.Index
import Design.TOC
import Design.Types
import KeywordMod hiding (main)
import ManageCards
import System.Directory (doesDirectoryExist)
import Test.Tasty
import Test.Tasty.HUnit

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "tools-hs tests"
    [ test_glossaryParser
    , test_glossaryCodegen
    , test_chunking
    , test_normalization
    , test_renaming
    , test_frontmatter
    , test_scaffolding
    , test_indexOps
    , test_tocNormalization
    , test_cardManagement
    , test_bundler
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
            assertEqual "Summary" "How approaches are classified." (toText e.summary)
            assertEqual "Theme is Nothing" Nothing e.theme

        case lookupGlossary "Red" g of
          Nothing -> assertFailure "Did not find 'Red'"
          Just e -> do
            assertEqual "Canonical" "Red" e.canonical
            assertEqual "Theme is red" (Just "red") e.theme
    ]

test_glossaryCodegen :: TestTree
test_glossaryCodegen =
  testGroup
    "Glossary Codegen & Validation"
    [ testCase "Validates keyword cross-references in sample markdown" $ do
        case parseGlossaryEntries sampleMarkdown of
          Left err -> assertFailure ("Parse error: " ++ err)
          Right entries -> do
            let refErrors = validateGlossaryReferences entries
            assertEqual "No invalid references" [] refErrors
    , testCase "Catches unknown keyword reference" $ do
        let badMarkdown =
              "# Glossary\n\n## Cat\n\n### Attack\n\nAn attack during [[Crissis Time]]!\n"
        case parseGlossaryEntries badMarkdown of
          Left err -> assertFailure ("Parse error: " ++ err)
          Right entries -> do
            let refErrors = validateGlossaryReferences entries
            assertEqual "Finds 1 error" 1 (length refErrors)
            case refErrors of
              (firstErr : _) -> assertBool "Mentions Crissis Time" ("Crissis Time" `T.isInfixOf` T.pack firstErr)
              [] -> assertFailure "Expected refErrors"
    , testCase "Generates compilable Haskell source containing entries" $ do
        case parseGlossaryEntries sampleMarkdown of
          Left err -> assertFailure ("Parse error: " ++ err)
          Right entries -> do
            let src = generateGlossaryHaskellSource entries
            assertBool "Contains module header" ("module Core.Glossary.Generated" `T.isInfixOf` src)
            assertBool "Contains Color" ("canonical = \"Color\"" `T.isInfixOf` src)
            assertBool "Contains Red" ("canonical = \"Red\"" `T.isInfixOf` src)
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
              "<!-- BEGIN AUTO-TOC -->\n| Document | Summary |\n| :--- | :--- |\n| [Doc](doc.md) | \\*\\*Bold\\*\\* and \\_under\\_ |\n\n_Last synced from `design/index.yaml` via `audit-index`._\n<!-- END AUTO-TOC -->"
            block2 =
              "<!-- BEGIN AUTO-TOC -->\n| Document | Summary |\n| :--- | :--- |\n| [Doc](doc.md) | **Bold** and _under_ |\n\n_Last synced from `design/index.yaml` via `audit-index`._\n<!-- END AUTO-TOC -->"
        assertEqual "Normalized equality" (normalizeMarkdownBlock block1) (normalizeMarkdownBlock block2)
    ]

test_cardManagement :: TestTree
test_cardManagement =
  testGroup
    "ManageCards Tooling"
    [ test_legacyClassifier
    , test_deduplicationAndSlugs
    , test_exportAndSerialization
    , test_deckRewriter
    , test_dataIntegrity
    ]

test_legacyClassifier :: TestTree
test_legacyClassifier =
  testGroup
    "Legacy Rules Classifier"
    [ testCase "Detects shorthand color pipes" $ do
        assertBool "Detects |x|" (checkShorthandColor "defend |x| + 1")
        assertBool "Detects |y|" (checkShorthandColor "strength = |y|")
        assertBool "Detects |z|" (checkShorthandColor "|z| + 3")
        assertBool "Detects |b|" (checkShorthandColor "|b| defense")
        assertBool "Ignores clean text" (not (checkShorthandColor "defend {Red} + 1"))
    , testCase "Detects legacy armor syntax" $ do
        assertBool "Detects ignore 1 armor" (checkLegacyArmor "ignore 1 armor on hit")
        assertBool "Detects no armor" (checkLegacyArmor "Str = {Red} + 3 -> no armor")
        assertBool "Detects armor damage" (checkLegacyArmor "Armor damage (on any success)")
        assertBool "Ignores clean armor" (not (checkLegacyArmor "wear heavy armor"))
    , testCase "Detects legacy defense wording" $ do
        assertBool
          "Detects defend from anywhere"
          (checkLegacyDefense "+ 3 when used to defend from anywhere")
        assertBool "Ignores regular defend" (not (checkLegacyDefense "defend against attack"))
    , testCase "Detects obsolete consequence tiers" $ do
        assertBool "Detects minor:" (checkObsoleteTiers "Minor: Target is staggered")
        assertBool "Detects major:" (checkObsoleteTiers "Major: Target is stunned")
        assertBool "Detects critical:" (checkObsoleteTiers "Critical: Target falls")
        assertBool "Ignores standard rules" (not (checkObsoleteTiers "Inflict consequence"))
    , testCase "Detects legacy wound phrasing" $ do
        assertBool "Detects basic wound" (checkLegacyWounds "{Red}: Str = {Red} + 2 -> basic wound")
        assertBool "Ignores clean attack" (not (checkLegacyWounds "{Red}: Str = {Red} + 2"))
    , testCase "Classifies clean modern card as RulesCurrent" $ do
        let card =
              CoreCard
                { name = unsafeNonEmptyText "Conditioning"
                , tags = Nothing
                , stats = Stats 4 3 3
                , cost = Nothing
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                }
            (status, notes) = classifyLegacy card
        status @?= RulesCurrent
        notes @?= Nothing
    ]

test_deduplicationAndSlugs :: TestTree
test_deduplicationAndSlugs =
  testGroup
    "Deduplication & Slugs"
    [ testCase "Disambiguates colliding slugs" $ do
        let c1 =
              CoreCard
                { name = unsafeNonEmptyText "Sunder Armor"
                , tags = Nothing
                , stats = Stats 4 2 3
                , cost = Just 2
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                }
            c2 =
              CoreCard (unsafeNonEmptyText "Sunder Armor") Nothing (Stats 4 2 3) (Just 1) Nothing Nothing Nothing
            groups =
              assignUniqueSlugs
                [(CategoryMartial, c1, [CardOccurrence "f1" c1]), (CategoryMartial, c2, [CardOccurrence "f2" c2])]
        map (\g -> g.canonicalSlug) groups @?= ["sunder-armor", "sunder-armor-2"]
    , testCase "Categorizes core cards appropriately" $ do
        let c =
              CoreCard
                { name = unsafeNonEmptyText "Athletics"
                , tags = Nothing
                , stats = Stats 4 4 2
                , cost = Nothing
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                }
        determineCardCategory ["data/cards/pc/shield-fighter.yaml"] c @?= CategoryCore
    , testCase "Categorizes wizard cards as arcane" $ do
        let c =
              CoreCard
                { name = unsafeNonEmptyText "Fireball"
                , tags = Nothing
                , stats = Stats 2 2 5
                , cost = Just 2
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                }
        determineCardCategory ["data/cards/pc/wizard.yaml"] c @?= CategoryArcane
    , testCase "Categorizes beast monsters appropriately" $ do
        let c =
              CoreCard
                { name = unsafeNonEmptyText "Snack attack"
                , tags = Nothing
                , stats = Stats 6 4 2
                , cost = Just 1
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                }
        determineCardCategory ["data/cards/monsters/bread_wolf.yaml"] c @?= CategoryBeasts
    , testCase "Picks modal stats for group with stat variations" $ do
        let c1 = CoreCard (unsafeNonEmptyText "Bite") Nothing (Stats 3 2 2) (Just 1) Nothing Nothing Nothing
            c2 = CoreCard (unsafeNonEmptyText "Bite") Nothing (Stats 3 2 2) (Just 1) Nothing Nothing Nothing
            c3 = CoreCard (unsafeNonEmptyText "Bite") Nothing (Stats 5 2 2) (Just 1) Nothing Nothing Nothing
            groups = groupCards [("f1", c1), ("f2", c2), ("f3", c3)]
        case groups of
          [grp] -> grp.baseCard.stats @?= Stats 3 2 2
          _ -> assertFailure "Expected single group"
    ]

test_exportAndSerialization :: TestTree
test_exportAndSerialization =
  testGroup
    "Export & YAML Serialization"
    [ testCase "Serializes MasterCard with snake_case rules_status and legacy_notes" $ do
        let mc =
              MasterCard
                { id = "test-card"
                , name = unsafeNonEmptyText "Test Card"
                , tags = Just (NE.singleton "Martial")
                , stats = Stats 3 2 1
                , cost = Just 1
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                , rulesStatus = Just RulesOutdated
                , legacyNotes = Just "Uses legacy syntax"
                , milestones = Nothing
                }
            encoded = encode [mc]
        assertBool "Contains rules_status" ("rules_status: outdated" `BS.isInfixOf` encoded)
        assertBool "Contains legacy_notes" ("legacy_notes: Uses legacy syntax" `BS.isInfixOf` encoded)
        case decodeEither' encoded of
          Left err -> assertFailure $ "Failed to decode: " ++ show err
          Right (decoded :: [MasterCard]) -> decoded @?= [mc]
    , testCase "CardGroup to MasterCard populates category tags when missing" $ do
        let c = CoreCard (unsafeNonEmptyText "Slash") Nothing (Stats 4 2 2) (Just 1) Nothing Nothing Nothing
            grp = CardGroup "slash" c [CardOccurrence "f" c] CategoryMartial RulesCurrent Nothing
            mc = cardGroupToMasterCard grp
        mc.tags @?= Just (NE.singleton "Martial")
        mc.rulesStatus @?= Just RulesCurrent
    ]

test_deckRewriter :: TestTree
test_deckRewriter =
  testGroup
    "Deck Rewriter"
    [ testCase "Computes Nothing for matching stats" $ do
        let s = Stats 3 2 1
        computeStatOverrides s s @?= Nothing
    , testCase "Computes partial override when only one stat differs" $ do
        let actual = Stats 5 2 1
            base = Stats 3 2 1
        computeStatOverrides actual base @?= Just (Stats (Just 5) Nothing Nothing)
    , testCase "Replaces matching inline cards with CardReference" $ do
        let baseCard = CoreCard (unsafeNonEmptyText "Shield Bash") Nothing (Stats 2 1 3) Nothing Nothing Nothing Nothing
            mc =
              MasterCard
                { id = "shield-bash"
                , name = unsafeNonEmptyText "Shield Bash"
                , tags = Nothing
                , stats = Stats 2 1 3
                , cost = Nothing
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                , rulesStatus = Just RulesCurrent
                , legacyNotes = Nothing
                , milestones = Nothing
                }
            catalog = Map.singleton "shield-bash" mc
            actor =
              ActorDefinition
                { name = "Defender"
                , tags = Nothing
                , items = []
                , nature = []
                , deck = [EntryInline baseCard]
                }
            (rewritten, res) = rewriteActorDefinition catalog actor
        res.replacedEntries @?= 1
        res.modified @?= True
        case rewritten.deck of
          [EntryRef ref] -> do
            ref.card @?= "shield-bash"
            ref.stats @?= Nothing
          _ -> assertFailure "Expected EntryRef"
    , testCase "Preserves non-matching inline cards inline" $ do
        let unknownCard = CoreCard (unsafeNonEmptyText "Unknown") Nothing (Stats 1 1 1) Nothing Nothing Nothing Nothing
            actor =
              ActorDefinition
                { name = "Mystery"
                , tags = Nothing
                , items = []
                , nature = []
                , deck = [EntryInline unknownCard]
                }
            (rewritten, res) = rewriteActorDefinition Map.empty actor
        res.retainedInlineEntries @?= 1
        res.modified @?= False
        rewritten.deck @?= [EntryInline unknownCard]
    , testCase "Byte-for-byte roundtrip passes for rewritten actor" $ do
        let mc =
              MasterCard
                { id = "quick-jab"
                , name = unsafeNonEmptyText "Quick Jab"
                , tags = Nothing
                , stats = Stats 2 1 1
                , cost = Nothing
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                , rulesStatus = Just RulesCurrent
                , legacyNotes = Nothing
                , milestones = Nothing
                }
            catalog = Map.singleton "quick-jab" mc
            actor =
              ActorDefinition
                { name = "Boxer"
                , tags = Nothing
                , items = []
                , nature = []
                , deck =
                    [ EntryInline
                        (CoreCard (unsafeNonEmptyText "Quick Jab") Nothing (Stats 3 1 1) Nothing Nothing Nothing Nothing)
                    ]
                }
            (rewritten, _) = rewriteActorDefinition catalog actor
            encoded = encode rewritten
        case decodeEither' encoded of
          Left err -> assertFailure $ "Failed decode: " ++ show err
          Right (decoded :: ActorDefinition) -> encode decoded @?= encoded
    ]

test_dataIntegrity :: TestTree
test_dataIntegrity =
  testGroup
    "Data Integrity"
    [ testCase "All existing actor files on disk have zero dangling card references" $ do
        let pcDir = "data/cards/pc"
            monDir = "data/cards/monsters"
            masterDir = "data/cards/master"
        pcExists <- doesDirectoryExist pcDir
        let (actualPc, actualMon, actualMaster) =
              if pcExists
                then (pcDir, monDir, masterDir)
                else ("../" ++ pcDir, "../" ++ monDir, "../" ++ masterDir)
        (_, pcFiles) <- scanActorFiles [actualPc]
        (_, monFiles) <- scanActorFiles [actualMon]
        let allFiles = pcFiles ++ monFiles
        actors <- mapM decodeFileEither allFiles :: IO [Either ParseException ActorDefinition]
        let validActors = rights actors
        eCatalog <- loadCatalog actualMaster
        catalog <- case eCatalog of
          Left err -> assertFailure ("Failed to load master catalog: " ++ err) >> pure Map.empty
          Right c -> pure c
        let errors = verifyCatalogIntegrity catalog validActors
        errors @?= []
    , testCase "Catches dangling card reference in invalid actor" $ do
        let badActor =
              ActorDefinition
                { name = "Ghost"
                , tags = Nothing
                , items = []
                , nature = []
                , deck = [EntryRef (CardReference "nonexistent-slug" Nothing Nothing Nothing)]
                }
            errs = verifyCatalogIntegrity Map.empty [badActor]
        assertEqual "Reports exactly 1 missing reference error" 1 (length errs)
        case errs of
          [firstErr] -> do
            assertBool
              "Mentions actor name"
              ("Ghost" `elem` words firstErr || "Actor 'Ghost'" `isInfixOfStr` firstErr)
            assertBool "Mentions card ID" ("nonexistent-slug" `isInfixOfStr` firstErr)
          _ -> assertFailure "Expected exactly 1 error message"
    , testCase "Resolves valid reference cleanly" $ do
        let mc =
              MasterCard
                { id = "strike"
                , name = unsafeNonEmptyText "Strike"
                , tags = Nothing
                , stats = Stats 3 2 2
                , cost = Nothing
                , attack = Nothing
                , rules = Nothing
                , flavor = Nothing
                , rulesStatus = Just RulesCurrent
                , legacyNotes = Nothing
                , milestones = Nothing
                }
            catalog = Map.singleton "strike" mc
            ref = CardReference "strike" (Just (Stats (Just 4) Nothing Nothing)) Nothing Nothing
        case resolveDeckEntry catalog (EntryRef ref) of
          Left err -> assertFailure $ "Resolution failed: " ++ err
          Right resolved -> resolved.stats @?= Stats 4 2 2
    ]
  where
    isInfixOfStr needle haystack = needle `T.isInfixOf` T.pack haystack

test_bundler :: TestTree
test_bundler =
  testGroup
    "Topic Bundler Tests"
    [ testGroup
        "Authority Tier Classification"
        [ testCase "Canonical rules" $
            classifyAuthority "design/rules/core-rules.md" @?= CanonicalRule
        , testCase "Design philosophy" $
            classifyAuthority "design/philosophy/design-precepts.md" @?= DesignPhilosophy
        , testCase "System design standards" $
            classifyAuthority ".agent/standards/systems_design_standards.md" @?= SystemDesignStandard
        , testCase "Math baseline" $
            classifyAuthority "data/math-baseline.md" @?= CanonicalMathBaseline
        , testCase "Active iteration" $
            classifyAuthority "design/iteration/fatigue/proposal.md" @?= ActiveIteration
        , testCase "Research synthesis" $
            classifyAuthority "design/research/synthesis/armor.md" @?= EmpiricalResearchSynthesis
        , testCase "Research report" $
            classifyAuthority "design/research/reports/archery-tests.md" @?= EmpiricalResearchReport
        , testCase "Canonical cards" $
            classifyAuthority "data/cards/core-combat.yaml" @?= CanonicalCardYaml
        , testCase "Engine Haskell AST" $
            classifyAuthority "core/src/Core/Types.hs" @?= EngineHaskellAst
        , testCase "Archived and outdated" $ do
            classifyAuthority "design/archive/old-rules.md" @?= ArchivedDeprecated
            classifyAuthority "design/rules/core-rules.md.outdated" @?= ArchivedDeprecated
        , testCase "Fallback project document" $
            classifyAuthority "README.md" @?= ProjectDocument
        ]
    , testGroup
        "Dynamic Code Fencing"
        [ testCase "Standard markdown with no backticks" $
            computeDynamicFence "Regular prose text without backticks." @?= "`````"
        , testCase "Markdown with 3-backtick code block" $
            computeDynamicFence "```haskell\nmain = putStrLn \"hi\"\n```" @?= "`````"
        , testCase "Markdown with 5-backtick block" $
            computeDynamicFence "`````markdown\nnested\n`````" @?= "``````"
        , testCase "Markdown with 7-backtick block" $
            computeDynamicFence "```````nested 7```````" @?= "````````"
        ]
    , testGroup
        "Bundle Rendering Structure"
        [ testCase "Renders all required sections and directives" $ do
            let cfg =
                  BundleConfig
                    { topic = "Fatigue & Armor Balance"
                    , framing = Just "1. How does fatigue interact with heavy armor?\n2. Are dice math within bounds?"
                    , output = "export/test-bundle.md"
                    , inputFiles = ["design/rules/core-rules.md"]
                    , timestamp = Just "2026-10-14 12:00"
                    }
                entry =
                  FileBundleEntry
                    { relPath = "design/rules/core-rules.md"
                    , authorityTier = CanonicalRule
                    , description = "The foundational player-facing rules."
                    , content = "# Core Rules\n\n```yaml\nsample: true\n```\n"
                    , lineCount = 5
                    , charCount = 35
                    , estimatedTokens = 8
                    , fence = "`````"
                    , langTag = "markdown"
                    }
                landscape =
                  [ LandscapeEntry
                      { relPath = "design/rules/modules/clocks-and-fronts.md"
                      , authorityTier = CanonicalRule
                      , description = "Pressure tracking and countdown clocks."
                      }
                  ]
                rendered = renderBundle cfg "2026-10-14 12:00" [entry] landscape
            assertBool
              "Contains topic header"
              ("# CARDPG DESIGN BUNDLE: Fatigue & Armor Balance" `T.isInfixOf` rendered)
            assertBool "Contains timestamp" ("Generated: 2026-10-14 12:00" `T.isInfixOf` rendered)
            assertBool
              "Contains Lead Systems Designer directive"
              ("Directive for AI (Lead Systems Designer)" `T.isInfixOf` rendered)
            assertBool
              "Contains Boundary Awareness"
              ("Repository Context & Boundary Awareness" `T.isInfixOf` rendered)
            assertBool
              "Contains Framing Section"
              ("## 2. Discussion Framing & Open Questions" `T.isInfixOf` rendered)
            assertBool
              "Contains Framing Content"
              ("How does fatigue interact with heavy armor?" `T.isInfixOf` rendered)
            assertBool "Contains Wrap-Up Protocol" ("## 3. Wrap-Up & Return Protocol" `T.isInfixOf` rendered)
            assertBool
              "Contains File Manifest"
              ("## 4. Included File Manifest & Authority Tiers" `T.isInfixOf` rendered)
            assertBool
              "Contains Manifest Line with Authority"
              ("CANONICAL RULE (Live System Law)" `T.isInfixOf` rendered)
            assertBool
              "Contains Landscape Section"
              ("## 5. Broader Repository Landscape (Available on Request)" `T.isInfixOf` rendered)
            assertBool
              "Contains Landscape item"
              ("design/rules/modules/clocks-and-fronts.md" `T.isInfixOf` rendered)
            assertBool
              "Contains Source Documents Section"
              ("## 6. Verbatim Source Documents" `T.isInfixOf` rendered)
            assertBool "Contains File Fencing" ("`````markdown\n# Core Rules" `T.isInfixOf` rendered)
        ]
    ]
