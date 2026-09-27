{-# LANGUAGE OverloadedStrings #-}

module PandocRenderTest (tests) where

import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Reflex.Dom.Core hiding (Link, Period, Space)
import Test.Tasty
import Test.Tasty.HUnit
import Text.Pandoc.Definition

import Core.Glossary (Glossary, GlossaryEntry (..), fromList, mkGlossary)
import Frontend.Render.Pandoc

testGlossary :: Glossary
testGlossary =
  fromList
    [ GlossaryEntry
        { canonical = "Action"
        , aliases = ["Actions"]
        , slug = "action"
        , category = "Action Types & Card Keywords"
        , summary = "An offensive or tactical declaration."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Crisis Time"
        , aliases = ["Crisis"]
        , slug = "crisis-time"
        , category = "Pacing & Play Modes"
        , summary = "The turn-based tactical mode used when stakes are high."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Defense"
        , aliases = ["Defenses", "Alias"]
        , slug = "defense"
        , category = "Stats & Values"
        , summary = "One of the key stats for resolving actions."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Keyword"
        , aliases = []
        , slug = "keyword"
        , category = "Action Types & Card Keywords"
        , summary = "A formal game rules keyword."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Red"
        , aliases = []
        , slug = "red"
        , category = "Colors of Action"
        , summary = "The color of Force, Endurance, Presence, Passion, Dominion."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Yellow"
        , aliases = []
        , slug = "yellow"
        , category = "Colors of Action"
        , summary = "The color of Cunning, Agility, Perception, Trickery."
        , theme = Nothing
        }
    , GlossaryEntry
        { canonical = "Blue"
        , aliases = []
        , slug = "blue"
        , category = "Colors of Action"
        , summary = "The color of Wisdom, Willpower, Precision, Lore."
        , theme = Nothing
        }
    ]

samplePandocDoc :: Pandoc
samplePandocDoc =
  Pandoc
    nullMeta
    [ Header 1 ("sec-rules", ["title"], []) [Str "Core", Space, Str "Rules"]
    , Header 2 ("sec-anatomy", [], []) [Str "Card", Space, Str "Anatomy"]
    , Header 3 ("sec-details", [], []) [Str "Detailed", Space, Str "Overview"]
    , Header 4 ("sec-sub", [], []) [Str "Subheading"]
    , Para
        [ Str "Welcome"
        , Space
        , Str "to"
        , Space
        , Strong [Str "CardPG"]
        , Str "."
        , Space
        , Emph [Str "Emphasized"]
        , Space
        , Underline [Str "underlined"]
        , Space
        , Code ("", [], []) "attack 3"
        , Space
        , Link ("", [], []) [Str "learn more"] ("glossary.html", "Glossary")
        ]
    , BlockQuote
        [ Para [Str "In the darkest dungeon, wisdom guides the blade."]
        ]
    , BulletList
        [ [Plain [Str "Draw two cards."]]
        , [Plain [Str "Gain 1 action."]]
        ]
    , OrderedList
        (1, Decimal, Period)
        [ [Plain [Str "First phase: Planning."]]
        , [Plain [Str "Second phase: Execution."]]
        ]
    , HorizontalRule
    , CodeBlock ("", ["haskell"], []) "main :: IO ()\nmain = putStrLn \"CardPG\""
    , CodeBlock ("", ["card"], []) "c-slash-01"
    , Table
        ("", [], [])
        (Caption Nothing [])
        [(AlignLeft, ColWidthDefault), (AlignRight, ColWidthDefault)]
        ( TableHead
            ("", [], [])
            [ Row
                ("", [], [])
                [ Cell ("", [], []) AlignLeft 1 1 [Plain [Str "Stat"]]
                , Cell ("", [], []) AlignRight 1 1 [Plain [Str "Value"]]
                ]
            ]
        )
        [ TableBody
            ("", [], [])
            0
            []
            [ Row
                ("", [], [])
                [ Cell ("", [], []) AlignLeft 1 1 [Plain [Str "Attack"]]
                , Cell ("", [], []) AlignRight 1 1 [Plain [Str "3"]]
                ]
            ]
        ]
        (TableFoot ("", [], []) [])
    ]

tests :: TestTree
tests =
  testGroup
    "Frontend.Render.Pandoc"
    [ testCase "Static mode renders headers with correct classes" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains h1 with font-cinzel"
          ("<h1" `T.isInfixOf` html && "font-cinzel" `T.isInfixOf` html)
        assertBool "Contains h1 with text-gold-bright" ("text-gold-bright" `T.isInfixOf` html)
        assertBool "Contains h1 with id sec-rules" ("id=\"sec-rules\"" `T.isInfixOf` html)
        assertBool "Contains h2 with text-xl" ("<h2" `T.isInfixOf` html && "text-xl" `T.isInfixOf` html)
        assertBool
          "Contains h3 with text-lg and text-gold-muted"
          ("<h3" `T.isInfixOf` html && "text-lg" `T.isInfixOf` html && "text-gold-muted" `T.isInfixOf` html)
        assertBool "Contains h4 with text-base" ("<h4" `T.isInfixOf` html && "text-base" `T.isInfixOf` html)
    , testCase "Static mode renders paragraph and inlines" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains paragraph with font-lora and leading-relaxed"
          ("<p" `T.isInfixOf` html && "font-lora" `T.isInfixOf` html && "leading-relaxed" `T.isInfixOf` html)
        assertBool
          "Contains strong with font-bold"
          ("<strong" `T.isInfixOf` html && "font-bold" `T.isInfixOf` html)
        assertBool "Contains em" ("<em>Emphasized</em>" `T.isInfixOf` html)
        assertBool "Contains underline" ("underline" `T.isInfixOf` html && "underlined" `T.isInfixOf` html)
        assertBool
          "Contains inline code with font-mono"
          ("<code" `T.isInfixOf` html && "font-mono" `T.isInfixOf` html && "attack 3" `T.isInfixOf` html)
        assertBool
          "Contains link with href"
          ( "<a" `T.isInfixOf` html
              && "href=\"glossary.html\"" `T.isInfixOf` html
              && "title=\"Glossary\"" `T.isInfixOf` html
          )
    , testCase "Static mode renders blockquote with gold left border" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains blockquote with border-l-4 and border-gold-muted"
          ( "<blockquote" `T.isInfixOf` html
              && "border-l-4" `T.isInfixOf` html
              && "border-gold-muted" `T.isInfixOf` html
              && "italic" `T.isInfixOf` html
          )
    , testCase "Static mode renders lists and horizontal rule" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains unordered list with list-disc"
          ("<ul" `T.isInfixOf` html && "list-disc" `T.isInfixOf` html)
        assertBool
          "Contains ordered list with list-decimal"
          ("<ol" `T.isInfixOf` html && "list-decimal" `T.isInfixOf` html)
        assertBool "Contains hr" ("<hr" `T.isInfixOf` html)
    , testCase "Static mode renders standard code block and fenced card block" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains standard pre block with bg-stone-dark"
          ("<pre" `T.isInfixOf` html && "bg-stone-dark" `T.isInfixOf` html)
        assertBool
          "Dispatches fenced card block to card-embed"
          ("class=\"card-embed\"" `T.isInfixOf` html && "data-card-id=\"c-slash-01\"" `T.isInfixOf` html)
    , testCase "Static mode renders tables" $ do
        let env = defaultRenderEnv RenderStatic
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains table with thead and tbody"
          ("<table" `T.isInfixOf` html && "<thead" `T.isInfixOf` html && "<tbody" `T.isInfixOf` html)
        assertBool
          "Contains th and td"
          ("<th" `T.isInfixOf` html && "<td" `T.isInfixOf` html && "Attack" `T.isInfixOf` html)
    , testCase "Interactive mode executes cleanly" $ do
        let env = RenderEnv{glossary = mkGlossary mempty, renderMode = RenderInteractive, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env samplePandocDoc)
        let html = decodeUtf8 htmlBytes
        assertBool "Renders content in interactive mode" ("Core Rules" `T.isInfixOf` html)
    , testCase "isWikilink identifies wikilink attributes" $ do
        assertBool "Recognizes wikilink class" (isWikilink ("", ["wikilink"], []))
        assertBool "Ignores regular links" (not (isWikilink ("", ["external"], [])))
    , testCase "Static mode renders single-word wikilink [[Action]]" $ do
        let doc =
              Pandoc
                nullMeta
                [ Para
                    [ Str "Take"
                    , Space
                    , Str "an"
                    , Space
                    , Link ("", ["wikilink"], []) [Str "Action"] ("Action", "")
                    , Str "."
                    ]
                ]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderStatic, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains href to glossary.html#action"
          ("href=\"glossary.html#action\"" `T.isInfixOf` html)
        assertBool
          "Contains title with summary"
          ("title=\"An offensive or tactical declaration.\"" `T.isInfixOf` html)
        assertBool "Contains anchor text Action" (">Action</a>" `T.isInfixOf` html)
        assertBool
          "Contains game-kw and category class"
          ("class=\"game-kw kw-action-types-card-keywords" `T.isInfixOf` html)
    , testCase "Static mode renders multi-word wikilink [[Crisis Time]]" $ do
        let doc =
              Pandoc
                nullMeta
                [ Para
                    [ Str "Entering"
                    , Space
                    , Link ("", ["wikilink"], []) [Str "Crisis", Space, Str "Time"] ("Crisis Time", "")
                    , Str "!"
                    ]
                ]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderStatic, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains href to glossary.html#crisis-time"
          ("href=\"glossary.html#crisis-time\"" `T.isInfixOf` html)
        assertBool
          "Contains summary title"
          ("title=\"The turn-based tactical mode used when stakes are high.\"" `T.isInfixOf` html)
        assertBool "Contains anchor text Crisis Time" (">Crisis Time</a>" `T.isInfixOf` html)
        assertBool "Contains kw-pacing-play-modes" ("kw-pacing-play-modes" `T.isInfixOf` html)
    , testCase "Static mode renders piped wikilink [[Crisis Time|tactical mode]]" $ do
        let doc =
              Pandoc
                nullMeta
                [ Para
                    [ Str "Entering"
                    , Space
                    , Link ("", ["wikilink"], []) [Str "tactical", Space, Str "mode"] ("Crisis Time", "")
                    , Str "."
                    ]
                ]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderStatic, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Contains href to target glossary.html#crisis-time"
          ("href=\"glossary.html#crisis-time\"" `T.isInfixOf` html)
        assertBool "Contains display text tactical mode" (">tactical mode</a>" `T.isInfixOf` html)
    , testCase "Static mode renders punctuated wikilinks [[Keyword]], and ([[Alias]])" $ do
        let doc =
              Pandoc
                nullMeta
                [ Para
                    [ Str "A"
                    , Space
                    , Link ("", ["wikilink"], []) [Str "Keyword"] ("Keyword", "")
                    , Str ","
                    , Space
                    , Str "and"
                    , Space
                    , Str "("
                    , Link ("", ["wikilink"], []) [Str "Alias"] ("Alias", "")
                    , Str ")."
                    ]
                ]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderStatic, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool "Keyword link has comma outside tag" (">Keyword</a>," `T.isInfixOf` html)
        assertBool
          "Keyword href is glossary.html#keyword"
          ("href=\"glossary.html#keyword\"" `T.isInfixOf` html)
        assertBool "Alias link is preceded by parenthesis" ("(<a" `T.isInfixOf` html)
        assertBool
          "Alias resolves to canonical slug defense"
          ("href=\"glossary.html#defense\"" `T.isInfixOf` html)
        assertBool "Closing parenthesis outside alias tag" (">Alias</a>)" `T.isInfixOf` html)
    , testCase "Static mode renders unknown term fallback with toSlug" $ do
        let doc =
              Pandoc
                nullMeta
                [ Para
                    [ Str "Refers"
                    , Space
                    , Str "to"
                    , Space
                    , Link ("", ["wikilink"], []) [Str "Unknown Future Term"] ("Unknown Future Term", "")
                    , Str "."
                    ]
                ]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderStatic, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool
          "Fallback slug is generated via toSlug"
          ("href=\"glossary.html#unknown-future-term\"" `T.isInfixOf` html)
        assertBool "Fallback anchor text is preserved" (">Unknown Future Term</a>" `T.isInfixOf` html)
        assertBool "Fallback category is general" ("kw-general" `T.isInfixOf` html)
    , testCase "Interactive mode renders badge chip and tooltip card" $ do
        let doc =
              Pandoc
                nullMeta
                [Para [Str "Activate", Space, Link ("", ["wikilink"], []) [Str "Action"] ("Action", ""), Str "."]]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderInteractive, activeKeyword = Nothing}
        (_, htmlBytes) <- renderStatic (renderPandoc env doc)
        let html = decodeUtf8 htmlBytes
        assertBool "Contains game-kw-interactive wrap" ("game-kw-interactive" `T.isInfixOf` html)
        assertBool
          "Contains game-kw-badge chip"
          ("game-kw-badge" `T.isInfixOf` html && "Action" `T.isInfixOf` html)
        assertBool
          "Contains font-cinzel term title"
          ("font-cinzel" `T.isInfixOf` html && "text-gold-bright" `T.isInfixOf` html)
        assertBool
          "Contains category badge"
          ( "text-xs" `T.isInfixOf` html && "Action Types &amp; Card Keywords" `T.isInfixOf` html
              || "Action Types & Card Keywords" `T.isInfixOf` html
          )
        assertBool
          "Contains summary in font-lora"
          ("font-lora" `T.isInfixOf` html && "An offensive or tactical declaration." `T.isInfixOf` html)
        assertBool "Contains group-hover:block" ("group-hover:block" `T.isInfixOf` html)
    , testCase "Interactive mode renders action color chips for Red, Yellow, Blue" $ do
        let docRed =
              Pandoc
                nullMeta
                [Para [Str "Uses", Space, Link ("", ["wikilink"], []) [Str "Red"] ("Red", ""), Str "."]]
            docYellow =
              Pandoc
                nullMeta
                [Para [Str "Uses", Space, Link ("", ["wikilink"], []) [Str "Yellow"] ("Yellow", ""), Str "."]]
            docBlue =
              Pandoc
                nullMeta
                [Para [Str "Uses", Space, Link ("", ["wikilink"], []) [Str "Blue"] ("Blue", ""), Str "."]]
            env = RenderEnv{glossary = testGlossary, renderMode = RenderInteractive, activeKeyword = Nothing}
        (_, htmlRedBytes) <- renderStatic (renderPandoc env docRed)
        (_, htmlYellowBytes) <- renderStatic (renderPandoc env docYellow)
        (_, htmlBlueBytes) <- renderStatic (renderPandoc env docBlue)
        let htmlRed = decodeUtf8 htmlRedBytes
            htmlYellow = decodeUtf8 htmlYellowBytes
            htmlBlue = decodeUtf8 htmlBlueBytes
        assertBool "Red has border-red-6" ("border-red-6" `T.isInfixOf` htmlRed)
        assertBool "Red has rubyGrad square" ("rubyGrad" `T.isInfixOf` htmlRed)
        assertBool "Yellow has border-yellow-5" ("border-yellow-5" `T.isInfixOf` htmlYellow)
        assertBool "Yellow has topazGrad circle" ("topazGrad" `T.isInfixOf` htmlYellow)
        assertBool "Blue has border-blue-5" ("border-blue-5" `T.isInfixOf` htmlBlue)
        assertBool "Blue has sapphireGrad diamond" ("sapphireGrad" `T.isInfixOf` htmlBlue)
    ]
