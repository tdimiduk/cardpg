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

import Data.Char (isAlphaNum)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Void (Void)
import Text.Megaparsec
import Text.Megaparsec.Char
import Text.Megaparsec.Char.Lexer qualified as L

import Data.Map.Strict qualified as Map
import Reflex.AtomicCss.Core (Prop)
import Reflex.AtomicCss.DSL qualified as S

type Parser = Parsec Void Text

-- | Static styles that don't take parameters
staticStyles :: [(Text, [Prop])]
staticStyles =
  [ ("flex", S.flex [])
  , ("flexRow", S.flexRow [])
  , ("flexCol", S.flexCol [])
  , ("itemsCenter", S.itemsCenter [])
  , ("itemsEnd", S.itemsEnd [])
  , ("itemsStretch", S.itemsStretch [])
  , ("justifyStart", S.justifyStart [])
  , ("justifyCenter", S.justifyCenter [])
  , ("justifyBetween", S.justifyBetween [])
  , ("justifyAround", S.justifyAround [])
  , ("grow", S.grow [])
  , ("grow0", S.grow0 [])
  , ("shrink0", S.shrink0 [])
  , ("absolute", S.absolute [])
  , ("relative", S.relative [])
  , ("fixed", S.fixed [])
  , ("hidden", S.hidden [])
  , ("overflowHidden", S.overflowHidden [])
  , ("overflowYAuto", S.overflowYAuto [])
  , ("cursorPointer", S.cursorPointer [])
  , ("cursorNotAllowed", S.cursorNotAllowed [])
  , ("pointerEventsNone", S.pointerEventsNone [])
  , ("pointerEventsAuto", S.pointerEventsAuto [])
  , ("group", S.group [])
  , ("inlineBlock", S.inlineBlock [])
  , ("alignTextBottom", S.alignTextBottom [])
  , ("flexWrap", S.flexWrap [])
  , ("contentStart", S.contentStart [])
  , ("wFull", S.wFull [])
  , ("hFull", S.hFull [])
  , ("wFit", S.wFit [])
  , ("hScreen", S.hScreen [])
  , ("h2_5", S.h2_5 [])
  , ("bottom0", S.bottom0 [])
  , ("left0", S.left0 [])
  , ("right0", S.right0 [])
  , ("inset0", S.inset0 [])
  , ("bgWhite", S.bgWhite [])
  , ("bgTransparent", S.bgTransparent [])
  , ("textBlack", S.textBlack [])
  , ("textWhite", S.textWhite [])
  , ("borderBlack", S.borderBlack [])
  , ("borderTransparent", S.borderTransparent [])
  , ("border1", S.border1 [])
  , ("border0", S.border0 [])
  , ("border2", S.border2 [])
  , ("borderB", S.borderB [])
  , ("borderT", S.borderT [])
  , ("borderL", S.borderL [])
  , ("borderR", S.borderR [])
  , ("border02mm", S.border02mm [])
  , ("rounded", S.rounded [])
  , ("roundedNone", S.roundedNone [])
  , ("roundedXl", S.roundedXl [])
  , ("rounded3Xl", S.rounded3Xl [])
  , ("roundedFull", S.roundedFull [])
  , ("fontBold", S.fontBold [])
  , ("textSm", S.textSm [])
  , ("textXs", S.textXs [])
  , ("textXl", S.textXl [])
  , ("text2Xl", S.text2Xl [])
  , ("textLg", S.textLg [])
  , ("textBase", S.textBase [])
  , ("textCenter", S.textCenter [])
  , ("leadingTight", S.leadingTight [])
  , ("uppercase", S.uppercase [])
  , ("trackingWider", S.trackingWider [])
  , ("whitespaceNowrap", S.whitespaceNowrap [])
  , ("textTruncate", S.textTruncate [])
  , ("textLeft", S.textLeft [])
  , ("shadow2Xl", S.shadow2Xl [])
  , ("shadowXl", S.shadowXl [])
  , ("shadowLg", S.shadowLg [])
  , ("shadowSm", S.shadowSm [])
  , ("grayscale", S.grayscale [])
  , ("grayscale50", S.grayscale50 [])
  , ("opacity75", S.opacity75 [])
  , ("opacity50", S.opacity50 [])
  , ("backdropBlurMd", S.backdropBlurMd [])
  , ("aspect43", S.aspect43 [])
  , ("aspectSquare", S.aspectSquare [])
  , ("spaceY2", S.spaceY2 [])
  , ("transitionAll", S.transitionAll [])
  , ("transitionTransform", S.transitionTransform [])
  , ("transitionColors", S.transitionColors [])
  , ("duration200", S.duration200 [])
  , ("easeOut", S.easeOut [])
  , ("selectNone", S.selectNone [])
  , ("ring2", S.ring2 [])
  , ("ringOffset2", S.ringOffset2 [])
  , ("flex1", S.flex1 [])
  , ("full", S.full [])
  , ("mb0", S.mb0 [])
  , ("minW0", S.minW0 [])
  , ("minH0", S.minH0 [])
  , ("fontMono", S.fontMono [])
  ]

