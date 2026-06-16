{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module Reflex.AtomicCss.Parser
  ( Parser
  , ParamFn (..)
  , knownParams
  , staticStyles
  , scanContent
  , parseAny
  , parseParam
  , tryParam
  , parseSize
  , parseInt
  , parseNumber
  , parseColor
  , parseColorAndTone
  , parseColorToneAlpha
  , parseFloat
  , parseStringLiteral
  , escapedChar
  , parseThreeStrings
  , parseMedia
  , parseStyle
  , parseStatic
  , parseNameAndDecls
  , parseDecl
  ) where

import Data.Char (isAlphaNum, toUpper)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

import Data.Map.Strict qualified as Map
import Reflex.AtomicCss.Core (Prop (..), Style (..), getProps)
import Reflex.AtomicCss.DSL qualified as S

type Parser = Parsec Void Text

-- | Convert a CSS class name back to its Haskell DSL identifier name.
classNameToHaskell :: Text -> Text
classNameToHaskell = \case
  -- Semantic / Custom aliases
  "bg-gray-0" -> "bgWhite"
  "bg-transparent" -> "bgTransparent"
  "text-gray-12" -> "textBlack"
  "text-gray-0" -> "textWhite"
  "border-gray-12" -> "borderBlack"
  "border-transparent" -> "borderTransparent"
  "truncate" -> "textTruncate"
  "h-pct-40" -> "h2_5"
  "border-0.2mm" -> "border02mm"
  "aspect-4/3" -> "aspect43"
  "w-pct-100" -> "wFull"
  "h-pct-100" -> "hFull"
  "h-vh-100" -> "hScreen"
  "border" -> "border1" -- S.border1 [] uses class name "border"

  -- Fallback to standard camelCase translation
  className ->
    let parts = T.splitOn "-" className
     in case parts of
          [] -> ""
          (x : xs) -> T.concat (x : map capitalize xs)
  where
    capitalize w =
      case T.uncons w of
        Nothing -> ""
        Just (c, rest) ->
          let c' = toUpper c
           in if
                | c' == '3' && rest == "xl" -> "3Xl"
                | c' == '2' && rest == "xl" -> "2Xl"
                | otherwise -> T.cons c' rest

-- | Extract Haskell identifier name from a list of Props
propsToHaskellName :: [Prop] -> Text
propsToHaskellName props =
  let classNamesList = map (.propClassName) props
   in case classNamesList of
        ["w-pct-100", "h-pct-100"] -> "full" -- Special compound style 'full'
        [clsName] -> classNameToHaskell clsName
        _ -> error $ "Unknown or unhandled compound style: " ++ show classNamesList

-- | Helper to build a static style tuple from its DSL value
mkStatic :: Style -> (Text, [Prop])
mkStatic style =
  let props = getProps style
   in (propsToHaskellName props, props)

-- | Static styles that don't take parameters
staticStyles :: [(Text, [Prop])]
staticStyles =
  map
    mkStatic
    [ S.flex
    , S.flexRow
    , S.flexCol
    , S.itemsCenter
    , S.itemsEnd
    , S.itemsStretch
    , S.justifyStart
    , S.justifyCenter
    , S.justifyBetween
    , S.justifyAround
    , S.grow
    , S.grow0
    , S.shrink0
    , S.absolute
    , S.relative
    , S.fixed
    , S.hidden
    , S.overflowHidden
    , S.overflowYAuto
    , S.cursorPointer
    , S.cursorNotAllowed
    , S.pointerEventsNone
    , S.pointerEventsAuto
    , S.group
    , S.inlineBlock
    , S.alignTextBottom
    , S.flexWrap
    , S.contentStart
    , S.wFull
    , S.hFull
    , S.wFit
    , S.hScreen
    , S.h2_5
    , S.bottom0
    , S.left0
    , S.right0
    , S.inset0
    , S.bgWhite
    , S.bgTransparent
    , S.textBlack
    , S.textWhite
    , S.borderBlack
    , S.borderTransparent
    , S.border1
    , S.border0
    , S.border2
    , S.borderB
    , S.borderT
    , S.borderL
    , S.borderR
    , S.border02mm
    , S.rounded
    , S.roundedNone
    , S.roundedXl
    , S.rounded3Xl
    , S.roundedFull
    , S.fontBold
    , S.textSm
    , S.textXs
    , S.textXl
    , S.text2Xl
    , S.textLg
    , S.textBase
    , S.textCenter
    , S.leadingTight
    , S.uppercase
    , S.trackingWider
    , S.whitespaceNowrap
    , S.textTruncate
    , S.textLeft
    , S.shadow2Xl
    , S.shadowXl
    , S.shadowLg
    , S.shadowSm
    , S.grayscale
    , S.grayscale50
    , S.opacity75
    , S.opacity50
    , S.backdropBlurMd
    , S.aspect43
    , S.aspectSquare
    , S.spaceY2
    , S.transitionAll
    , S.transitionTransform
    , S.transitionColors
    , S.duration200
    , S.easeOut
    , S.selectNone
    , S.ring2
    , S.ringOffset2
    , S.flex1
    , S.full
    , S.mb0
    , S.minW0
    , S.minH0
    , S.fontMono
    ]

-- | Parameterized functions
data ParamFn = forall a. ParamFn
  { fnName :: Text
  , fnParse :: Parser a
  , fnApply :: a -> [Prop]
  }

knownParams :: [ParamFn]
knownParams =
  [ ParamFn "gap" parseSize (getProps . S.gap)
  , ParamFn "p" parseSize (getProps . S.p)
  , ParamFn "px" parseSize (getProps . S.px)
  , ParamFn "py" parseSize (getProps . S.py)
  , ParamFn "pt" parseSize (getProps . S.pt)
  , ParamFn "pb" parseSize (getProps . S.pb)
  , ParamFn "pl" parseSize (getProps . S.pl)
  , ParamFn "pr" parseSize (getProps . S.pr)
  , ParamFn "mt" parseSize (getProps . S.mt)
  , ParamFn "mb" parseSize (getProps . S.mb)
  , ParamFn "ml" parseSize (getProps . S.ml)
  , ParamFn "mr" parseSize (getProps . S.mr)
  , ParamFn "bottom" parseSize (getProps . S.bottom)
  , ParamFn "left" parseSize (getProps . S.left)
  , ParamFn "right" parseSize (getProps . S.right)
  , ParamFn "top" parseSize (getProps . S.top)
  , ParamFn "fontSize" parseInt (getProps . S.fontSize)
  , ParamFn "w" parseSize (getProps . S.w)
  , ParamFn "h" parseSize (getProps . S.h)
  , ParamFn "z" parseInt (getProps . S.z)
  , ParamFn "opacity" parseFloat (getProps . S.opacity)
  , ParamFn "css" parseThreeStrings (\(n, p, v) -> getProps (S.css n p v))
  , ParamFn "css'" parseNameAndDecls (\(n, ds) -> getProps (S.css' n ds))
  , ParamFn "bg" parseColorAndTone (\(c, n) -> getProps (S.bg c n))
  , ParamFn "bgAlpha" parseColorToneAlpha (\(c, n, a) -> getProps (S.bgAlpha c n a))
  , ParamFn "text" parseColorAndTone (\(c, n) -> getProps (S.text c n))
  , ParamFn "border" parseColorAndTone (\(c, n) -> getProps (S.border c n))
  , ParamFn "ring" parseColorAndTone (\(c, n) -> getProps (S.ring c n))
  , ParamFn "media" parseMedia snd
  , ParamFn "cls" parseStringLiteral (getProps . S.cls)
  , ParamFn "roundedS" parseSize (getProps . S.roundedS)
  , ParamFn "surface" parseInt (getProps . S.surface)
  , ParamFn "borderAlpha" parseColorToneAlpha (\(c, n, a) -> getProps (S.borderAlpha c n a))
  , ParamFn "minW" parseSize (getProps . S.minW)
  , ParamFn "minH" parseSize (getProps . S.minH)
  , ParamFn "shadow" parseInt (getProps . S.shadow)
  ]

staticStylesMap :: Map.Map Text [Prop]
staticStylesMap = Map.fromList staticStyles

knownParamsMap :: Map.Map Text ParamFn
knownParamsMap = Map.fromList [(fn.fnName, fn) | fn <- knownParams]

parseIdentifier :: Parser Text
parseIdentifier = do
  first <- letterChar <|> char '_'
  rest <- many (alphaNumChar <|> char '_' <|> char '\'')
  return $ T.pack (first : rest)

parseStyleExpr :: Parser [Prop]
parseStyleExpr = do
  terms <- sepBy1 parseStyleDotChain (try (space *> char '$' *> space))
  return $ concat terms

parseStyleDotChain :: Parser [Prop]
parseStyleDotChain = do
  terms <- sepBy1 parseStyleTerm (try (space *> string "<>" *> space))
  return $ concat terms

parseDecls :: Parser [(Text, Text)]
parseDecls = do
  _ <- char '['
  space
  ds <- sepBy parseDecl (space >> char ',' >> space)
  space
  _ <- char ']'
  return ds

parseStyleTerm :: Parser [Prop]
parseStyleTerm = do
  choice
    [ char '(' *> space *> parseStyleExpr <* space <* char ')'
    , do
        _ <- optional (string "S.")
        ident <- parseIdentifier
        if
          | ident == "hover" -> do
              space1
              map S.hoverProp <$> parseStyleTerm
          | ident == "active" -> do
              space1
              map S.activeProp <$> parseStyleTerm
          | ident == "lastChild" -> do
              space1
              map S.lastChildProp <$> parseStyleTerm
          | ident == "pseudo" -> do
              space1
              pseudoClass <- parseStringLiteral
              space1
              map (S.pseudoProp pseudoClass) <$> parseStyleTerm
          | ident == "media" -> do
              space1
              q <- parseStringLiteral
              space1
              map (S.mediaProp q) <$> parseStyleTerm
          | ident == "customSelector" -> do
              space1
              name <- parseStringLiteral
              space1
              selector <- parseStringLiteral
              space1
              getProps . S.customSelector name selector <$> parseDecls
          | otherwise -> case Map.lookup ident staticStylesMap of
              Just props -> return props
              Nothing -> case Map.lookup ident knownParamsMap of
                Just (ParamFn _ parser applyFn) -> do
                  space1
                  applyFn <$> parser
                Nothing -> fail $ "Unknown identifier: " ++ T.unpack ident
    ]

scanContent :: Text -> [Prop]
scanContent content = case parse (many parseAny) "" content of
  Left err -> error $ "Parse error: " ++ errorBundlePretty err
  Right parsedChunks -> concat parsedChunks

parseAny :: Parser [Prop]
parseAny = try parseStyleExpr <|> (anySingle >> return [])

parseParam :: Parser [Prop]
parseParam = do
  _ <- optional (string "S.")
  ident <- parseIdentifier
  case Map.lookup ident knownParamsMap of
    Just (ParamFn _ parser applyFn) -> do
      space1
      applyFn <$> parser
    Nothing -> fail $ "Not a known parameterized style: " ++ T.unpack ident

tryParam :: ParamFn -> Parser [Prop]
tryParam (ParamFn name p applyFn) = do
  let callParser = do
        _ <- optional (string "S.")
        _ <- string name
        notFollowedBy (satisfy (\c -> isAlphaNum c || c == '_'))
        space1
        p

  arg <- (char '(' *> space *> callParser <* space <* char ')') <|> callParser
  return $ applyFn arg

-- | Parsers
parseSize :: Parser S.Size
parseSize = do
  _ <- optional (string "S.")
  (char '(' *> space *> pSize <* space <* char ')') <|> pSize
  where
    parseS s = s <$ string (T.pack $ show s)
    pSize = do
      _ <- optional (string "S.")
      choice $
        fmap
          parseS
          [ S.S0_5
          , S.S10
          , S.S11
          , S.S12
          , S.S13
          , S.S14
          , S.S15
          , S.S0
          , S.S1
          , S.S2
          , S.S3
          , S.S4
          , S.S5
          , S.S6
          , S.S7
          , S.S8
          , S.S9
          ]
          <> [ try $ S.Rem <$> (string "Rem" *> space *> parseFloat)
             , try $ S.Px <$> (string "Px" *> space *> parseFloat)
             , try $ S.Vh <$> (string "Vh" *> space *> parseFloat)
             , try $ S.Vw <$> (string "Vw" *> space *> parseFloat)
             , try $ S.Percent <$> (string "Percent" *> space *> parseFloat)
             , try $ S.Mm <$> (string "Mm" *> space *> parseFloat)
             , try $ S.Em <$> (string "Em" *> space *> parseFloat)
             , try $ S.Rem . (/ 4) . fromIntegral <$> parseInt
             ]

parseInt :: Parser Int
parseInt = L.signed space L.decimal

parseNumber :: Parser Int
parseNumber = L.decimal

parseEnum :: (Show a, Bounded a, Enum a) => Parser a
parseEnum = choice [val <$ chunk (T.pack $ show val) | val <- [minBound .. maxBound]]

parseColor :: Parser S.Color
parseColor = do
  let pColor = do
        _ <- optional (chunk "S.")
        parseEnum
  (char '(' *> space *> pColor <* space <* char ')') <|> pColor

parseColorAndTone :: Parser (S.Color, Int)
parseColorAndTone = do
  _ <- optional (chunk "S.")
  c <- parseColor
  space1
  n <- parseNumber
  return (c, n)

parseColorToneAlpha :: Parser (S.Color, Int, Int)
parseColorToneAlpha = do
  _ <- optional (chunk "S.")
  c <- parseColor
  space1
  n <- parseNumber
  space1
  a <- parseNumber
  return (c, n, a)

parseFloat :: Parser Double
parseFloat = (char '(' *> space *> pFloat <* space <* char ')') <|> pFloat
  where
    pFloat = try (L.signed space L.float) <|> (fromIntegral <$> parseInt)

parseStringLiteral :: Parser Text
parseStringLiteral = do
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

parseThreeStrings :: Parser (Text, Text, Text)
parseThreeStrings = do
  n <- parseStringLiteral
  space1
  p <- parseStringLiteral
  space1
  v <- parseStringLiteral
  return (n, p, v)

parseMedia :: Parser (Text, [Prop])
parseMedia = do
  q <- parseStringLiteral
  space1
  props <- parseStyle
  return (q, map (S.mediaProp q) props)

parseStyle :: Parser [Prop]
parseStyle = try parseParam <|> parseStatic

parseStatic :: Parser [Prop]
parseStatic = do
  _ <- optional (string "S.")
  ident <- parseIdentifier
  case Map.lookup ident staticStylesMap of
    Just props -> return props
    Nothing -> fail $ "Not a static style: " ++ T.unpack ident

parseNameAndDecls :: Parser (Text, [(Text, Text)])
parseNameAndDecls = do
  n <- parseStringLiteral
  space1
  _ <- char '['
  space
  ds <- sepBy parseDecl (space >> char ',' >> space)
  space
  _ <- char ']'
  return (n, ds)

parseDecl :: Parser (Text, Text)
parseDecl = do
  _ <- char '('
  space
  p <- parseStringLiteral
  space
  _ <- char ','
  space
  v <- parseStringLiteral
  space
  _ <- char ')'
  return (p, v)
