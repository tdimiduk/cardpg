{-# LANGUAGE OverloadedStrings #-}

module RulesViewerTest (tests) where

import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Reflex.Dom.Core hiding (Link, Space)
import Test.Tasty
import Test.Tasty.HUnit
import Text.Pandoc.Definition (Pandoc (..))

import Core.Glossary (lookupGlossary)
import Core.NonEmptyText (unsafeNonEmptyText)
import Core.RichText (Inline (..))
import Frontend.Render.Rules (renderInline)
import Frontend.Rules.Data
import Frontend.Rules.Viewer

tests :: TestTree
tests =
  testGroup
    "Frontend.Rules and Keyword Tooltips (Phase 5)"
    [ testGroup
        "Frontend.Rules.Data (Compile-Time Embedding)"
        [ testCase "embeddedGlossary has canonical entries" $ do
            let mAttack = lookupGlossary "Attack" embeddedGlossary
            assertBool "Attack entry exists" (isJust mAttack)
            let mActionStack = lookupGlossary "Action Stack" embeddedGlossary
            assertBool "Action Stack entry exists" (isJust mActionStack)
            let mCrisis = lookupGlossary "Crisis Time" embeddedGlossary
            assertBool "Crisis Time entry exists" (isJust mCrisis)
            let mRed = lookupGlossary "Red" embeddedGlossary
            assertBool "Red entry exists" (isJust mRed)
            let mYellow = lookupGlossary "Yellow" embeddedGlossary
            assertBool "Yellow entry exists" (isJust mYellow)
            let mBlue = lookupGlossary "Blue" embeddedGlossary
            assertBool "Blue entry exists" (isJust mBlue)
        , testCase "embeddedDocs has valid non-empty ASTs for all tabs" $ do
            let (Pandoc _ rBlocks) = lookupDoc TabCoreRules
            assertBool "Core rules has AST blocks" (not (null rBlocks))
            let (Pandoc _ gBlocks) = lookupDoc TabGlossary
            assertBool "Glossary has AST blocks" (not (null gBlocks))
            let (Pandoc _ cBlocks) = lookupDoc TabColors
            assertBool "Colors has AST blocks" (not (null cBlocks))
            assertEqual "Map contains all 3 tabs" 3 (Map.size embeddedDocs)
        ]
    , testGroup
        "Frontend.Rules.Viewer (In-App Rules Modal)"
        [ testCase "rulesViewerWidget renders obsidian panel, tabs, and content" $ do
            (_, htmlBytes) <- renderStatic (rulesViewerWidget never)
            let html = decodeUtf8 htmlBytes
            assertBool "Contains obsidian-panel class" ("obsidian-panel" `T.isInfixOf` html)
            assertBool "Contains bg-stone-dark" ("bg-stone-dark" `T.isInfixOf` html)
            assertBool "Contains border-gold-muted" ("border-gold-muted" `T.isInfixOf` html)
            assertBool "Contains rules-backdrop" ("data-testid=\"rules-backdrop\"" `T.isInfixOf` html)
            assertBool "Contains rules-viewer-modal" ("data-testid=\"rules-viewer-modal\"" `T.isInfixOf` html)
            assertBool "Contains Core Rules tab button" ("data-testid=\"tab-core-rules\"" `T.isInfixOf` html)
            assertBool "Contains Glossary tab button" ("data-testid=\"tab-glossary\"" `T.isInfixOf` html)
            assertBool "Contains Colors tab button" ("data-testid=\"tab-colors\"" `T.isInfixOf` html)
            assertBool "Contains close button" ("data-testid=\"close-rules-viewer\"" `T.isInfixOf` html)
            assertBool "Contains font-cinzel tab typography" ("font-cinzel" `T.isInfixOf` html)
            assertBool "Contains rules content area" ("rules-content" `T.isInfixOf` html)
        , testCase "rulesViewerWidgetWithInitialTab renders specified tab" $ do
            (_, htmlBytes) <- renderStatic (rulesViewerWidgetWithInitialTab TabGlossary never)
            let html = decodeUtf8 htmlBytes
            assertBool "Contains tab-glossary button" ("data-testid=\"tab-glossary\"" `T.isInfixOf` html)
            assertBool "Renders glossary content" ("rules-content" `T.isInfixOf` html)
        , testCase "rulesViewerModal renders on open event" $ do
            (_, htmlBytes) <- renderStatic (rulesViewerModal =<< getPostBuild)
            let html = decodeUtf8 htmlBytes
            assertBool "Renders modal on open event" ("rules-viewer-modal" `T.isInfixOf` html)
        ]
    , testGroup
        "Frontend.Render.Rules (Card Keyword Tooltip Unification)"
        [ testCase "Card renderInline Wikilink renders interactive badge and tooltip popover" $ do
            (_, htmlBytes) <- renderStatic (renderInline (Wikilink (unsafeNonEmptyText "Action") Nothing))
            let html = decodeUtf8 htmlBytes
            assertBool "Contains game-kw-interactive wrapper" ("game-kw-interactive" `T.isInfixOf` html)
            assertBool "Contains game-kw-badge chip" ("game-kw-badge" `T.isInfixOf` html)
            assertBool "Displays Action keyword text" ("Action" `T.isInfixOf` html)
            assertBool "Contains font-cinzel title" ("font-cinzel" `T.isInfixOf` html)
            assertBool "Contains font-lora summary" ("font-lora" `T.isInfixOf` html)
            assertBool "Contains group-hover:block" ("group-hover:block" `T.isInfixOf` html)
        , testCase "Card renderInline Wikilink renders action color chips for Red, Yellow, Blue" $ do
            (_, htmlRedBytes) <- renderStatic (renderInline (Wikilink (unsafeNonEmptyText "Red") Nothing))
            (_, htmlYellowBytes) <- renderStatic (renderInline (Wikilink (unsafeNonEmptyText "Yellow") Nothing))
            (_, htmlBlueBytes) <- renderStatic (renderInline (Wikilink (unsafeNonEmptyText "Blue") Nothing))
            let htmlRed = decodeUtf8 htmlRedBytes
                htmlYellow = decodeUtf8 htmlYellowBytes
                htmlBlue = decodeUtf8 htmlBlueBytes
            assertBool "Red has border-red-6" ("border-red-6" `T.isInfixOf` htmlRed)
            assertBool "Red has rubyGrad square" ("rubyGrad" `T.isInfixOf` htmlRed)
            assertBool "Yellow has border-yellow-5" ("border-yellow-5" `T.isInfixOf` htmlYellow)
            assertBool "Yellow has topazGrad circle" ("topazGrad" `T.isInfixOf` htmlYellow)
            assertBool "Blue has border-blue-5" ("border-blue-5" `T.isInfixOf` htmlBlue)
            assertBool "Blue has sapphireGrad diamond" ("sapphireGrad" `T.isInfixOf` htmlBlue)
        , testCase
            "Card renderInline Wikilink with piped alias renders display on badge and canonical in tooltip"
            $ do
              (_, htmlBytes) <-
                renderStatic
                  ( renderInline
                      (Wikilink (unsafeNonEmptyText "Crisis Time") (Just (unsafeNonEmptyText "tactical mode")))
                  )
              let html = decodeUtf8 htmlBytes
              assertBool "Badge contains piped display text" ("tactical mode" `T.isInfixOf` html)
              assertBool "Tooltip contains canonical target text" ("Crisis Time" `T.isInfixOf` html)
        , testCase "Card renderInline Wikilink with unknown keyword renders fallback badge" $ do
            (_, htmlBytes) <- renderStatic (renderInline (Wikilink (unsafeNonEmptyText "UnknownTerm") Nothing))
            let html = decodeUtf8 htmlBytes
            assertBool "Contains game-kw-interactive wrapper" ("game-kw-interactive" `T.isInfixOf` html)
            assertBool "Displays unknown term text" ("UnknownTerm" `T.isInfixOf` html)
        ]
    ]