-- | Parameterized functions
data ParamFn = forall a. ParamFn
  { fnName :: Text
  , fnParse :: Parser a
  , fnApply :: a -> [Prop]
  }

knownParams :: [ParamFn]
knownParams =
  [ ParamFn "gap" parseSize (`S.gap` [])
  , ParamFn "p" parseSize (`S.p` [])
  , ParamFn "px" parseSize (`S.px` [])
  , ParamFn "py" parseSize (`S.py` [])
  , ParamFn "pt" parseSize (`S.pt` [])
  , ParamFn "pb" parseSize (`S.pb` [])
  , ParamFn "pl" parseSize (`S.pl` [])
  , ParamFn "pr" parseSize (`S.pr` [])
  , ParamFn "mt" parseSize (`S.mt` [])
  , ParamFn "mb" parseSize (`S.mb` [])
  , ParamFn "ml" parseSize (`S.ml` [])
  , ParamFn "mr" parseSize (`S.mr` [])
  , ParamFn "bottom" parseSize (`S.bottom` [])
  , ParamFn "left" parseSize (`S.left` [])
  , ParamFn "right" parseSize (`S.right` [])
  , ParamFn "top" parseSize (`S.top` [])
  , ParamFn "fontSize" parseInt (`S.fontSize` [])
  , ParamFn "w" parseSize (`S.w` [])
  , ParamFn "h" parseSize (`S.h` [])
  , ParamFn "z" parseInt (`S.z` [])
  , ParamFn "opacity" parseFloat (`S.opacity` [])
  , ParamFn "css" parseThreeStrings (\(n, p, v) -> S.css n p v [])
  , ParamFn "css'" parseNameAndDecls (\(n, ds) -> S.css' n ds [])
  , ParamFn "bg" parseColorAndTone (\(c, n) -> S.bg c n [])
  , ParamFn "bgAlpha" parseColorToneAlpha (\(c, n, a) -> S.bgAlpha c n a [])
  , ParamFn "text" parseColorAndTone (\(c, n) -> S.text c n [])
  , ParamFn "border" parseColorAndTone (\(c, n) -> S.border c n [])
  , ParamFn "ring" parseColorAndTone (\(c, n) -> S.ring c n [])
  , ParamFn "media" parseMedia snd
  , ParamFn "cls" parseStringLiteral (`S.cls` [])
  , ParamFn "roundedS" parseSize (`S.roundedS` [])
  , ParamFn "surface" parseInt (`S.surface` [])
  , ParamFn "borderAlpha" parseColorToneAlpha (\(c, n, a) -> S.borderAlpha c n a [])
  , ParamFn "minW" parseSize (`S.minW` [])
  , ParamFn "minH" parseSize (`S.minH` [])
  , ParamFn "shadow" parseInt (`S.shadow` [])
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
  terms <- sepBy1 parseStyleTerm (try (space *> char '.' *> space))
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
              decls <- parseDecls
              return $ S.customSelector name selector decls []
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
