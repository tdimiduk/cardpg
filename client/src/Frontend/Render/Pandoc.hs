{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module: Frontend.Render.Pandoc
-- Description: Reflex DOM renderer for Pandoc AST documents with CardPG design tokens.
--
-- Portions adapted from reflex-dom-pandoc
-- Copyright (c) 2019 Sridhar Ratnakumar
-- SPDX-License-Identifier: BSD-3-Clause
module Frontend.Render.Pandoc
  ( RenderMode (..)
  , RenderEnv (..)
  , defaultRenderEnv
  , isWikilink
  , renderPandoc
  , renderBlocks
  , renderBlock
  , renderInlines
  , renderInline
  , renderWikilink
  , renderStaticWikilink
  , renderInteractiveWikilink
  , renderInteractiveWikilinkText
  , renderCardBlock
  , headerStyle
  , paraStyle
  , blockquoteStyle
  , bulletListStyle
  , orderedListStyle
  , hrStyle
  , codeBlockStyle
  , inlineCodeStyle
  , kwStaticStyle
  , kwBadgeStyle
  , tooltipCardStyle
  ) where

import Control.Monad (forM_, unless)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core hiding (Link, Space)
import Text.Pandoc.Definition

import Core.Glossary
  ( Glossary
  , GlossaryEntry (..)
  , canonicalSlug
  , lookupGlossary
  , mkGlossary
  , summaryText
  , toSlug
  )
import Core.Language (TextStyle (..))
import Core.NonEmptyText (getRawText)
import Core.RichText (RichText, getInlines)
import Core.RichText qualified as CoreRichText
import Core.Stats (Difficulty (..), StatValue (..))
import Core.Util (tshow)
import Frontend.Render.Common (IconMode (..), renderResourceType)
import Frontend.Style.Common (classNames, divS, elS)
import Frontend.Style.DSL qualified as S
import Frontend.Svg (renderCircle, renderDiamond, renderSquare)

--------------------------------------------------------------------------------
-- Rendering Environment
--------------------------------------------------------------------------------

data RenderMode = RenderStatic | RenderInteractive
  deriving (Show, Eq)

data RenderEnv = RenderEnv
  { glossary :: Glossary
  , renderMode :: RenderMode
  , activeKeyword :: Maybe Text
  }
  deriving (Show, Eq)

-- | Construct a default rendering environment with an empty glossary.
defaultRenderEnv :: RenderMode -> RenderEnv
defaultRenderEnv mode =
  RenderEnv
    { glossary = mkGlossary mempty
    , renderMode = mode
    , activeKeyword = Nothing
    }

--------------------------------------------------------------------------------
-- Style Tokens
--------------------------------------------------------------------------------

headerTag :: Int -> Text
headerTag 1 = "h1"
headerTag 2 = "h2"
headerTag 3 = "h3"
headerTag 4 = "h4"
headerTag 5 = "h5"
headerTag _ = "h6"

headerStyle :: Int -> S.Style
headerStyle 1 =
  S.fontCinzel
    <> S.textGoldBright
    <> S.text2Xl
    <> S.borderB2
    <> S.borderGoldMuted
    <> S.pb S.S2
    <> S.my S.S4
headerStyle 2 =
  S.fontCinzel
    <> S.textGoldBright
    <> S.textXl
    <> S.my S.S3
headerStyle 3 =
  S.fontCinzel
    <> S.textGoldMuted
    <> S.textLg
    <> S.my S.S2
headerStyle 4 =
  S.fontCinzel
    <> S.textGoldMuted
    <> S.textBase
    <> S.fontBold
    <> S.my S.S2
headerStyle 5 =
  S.fontCinzel
    <> S.textGoldMuted
    <> S.textSm
    <> S.fontBold
    <> S.my S.S1
headerStyle _ =
  S.fontCinzel
    <> S.textGoldMuted
    <> S.textXs
    <> S.fontBold
    <> S.my S.S1

paraStyle :: S.Style
paraStyle =
  S.fontLora
    <> S.text S.Gray 2
    <> S.my S.S2
    <> S.leadingRelaxed

blockquoteStyle :: S.Style
blockquoteStyle =
  S.borderL4
    <> S.borderGoldMuted
    <> S.pl S.S4
    <> S.my S.S3
    <> S.italic
    <> S.text S.Gray 3

bulletListStyle :: S.Style
bulletListStyle =
  S.listDisc
    <> S.pl S.S6
    <> S.my S.S2
    <> S.leadingRelaxed

orderedListStyle :: S.Style
orderedListStyle =
  S.listDecimal
    <> S.pl S.S6
    <> S.my S.S2
    <> S.leadingRelaxed

hrStyle :: S.Style
hrStyle =
  S.border S.Gray 7
    <> S.border1
    <> S.my S.S6

codeBlockStyle :: S.Style
codeBlockStyle =
  S.bgStoneDark
    <> S.p S.S4
    <> S.roundedLg
    <> S.overflowAuto
    <> S.borderStoneMed
    <> S.border1
    <> S.my S.S3

codeTextPreStyle :: S.Style
codeTextPreStyle =
  S.fontMono
    <> S.textGoldBright
    <> S.textSm

inlineCodeStyle :: S.Style
inlineCodeStyle =
  S.fontMono
    <> S.textGoldBright
    <> S.textSm
    <> S.px S.S1
    <> S.py S.S0_5
    <> S.rounded
    <> S.border1
    <> S.borderStoneMed
    <> S.bgStoneDark

strongStyle :: S.Style
strongStyle =
  S.fontBold
    <> S.text S.Gray 1

linkStyle :: S.Style
linkStyle =
  S.text S.Blue 4
    <> S.hover S.underline

tableStyle :: S.Style
tableStyle =
  S.wFull
    <> S.my S.S4
    <> S.overflowHidden
    <> S.rounded
    <> S.border1
    <> S.borderStoneMed

thStyle :: S.Style
thStyle =
  S.bgStoneDark
    <> S.textGoldBright
    <> S.fontCinzel
    <> S.p S.S3
    <> S.textLeft
    <> S.border1
    <> S.borderStoneMed

tdStyle :: S.Style
tdStyle =
  S.p S.S3
    <> S.border1
    <> S.borderStoneMed
    <> S.text S.Gray 2

defsListStyle :: S.Style
defsListStyle =
  S.my S.S3
    <> S.leadingRelaxed

defTermStyle :: S.Style
defTermStyle =
  S.fontBold
    <> S.textGoldBright
    <> S.mt S.S2

defDescStyle :: S.Style
defDescStyle =
  S.pl S.S4
    <> S.mb S.S2
    <> S.text S.Gray 2

kwStaticStyle :: S.Style
kwStaticStyle =
  S.textGoldBright
    <> S.hover S.underline
    <> S.cursorPointer

kwBadgeStyle :: S.Style
kwBadgeStyle =
  S.bgStoneDark
    <> S.border1
    <> S.borderGoldMuted
    <> S.rounded
    <> S.px S.S2
    <> S.py S.S0_5
    <> S.textGoldBright
    <> S.textSm
    <> S.inlineBlock

tooltipCardStyle :: S.Style
tooltipCardStyle =
  S.cls "game-kw-tooltip"
    <> S.absolute
    <> S.z 50
    <> S.hidden
    <> S.groupHoverBlock
    <> S.bottomFull
    <> S.left0
    <> S.mb S.S2
    <> S.w (S.Rem 18)
    <> S.p S.S3
    <> S.roundedLg
    <> S.border1
    <> S.borderGoldMuted
    <> S.bgStoneDark
    <> S.shadowXl
    <> S.textLeft

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Build DOM attributes combining an atomic CSS style with Pandoc element attributes.
buildAttrMap :: S.Style -> Attr -> Map Text Text -> Map Text Text
buildAttrMap style (elId, elClasses, elKvs) extraAttrs =
  let styleCls = classNames style
      combinedCls
        | null elClasses = styleCls
        | T.null styleCls = T.intercalate " " elClasses
        | otherwise = styleCls <> " " <> T.intercalate " " elClasses
      classAttr = if T.null combinedCls then Map.empty else "class" =: combinedCls
      idAttr = if T.null elId then Map.empty else "id" =: elId
   in idAttr <> classAttr <> Map.fromList elKvs <> extraAttrs

-- | Render an element with atomic styling and Pandoc attributes.
elSAttr :: (DomBuilder t m) => Text -> S.Style -> Attr -> m a -> m a
elSAttr tagName style attr = elAttr tagName (buildAttrMap style attr Map.empty)

-- | Convert list of inlines to plain text (e.g. for image alt text).
stringifyInlines :: [Inline] -> Text
stringifyInlines = \case
  [] -> ""
  (Str t : rest) -> t <> stringifyInlines rest
  (Space : rest) -> " " <> stringifyInlines rest
  (SoftBreak : rest) -> " " <> stringifyInlines rest
  (Code _ t : rest) -> t <> stringifyInlines rest
  (Emph xs : rest) -> stringifyInlines xs <> stringifyInlines rest
  (Strong xs : rest) -> stringifyInlines xs <> stringifyInlines rest
  (_ : rest) -> stringifyInlines rest

-- | Check whether a CodeBlock is a fenced card block (```card <id>).
isCardBlock :: Attr -> Bool
isCardBlock (cId, classes, _) =
  "card" `elem` classes || cId == "card"

-- | Render a fenced card block.
-- Placeholder implementation for Phase 2, dispatching to card art renderer in Phase 4.
renderCardBlock :: (DomBuilder t m) => RenderEnv -> Attr -> Text -> m ()
renderCardBlock _env (cId, classes, kvs) codeText = do
  let cardId = case lookup "id" kvs of
        Just cid -> cid
        Nothing ->
          let firstWord = case T.words (T.strip codeText) of
                (w : _) -> w
                [] -> ""
           in if not (T.null firstWord)
                then firstWord
                else
                  if not (T.null cId) && cId /= "card"
                    then cId
                    else case filter (/= "card") classes of
                      (c : _) -> c
                      [] -> "unknown"
  elAttr "div" ("class" =: "card-embed" <> "data-card-id" =: cardId) $ do
    divS (S.p S.S4 <> S.border1 <> S.borderGoldMuted <> S.roundedLg <> S.bgStoneDark <> S.my S.S3) $ do
      elS "span" (S.fontCinzel <> S.textGoldBright <> S.textSm) $
        text $
          "Card: " <> cardId

-- | Convert Pandoc ListAttributes to HTML ol attributes.
orderedListAttrs :: ListAttributes -> Map Text Text
orderedListAttrs (start, numStyle, _delim) =
  let startAttr = if start /= 1 then "start" =: T.pack (show start) else Map.empty
      styleAttr = case numStyle of
        LowerRoman -> "type" =: "i"
        UpperRoman -> "type" =: "I"
        LowerAlpha -> "type" =: "a"
        UpperAlpha -> "type" =: "A"
        _ -> Map.empty
   in startAttr <> styleAttr

--------------------------------------------------------------------------------
-- Document and Block Rendering
--------------------------------------------------------------------------------

-- | Render a complete Pandoc AST document.
renderPandoc :: (DomBuilder t m) => RenderEnv -> Pandoc -> m ()
renderPandoc env (Pandoc _meta blocks) =
  renderBlocks env blocks

-- | Render a list of Pandoc blocks.
renderBlocks :: (DomBuilder t m) => RenderEnv -> [Block] -> m ()
renderBlocks env = mapM_ (renderBlock env)

-- | Render a single Pandoc block with CardPG styling.
renderBlock :: (DomBuilder t m) => RenderEnv -> Block -> m ()
renderBlock env = \case
  Plain inlines ->
    renderInlines env inlines
  Para inlines ->
    elS "p" paraStyle $ renderInlines env inlines
  LineBlock lines' ->
    forM_ lines' $ \lineInlines -> do
      renderInlines env lineInlines
      el "br" (pure ())
  CodeBlock attr codeText
    | isCardBlock attr ->
        renderCardBlock env attr codeText
    | otherwise ->
        elSAttr "pre" codeBlockStyle attr $
          elS "code" codeTextPreStyle (text codeText)
  RawBlock (Format "html") rawHtml ->
    text rawHtml
  RawBlock _ rawText ->
    text rawText
  BlockQuote blocks ->
    elS "blockquote" blockquoteStyle $ renderBlocks env blocks
  OrderedList listAttrs items ->
    let attrs = buildAttrMap orderedListStyle ("", [], []) (orderedListAttrs listAttrs)
     in elAttr "ol" attrs $
          forM_ items $ \blks ->
            el "li" (renderBlocks env blks)
  BulletList items ->
    elS "ul" bulletListStyle $
      forM_ items $ \blks ->
        el "li" (renderBlocks env blks)
  DefinitionList defs ->
    elS "dl" defsListStyle $
      forM_ defs $ \(termInlines, descBlocksList) -> do
        elS "dt" defTermStyle (renderInlines env termInlines)
        forM_ descBlocksList $ \descBlocks ->
          elS "dd" defDescStyle (renderBlocks env descBlocks)
  Header level attr inlines ->
    elSAttr (headerTag level) (headerStyle level) attr $
      renderInlines env inlines
  HorizontalRule ->
    elS "hr" hrStyle (pure ())
  Table attr _caption _colSpecs (TableHead _ hrows) tbodys (TableFoot _ frows) ->
    elSAttr "table" tableStyle attr $ do
      unless (null hrows) $
        el "thead" $
          forM_ hrows $ \(Row _ cells) ->
            el "tr" $
              forM_ cells $ \(Cell _ _ _ _ blocks) ->
                elS "th" thStyle (renderBlocks env blocks)
      forM_ tbodys $ \(TableBody _ _ _ rows) ->
        el "tbody" $
          forM_ rows $ \(Row _ cells) ->
            el "tr" $
              forM_ cells $ \(Cell _ _ _ _ blocks) ->
                elS "td" tdStyle (renderBlocks env blocks)
      unless (null frows) $
        el "tfoot" $
          forM_ frows $ \(Row _ cells) ->
            el "tr" $
              forM_ cells $ \(Cell _ _ _ _ blocks) ->
                elS "td" tdStyle (renderBlocks env blocks)
  Div attr blocks ->
    elSAttr "div" mempty attr (renderBlocks env blocks)
  Figure attr (Caption _ captionBlocks) blocks ->
    elSAttr "figure" (S.my S.S4) attr $ do
      renderBlocks env blocks
      unless (null captionBlocks) $
        elS "figcaption" (S.textSm <> S.text S.Gray 4 <> S.textCenter <> S.mt S.S2) $
          renderBlocks env captionBlocks

--------------------------------------------------------------------------------
-- Inline Rendering
--------------------------------------------------------------------------------

-- | Check whether an element's attributes mark it as a Pandoc wikilink.
isWikilink :: Attr -> Bool
isWikilink (_, classes, _) = "wikilink" `elem` classes

-- | Colors of Action associated with keyword terms.
data ActionColor = RedAction | YellowAction | BlueAction
  deriving (Show, Eq)

termActionColor :: Text -> Maybe GlossaryEntry -> Maybe ActionColor
termActionColor term mEntry
  | norm == "red" || slug == Just "red" || canon == Just "red" = Just RedAction
  | norm == "yellow" || slug == Just "yellow" || canon == Just "yellow" = Just YellowAction
  | norm == "blue" || slug == Just "blue" || canon == Just "blue" = Just BlueAction
  | otherwise = Nothing
  where
    norm = T.toLower (T.strip term)
    slug = fmap (.slug) mEntry
    canon = fmap (T.toLower . (.canonical)) mEntry

renderActionColorChip :: (DomBuilder t m) => ActionColor -> m ()
renderActionColorChip = \case
  RedAction ->
    divS (S.w S.S6 <> S.h S.S6 <> S.border1 <> S.border S.Red 6 <> S.rounded <> S.p S.S0_5 <> S.my S.S1) $
      renderSquare (S.text S.Red 6) Nothing
  YellowAction ->
    divS
      (S.w S.S6 <> S.h S.S6 <> S.border1 <> S.border S.Yellow 5 <> S.rounded <> S.p S.S0_5 <> S.my S.S1)
      $ renderCircle (S.text S.Yellow 5) Nothing
  BlueAction ->
    divS
      (S.w S.S6 <> S.h S.S6 <> S.border1 <> S.border S.Blue 5 <> S.rounded <> S.p S.S0_5 <> S.my S.S1)
      $ renderDiamond (S.text S.Blue 5) Nothing

-- | Render a resolved or unresolved wikilink according to the current RenderMode.
renderWikilink :: (DomBuilder t m) => RenderEnv -> Text -> [Inline] -> Maybe GlossaryEntry -> m ()
renderWikilink env target inlines mEntry = case env.renderMode of
  RenderStatic ->
    renderStaticWikilink env target inlines mEntry
  RenderInteractive ->
    renderInteractiveWikilink env target inlines mEntry

-- | Static mode rendering: emits an anchor with class "game-kw kw-{category-slug}",
-- href pointing to glossary.html#{slug}, and title attribute containing summary.
renderStaticWikilink
  :: (DomBuilder t m) => RenderEnv -> Text -> [Inline] -> Maybe GlossaryEntry -> m ()
renderStaticWikilink env target inlines mEntry = do
  let slug = maybe (canonicalSlug target env.glossary) (.slug) mEntry
      catSlug = maybe "general" (toSlug . (.category)) mEntry
      summary = maybe target summaryText mEntry
      classes = "game-kw kw-" <> catSlug <> " " <> classNames kwStaticStyle
      attrs =
        "class" =: classes
          <> "href" =: ("glossary.html#" <> slug)
          <> "title" =: summary
  elAttr "a" attrs $
    if null inlines
      then text target
      else renderInlines env inlines

-- | Render RichText inside a tooltip hover card, rendering keyword references
-- as styled highlight spans rather than spawning nested interactive popovers.
renderTooltipRichText :: (DomBuilder t m) => RichText -> m ()
renderTooltipRichText rt = mapM_ renderTooltipInline (NE.toList (getInlines rt))

renderTooltipInline :: (DomBuilder t m) => CoreRichText.Inline -> m ()
renderTooltipInline = \case
  CoreRichText.TextRun mStyle content ->
    case mStyle of
      Nothing -> text (getRawText content)
      Just Bold -> elS "strong" strongStyle $ text (getRawText content)
      Just Italic -> el "em" $ text (getRawText content)
      Just GameKeyword -> elS "code" inlineCodeStyle $ text (getRawText content)
  CoreRichText.Wikilink target mLabel ->
    let displayTxt = maybe (getRawText target) getRawText mLabel
     in elS "span" (S.textGoldBright <> S.fontBold) (text displayTxt)
  CoreRichText.MarkdownLink target label ->
    elAttr
      "a"
      ("href" =: getRawText target <> "class" =: classNames linkStyle)
      (text (getRawText label))
  CoreRichText.Break ->
    el "br" (pure ())
  CoreRichText.ColorValue v ->
    renderResourceType IconInline v.color (Just (tshow v.value))
  CoreRichText.DifficultyValue d ->
    renderResourceType IconInline d.attribute (Just (tshow d.value))

-- | Interactive mode rendering: emits an interactive popover / tooltip component
-- with an inline badge chip and a hover/focus-revealed tooltip card.
renderInteractiveWikilink
  :: (DomBuilder t m) => RenderEnv -> Text -> [Inline] -> Maybe GlossaryEntry -> m ()
renderInteractiveWikilink env target inlines mEntry = do
  let catName = maybe "Keyword" (.category) mEntry
      mActionColor = termActionColor target mEntry
      isActive = case env.activeKeyword of
        Nothing -> False
        Just "all" -> True
        Just kw -> kw == target
      wrapStyle =
        S.relative
          <> S.inlineBlock
          <> S.cls "group"
          <> S.cursorPointer
          <> (if isActive then S.cls "active-kw" else mempty)
      displayName = case mEntry of
        Just entry | entry.canonical /= target -> entry.canonical <> " (" <> target <> ")"
        _ -> target
  elAttr "span" ("class" =: ("game-kw-interactive " <> classNames wrapStyle) <> "tabindex" =: "0") $ do
    elAttr "span" ("class" =: ("game-kw-badge " <> classNames kwBadgeStyle)) $
      if null inlines
        then text target
        else renderInlines env inlines
    divS tooltipCardStyle $ do
      divS (S.flexRow <> S.justifyBetween <> S.itemsCenter <> S.gap S.S2 <> S.mb S.S1) $ do
        elS "span" (S.fontCinzel <> S.textGoldBright <> S.textSm <> S.fontBold) (text displayName)
        elS "span" (S.textXs <> S.text S.Gray 4 <> S.uppercase <> S.trackingWider) (text catName)
      forM_ mActionColor renderActionColorChip
      divS (S.fontLora <> S.text S.Gray 2 <> S.leadingRelaxed <> S.textSm) $ do
        case mEntry of
          Just entry -> renderTooltipRichText entry.summary
          Nothing -> text ("Rules keyword: " <> target)

-- | Interactive mode rendering helper for plain text display labels.
renderInteractiveWikilinkText
  :: (DomBuilder t m) => RenderEnv -> Text -> Text -> Maybe GlossaryEntry -> m ()
renderInteractiveWikilinkText env target dispText =
  renderInteractiveWikilink env target [Str dispText]

-- | Render a list of Pandoc inlines.
renderInlines :: (DomBuilder t m) => RenderEnv -> [Inline] -> m ()
renderInlines env = mapM_ (renderInline env)

-- | Render a single Pandoc inline element.
renderInline :: (DomBuilder t m) => RenderEnv -> Inline -> m ()
renderInline env = \case
  Str t ->
    text t
  Emph inlines ->
    el "em" $ renderInlines env inlines
  Strong inlines ->
    elS "strong" strongStyle $ renderInlines env inlines
  Underline inlines ->
    elS "span" S.underline $ renderInlines env inlines
  Strikeout inlines ->
    el "s" $ renderInlines env inlines
  Superscript inlines ->
    el "sup" $ renderInlines env inlines
  Subscript inlines ->
    el "sub" $ renderInlines env inlines
  SmallCaps inlines ->
    el "small" $ renderInlines env inlines
  Quoted SingleQuote inlines -> do
    text "‘"
    renderInlines env inlines
    text "’"
  Quoted DoubleQuote inlines -> do
    text "“"
    renderInlines env inlines
    text "”"
  Cite _ inlines ->
    renderInlines env inlines
  Code attr codeText ->
    elSAttr "code" inlineCodeStyle attr (text codeText)
  Space ->
    text " "
  SoftBreak ->
    text " "
  LineBreak ->
    el "br" (pure ())
  Math _ mathText ->
    elS "code" inlineCodeStyle (text mathText)
  RawInline _ rawText ->
    text rawText
  Link attr inlines (url, title)
    | isWikilink attr ->
        renderWikilink env url inlines (lookupGlossary url env.glossary)
    | otherwise ->
        let extraAttrs =
              ("href" =: url)
                <> (if T.null title then Map.empty else "title" =: title)
            attrs = buildAttrMap linkStyle attr extraAttrs
         in elAttr "a" attrs $ renderInlines env inlines
  Image attr inlines (src, title) ->
    let extraAttrs =
          ("src" =: src)
            <> (if T.null title then Map.empty else "title" =: title)
            <> ("alt" =: stringifyInlines inlines)
        attrs = buildAttrMap mempty attr extraAttrs
     in elAttr "img" attrs (pure ())
  Note blocks ->
    elS "span" (S.textSm <> S.text S.Gray 4) (renderBlocks env blocks)
  Span attr inlines ->
    elSAttr "span" mempty attr (renderInlines env inlines)
