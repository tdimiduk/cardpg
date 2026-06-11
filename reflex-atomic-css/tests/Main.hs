{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Text (Text)
import Data.Text qualified as T
import Test.QuickCheck
import Test.Tasty
import Test.Tasty.QuickCheck
import Text.Megaparsec (parse)

import Reflex.AtomicCss.DSL qualified as S
import Reflex.AtomicCss.Parser

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "Reflex.AtomicCss.Parser Tests"
    [ testProperty "parseStringLiteral with escapes" prop_stringLiteral
    , testProperty "staticStyles parsing in isolation" prop_staticStyle
    , testProperty "gap (size) parsing in isolation" prop_gap
    , testProperty "p (size) parsing in isolation" prop_p
    , testProperty "fontSize (int) parsing in isolation" prop_fontSize
    , testProperty "opacity (float) parsing in isolation" prop_opacity
    , testProperty "bg (color + tone) parsing in isolation" prop_bg
    , testProperty "bgAlpha (color + tone + alpha) parsing in isolation" prop_bgAlpha
    , testProperty "css (name + prop + val) parsing in isolation" prop_css
    , testProperty "css' (name + decls) parsing in isolation" prop_cssPrime
    , testProperty "media (query + substyle) parsing in isolation" prop_media
    , testProperty "mixed content scanning (integration)" prop_mixedContent
    ]

--------------------------------------------------------------------------------
-- Arbitrary Instances & Generators
--------------------------------------------------------------------------------

-- | Generate double values that won't format in scientific notation.
genPosDouble :: Gen Double
genPosDouble = do
  n <- choose (1 :: Int, 1000)
  d <- choose (0 :: Int, 99)
  return (fromIntegral n + fromIntegral d / 100.0)

instance Arbitrary S.Size where
  arbitrary =
    oneof
      [ pure S.S0
      , pure S.S0_5
      , pure S.S1
      , pure S.S2
      , pure S.S3
      , pure S.S4
      , pure S.S5
      , pure S.S6
      , pure S.S7
      , pure S.S8
      , pure S.S9
      , pure S.S10
      , pure S.S11
      , pure S.S12
      , pure S.S13
      , pure S.S14
      , pure S.S15
      , S.Rem <$> genPosDouble
      , S.Px <$> genPosDouble
      , S.Vh <$> genPosDouble
      , S.Vw <$> genPosDouble
      , S.Percent <$> genPosDouble
      , S.Mm <$> genPosDouble
      , S.Em <$> genPosDouble
      ]

genColor :: Gen S.Color
genColor =
  elements
    [ S.Gray
    , S.Red
    , S.Blue
    , S.Indigo
    , S.Yellow
    , S.Amber
    , S.White
    , S.Black
    , S.Transparent
    ]

sizeToHaskell :: S.Size -> Gen Text
sizeToHaskell sz = do
  prefix <- elements ["", "S."]
  case sz of
    S.S0 -> return $ prefix <> "S0"
    S.S0_5 -> return $ prefix <> "S0_5"
    S.S1 -> return $ prefix <> "S1"
    S.S2 -> return $ prefix <> "S2"
    S.S3 -> return $ prefix <> "S3"
    S.S4 -> return $ prefix <> "S4"
    S.S5 -> return $ prefix <> "S5"
    S.S6 -> return $ prefix <> "S6"
    S.S7 -> return $ prefix <> "S7"
    S.S8 -> return $ prefix <> "S8"
    S.S9 -> return $ prefix <> "S9"
    S.S10 -> return $ prefix <> "S10"
    S.S11 -> return $ prefix <> "S11"
    S.S12 -> return $ prefix <> "S12"
    S.S13 -> return $ prefix <> "S13"
    S.S14 -> return $ prefix <> "S14"
    S.S15 -> return $ prefix <> "S15"
    S.Rem d -> genCon prefix "Rem" d
    S.Px d -> genCon prefix "Px" d
    S.Vh d -> genCon prefix "Vh" d
    S.Vw d -> genCon prefix "Vw" d
    S.Percent d -> genCon prefix "Percent" d
    S.Mm d -> genCon prefix "Mm" d
    S.Em d -> genCon prefix "Em" d
  where
    genCon prefix con d = do
      innerPrefix <- elements ["", "S."]
      let valStr = T.pack (show d)
      elements
        [ prefix <> con <> " " <> valStr
        , prefix <> con <> " (" <> valStr <> ")"
        , innerPrefix <> prefix <> con <> " (" <> valStr <> ")"
        ]

colorToHaskell :: S.Color -> Gen Text
colorToHaskell c = do
  prefix <- elements ["", "S."]
  let name = T.pack (show c)
  elements
    [ prefix <> name
    , "(" <> prefix <> name <> ")"
    ]

wrapNoise :: Text -> Gen Text
wrapNoise expr = do
  s1 <- genSpaces
  s2 <- genSpaces
  useParens <- arbitrary
  if useParens
    then do
      s3 <- genSpaces
      s4 <- genSpaces
      return $ s1 <> "(" <> s3 <> expr <> s4 <> ")" <> s2
    else
      return $ s1 <> expr <> s2
  where
    genSpaces = do
      n <- choose (0, 3)
      return $ T.replicate n " "

--------------------------------------------------------------------------------
-- Properties
-- All properties check that when we construct a style via Megaparsec scanner,
-- it evaluates to the same Prop list as evaluating it in Haskell directly.
--------------------------------------------------------------------------------

prop_stringLiteral :: Property
prop_stringLiteral = forAll genStringWithEscapes $ \s ->
  let printed = T.pack (show s)
      parsed = parse parseStringLiteral "" printed
   in case parsed of
        Left err ->
          counterexample
            ("String: " <> show s <> "\nPrinted: " <> T.unpack printed <> "\nError: " <> show err)
            False
        Right val -> val === T.pack s
  where
    genStringWithEscapes =
      listOf (elements $ ['a' .. 'z'] ++ ['A' .. 'Z'] ++ ['0' .. '9'] ++ [' ', '\n', '\t', '\\', '"'])

prop_staticStyle :: Property
prop_staticStyle = forAll (elements staticStyles) $ \(name, expected) ->
  forAll (genCall name) $ \callExpr ->
    let parsed = parse parseStatic "" callExpr
     in case parsed of
          Left err -> counterexample ("Expr: " <> T.unpack callExpr <> "\nError: " <> show err) False
          Right val -> val === expected
  where
    genCall name = do
      prefix <- elements ["", "S."]
      return (prefix <> name)

prop_sizeParamHelper :: Text -> (S.Size -> S.Style) -> S.Size -> Property
prop_sizeParamHelper name applyFn sz = forAll genCall $ \callExpr ->
  let parsed = scanContent callExpr
      expected = applyFn sz []
   in counterexample
        ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
        $ parsed === expected
  where
    genCall = do
      szStr <- sizeToHaskell sz
      fnPrefix <- elements ["", "S."]
      wrapNoise (fnPrefix <> name <> " " <> szStr)

prop_gap :: S.Size -> Property
prop_gap = prop_sizeParamHelper "gap" S.gap

prop_p :: S.Size -> Property
prop_p = prop_sizeParamHelper "p" S.p

prop_fontSize :: Property
prop_fontSize = forAll (choose (-100, 1000)) $ \val ->
  forAll (genCall val) $ \callExpr ->
    let parsed = scanContent callExpr
        expected = S.fontSize val []
     in counterexample
          ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
          $ parsed === expected
  where
    genCall val = do
      fnPrefix <- elements ["", "S."]
      let valStr = T.pack (show val)
      wrapNoise (fnPrefix <> "fontSize " <> valStr)

prop_opacity :: Property
prop_opacity = forAll (choose (0.0 :: Double, 1.0 :: Double)) $ \val ->
  forAll (genCall val) $ \callExpr ->
    let parsed = scanContent callExpr
        expected = S.opacity val []
     in counterexample
          ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
          $ parsed === expected
  where
    genCall val = do
      fnPrefix <- elements ["", "S."]
      let valStr = T.pack (show val)
      valStrWrapped <- elements [valStr, "(" <> valStr <> ")"]
      wrapNoise (fnPrefix <> "opacity " <> valStrWrapped)

prop_bg :: Property
prop_bg = forAll genColor $ \c ->
  forAll (choose (0, 100)) $ \tone ->
    forAll (genCall c tone) $ \callExpr ->
      let parsed = scanContent callExpr
          expected = S.bg c tone []
       in counterexample
            ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
            $ parsed === expected
  where
    genCall c tone = do
      fnPrefix <- elements ["", "S."]
      cStr <- colorToHaskell c
      let toneStr = T.pack (show tone)
      wrapNoise (fnPrefix <> "bg " <> cStr <> " " <> toneStr)

prop_bgAlpha :: Property
prop_bgAlpha = forAll genColor $ \c ->
  forAll (choose (0, 100)) $ \tone ->
    forAll (choose (0, 100)) $ \alpha ->
      forAll (genCall c tone alpha) $ \callExpr ->
        let parsed = scanContent callExpr
            expected = S.bgAlpha c tone alpha []
         in counterexample
              ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
              $ parsed === expected
  where
    genCall c tone alpha = do
      fnPrefix <- elements ["", "S."]
      cStr <- colorToHaskell c
      let toneStr = T.pack (show tone)
          alphaStr = T.pack (show alpha)
      wrapNoise (fnPrefix <> "bgAlpha " <> cStr <> " " <> toneStr <> " " <> alphaStr)

genSafeString :: Gen Text
genSafeString = do
  s <- listOf1 (elements (['a' .. 'z'] ++ ['A' .. 'Z'] ++ ['0' .. '9'] ++ ['-']))
  return $ T.pack s

prop_css :: Property
prop_css = forAll genSafeString $ \n ->
  forAll genSafeString $ \p ->
    forAll genSafeString $ \v ->
      forAll (genCall n p v) $ \callExpr ->
        let parsed = scanContent callExpr
            expected = S.css n p v []
         in counterexample
              ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
              $ parsed === expected
  where
    genCall n p v = do
      fnPrefix <- elements ["", "S."]
      let nStr = "\"" <> n <> "\""
          pStr = "\"" <> p <> "\""
          vStr = "\"" <> v <> "\""
      wrapNoise (fnPrefix <> "css " <> nStr <> " " <> pStr <> " " <> vStr)

prop_cssPrime :: Property
prop_cssPrime = forAll genSafeString $ \n ->
  forAll (listOf1 ((,) <$> genSafeString <*> genSafeString)) $ \decls ->
    forAll (genCall n decls) $ \callExpr ->
      let parsed = scanContent callExpr
          expected = S.css' n decls []
       in counterexample
            ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
            $ parsed === expected
  where
    genCall n decls = do
      fnPrefix <- elements ["", "S."]
      let nStr = "\"" <> n <> "\""
          declStr = "[" <> T.intercalate ", " (map (\(p, v) -> "(\"" <> p <> "\", \"" <> v <> "\")") decls) <> "]"
      wrapNoise (fnPrefix <> "css' " <> nStr <> " " <> declStr)

prop_media :: Property
prop_media = forAll genSafeString $ \q ->
  forAll genSubStyle $ \(subStr, subProps) ->
    forAll (genCall q subStr) $ \callExpr ->
      let parsed = scanContent callExpr
          expected = map (S.mediaProp q) subProps
       in counterexample
            ("Expr: " <> T.unpack callExpr <> "\nExpected: " <> show expected <> "\nParsed: " <> show parsed)
            $ parsed === expected
  where
    genSubStyle =
      oneof
        [ do
            (name, props) <- elements staticStyles
            prefix <- elements ["", "S."]
            return (prefix <> name, props)
        , do
            sz <- arbitrary
            szStr <- sizeToHaskell sz
            prefix <- elements ["", "S."]
            return (prefix <> "gap " <> szStr, S.gap sz [])
        ]
    genCall q subStr = do
      fnPrefix <- elements ["", "S."]
      let qStr = "\"" <> q <> "\""
      wrapNoise (fnPrefix <> "media " <> qStr <> " " <> subStr)

prop_mixedContent :: Property
prop_mixedContent = forAll (listOf genItem) $ \items ->
  let fileContent = T.unlines (map fst items)
      expected = concatMap snd items
      parsed = scanContent fileContent
   in counterexample
        ( "Content:\n"
            <> T.unpack fileContent
            <> "\nExpected: "
            <> show expected
            <> "\nParsed: "
            <> show parsed
        )
        $ parsed === expected
  where
    genItem =
      oneof
        [ do
            sz <- arbitrary
            szStr <- sizeToHaskell sz
            prefix <- elements ["", "S."]
            expr <- wrapNoise (prefix <> "gap " <> szStr)
            return (expr, S.gap sz [])
        , do
            word <-
              elements
                [ "module"
                , "import"
                , "where"
                , "Main"
                , "myWidget"
                , "::"
                , "DomBuilder"
                , "->"
                , "text"
                , "\"Hello\""
                , "class"
                , "instance"
                , "="
                , "+"
                , ","
                , "{"
                , "}"
                ]
            return (word, [])
        ]
