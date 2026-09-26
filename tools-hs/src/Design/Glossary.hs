{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Design.Glossary
  ( parseGlossaryEntries
  , parseGlossaryText
  , parseGlossaryFile
  , parseGlossaryEntriesFile
  , validateGlossaryReferences
  , generateGlossaryHaskellSource
  , updateOrVerifyGlossary
  , glossaryMarkdownRelPath
  , glossaryHaskellRelPath
  ) where

import Control.Monad (void)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NE
import Data.Maybe (fromMaybe)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Data.Void (Void)
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath (takeDirectory)
import Text.Megaparsec
  ( Parsec
  , anySingle
  , eof
  , errorBundlePretty
  , lookAhead
  , many
  , manyTill
  , optional
  , parse
  , takeWhile1P
  , takeWhileP
  , try
  , (<|>)
  )
import Text.Megaparsec.Char (char, eol, hspace, string)

import Core.DSL (parseText)
import Core.Glossary (Glossary, GlossaryEntry (..), fromList, toSlug)
import Core.Language (TextStyle (..))
import Core.NonEmptyText (getRawText)
import Core.RichText (Inline (..), getInlines, unsafeSimpleString)

glossaryMarkdownRelPath :: FilePath
glossaryMarkdownRelPath = "rules/keyword-glossary.md"

glossaryHaskellRelPath :: FilePath
glossaryHaskellRelPath = "core/src/Core/Glossary/Generated.hs"

type Parser = Parsec Void Text

anyChar :: Parser Char
anyChar = anySingle

parseGlossaryFile :: FilePath -> IO Glossary
parseGlossaryFile path = do
  exists <- doesFileExist path
  if not exists
    then pure (fromList [])
    else do
      content <- TIO.readFile path
      pure $ parseGlossaryText content

parseGlossaryEntriesFile :: FilePath -> IO (Either String [GlossaryEntry])
parseGlossaryEntriesFile path = do
  exists <- doesFileExist path
  if not exists
    then pure (Left $ "Glossary file not found: " ++ path)
    else do
      content <- TIO.readFile path
      pure $ parseGlossaryEntries content

parseGlossaryEntries :: Text -> Either String [GlossaryEntry]
parseGlossaryEntries input = case parse glossaryDocParser "" input of
  Left err -> Left (errorBundlePretty err)
  Right entries -> Right entries

parseGlossaryText :: Text -> Glossary
parseGlossaryText input = case parseGlossaryEntries input of
  Left _ -> fromList []
  Right entries -> fromList entries

glossaryDocParser :: Parser [GlossaryEntry]
glossaryDocParser = do
  _ <- manyTill anyChar (lookAhead (try (void categoryHeader)) <|> eof)
  categories <- many (try categoryParser)
  pure (concat categories)

categoryHeader :: Parser Text
categoryHeader = do
  _ <- string "## "
  cat <- takeWhileP (Just "category name") (\c -> c /= '\n' && c /= '\r')
  _ <- optional eol
  pure (T.strip cat)

categoryParser :: Parser [GlossaryEntry]
categoryParser = do
  _ <- many (try (hspace *> eol))
  cat <- categoryHeader
  many (try (entryParser cat))

entryHeader :: Parser Text
entryHeader = do
  _ <- try (string "#### ") <|> try (string "### ")
  name <- takeWhileP (Just "entry name") (\c -> c /= '\n' && c /= '\r')
  _ <- optional eol
  pure (T.strip name)

entryParser :: Text -> Parser GlossaryEntry
entryParser cat = do
  _ <- many (try (hspace *> eol))
  name <- entryHeader
  mAliases <- optional (try aliasLineParser)
  let aliases = fromMaybe [] mAliases
  summaryLines <- manyTill summaryLine (lookAhead (try isNextHeading <|> void eof))
  let rawSummary = T.unwords (filter (not . T.null) (map T.strip summaryLines))
      summary = case parseText rawSummary of
        Right rt -> rt
        Left _ -> unsafeSimpleString rawSummary
      theme = case T.toLower name of
        "red" -> Just "red"
        "yellow" -> Just "yellow"
        "blue" -> Just "blue"
        _ -> Nothing
  pure
    GlossaryEntry
      { canonical = name
      , aliases = aliases
      , slug = toSlug name
      , category = cat
      , summary = summary
      , theme = theme
      }

isNextHeading :: Parser ()
isNextHeading = do
  _ <- many (try (hspace *> eol))
  _ <- string "##"
  pure ()

aliasLineParser :: Parser [Text]
aliasLineParser = do
  _ <- many (try (hspace *> eol))
  _ <- char '_' <|> char '*'
  _ <- string "Aliases:"
  content <- takeWhile1P (Just "aliases") (\c -> c /= '_' && c /= '*' && c /= '\n' && c /= '\r')
  _ <- char '_' <|> char '*'
  _ <- optional eol
  pure $ filter (not . T.null) $ map T.strip $ T.splitOn "," content

summaryLine :: Parser Text
summaryLine = do
  line <- takeWhileP (Just "summary line") (\c -> c /= '\n' && c /= '\r')
  _ <- optional eol
  pure line

--------------------------------------------------------------------------------
-- Referential Integrity Validation
--------------------------------------------------------------------------------

validateGlossaryReferences :: [GlossaryEntry] -> [String]
validateGlossaryReferences entries =
  let knownTerms =
        Set.fromList
          [ T.toLower (T.strip term)
          | e <- entries
          , term <- e.slug : e.canonical : e.aliases
          ]
      checkEntry e =
        [ "Unknown keyword reference '[["
            ++ T.unpack (getRawText target)
            ++ "]]' in definition of '"
            ++ T.unpack e.canonical
            ++ "'"
        | inline <- NE.toList (getInlines e.summary)
        , Wikilink target _ <- [inline]
        , not (Set.member (T.toLower (T.strip (getRawText target))) knownTerms)
        ]
   in concatMap checkEntry entries

--------------------------------------------------------------------------------
-- Haskell Code Generation
--------------------------------------------------------------------------------

ppText :: Text -> Text
ppText t = T.pack (show (T.unpack t))

ppMaybeText :: Maybe Text -> Text
ppMaybeText Nothing = "Nothing"
ppMaybeText (Just t) = "(Just (unsafeNonEmptyText " <> ppText t <> "))"

ppStyle :: Maybe TextStyle -> Text
ppStyle Nothing = "Nothing"
ppStyle (Just Bold) = "(Just Bold)"
ppStyle (Just Italic) = "(Just Italic)"
ppStyle (Just GameKeyword) = "(Just GameKeyword)"

ppInline :: Inline -> Text
ppInline = \case
  TextRun mStyle content ->
    "TextRun " <> ppStyle mStyle <> " (unsafeNonEmptyText " <> ppText (getRawText content) <> ")"
  Wikilink target mLbl ->
    "Wikilink (unsafeNonEmptyText "
      <> ppText (getRawText target)
      <> ") "
      <> ppMaybeText (fmap getRawText mLbl)
  MarkdownLink target lbl ->
    "MarkdownLink (unsafeNonEmptyText "
      <> ppText (getRawText target)
      <> ") (unsafeNonEmptyText "
      <> ppText (getRawText lbl)
      <> ")"
  Break ->
    "Break"
  ColorValue v ->
    "ColorValue (" <> T.pack (show v) <> ")"
  DifficultyValue d ->
    "DifficultyValue (" <> T.pack (show d) <> ")"

ppEntry :: GlossaryEntry -> Text
ppEntry e =
  let (first :| rest) = getInlines e.summary
      summaryLines =
        if null rest
          then "RichText (" <> ppInline first <> " NE.:| [])"
          else
            "RichText\n          ( "
              <> ppInline first
              <> "\n          NE.:|\n            [ "
              <> T.intercalate "\n            , " (map ppInline rest)
              <> "\n            ]\n          )"
      aliasesList = "[" <> T.intercalate ", " (map ppText e.aliases) <> "]"
      themeVal = case e.theme of
        Nothing -> "Nothing"
        Just th -> "Just " <> ppText th
   in T.unlines
        [ "  GlossaryEntry"
        , "    { canonical = " <> ppText e.canonical
        , "    , aliases = " <> aliasesList
        , "    , slug = " <> ppText e.slug
        , "    , category = " <> ppText e.category
        , "    , theme = " <> themeVal
        , "    , summary =\n        " <> summaryLines
        , "    }"
        ]

generateGlossaryHaskellSource :: [GlossaryEntry] -> Text
generateGlossaryHaskellSource entries =
  T.unlines
    [ "{-# LANGUAGE OverloadedStrings #-}"
    , "{- FOURMOLU_DISABLE -}"
    , ""
    , "-- |"
    , "-- Module: Core.Glossary.Generated"
    , "-- Description: Machine-generated keyword glossary data from design/rules/keyword-glossary.md."
    , "--"
    , "-- DO NOT EDIT THIS FILE DIRECTLY."
    , "-- To update, edit design/rules/keyword-glossary.md and run:"
    , "--   cabal run tools-hs:exe:audit-index -- --fix"
    , "-- or:"
    , "--   cabal run tools-hs:exe:keyword-mod -- codegen"
    , "module Core.Glossary.Generated"
    , "  ( glossary"
    , "  , glossaryEntries"
    , "  ) where"
    , ""
    , "import Core.Glossary.Types (Glossary, GlossaryEntry (..), fromList)"
    , "import Core.Language (TextStyle (..))"
    , "import Core.NonEmptyText (unsafeNonEmptyText)"
    , "import Core.RichText (Inline (..), RichText (..))"
    , "import Data.List.NonEmpty qualified as NE"
    , ""
    , "-- | Canonical keyword glossary constructed at compile time."
    , "glossary :: Glossary"
    , "glossary = fromList glossaryEntries"
    , ""
    , "-- | All canonical glossary entries in the order defined in the markdown."
    , "glossaryEntries :: [GlossaryEntry]"
    , "glossaryEntries ="
    , "  [ " <> T.stripEnd (T.intercalate "  , " (map ppEntry entries))
    , "  ]"
    ]

--------------------------------------------------------------------------------
-- Check & Fix Sync
--------------------------------------------------------------------------------

updateOrVerifyGlossary :: FilePath -> FilePath -> Bool -> IO (Either String (), Bool)
updateOrVerifyGlossary mdPath hsPath fix = do
  mdExists <- doesFileExist mdPath
  if not mdExists
    then pure (Left ("Glossary markdown file not found: " ++ mdPath), False)
    else do
      content <- TIO.readFile mdPath
      case parseGlossaryEntries content of
        Left err -> pure (Left ("Failed to parse glossary markdown: " ++ err), False)
        Right entries -> do
          let refErrs = validateGlossaryReferences entries
          if not (null refErrs)
            then pure (Left (unlines refErrs), False)
            else do
              let expected = generateGlossaryHaskellSource entries
              hsExists <- doesFileExist hsPath
              if hsExists
                then do
                  existing <- TIO.readFile hsPath
                  if existing == expected
                    then pure (Right (), False)
                    else
                      if fix
                        then do
                          createDirectoryIfMissing True (takeDirectory hsPath)
                          TIO.writeFile hsPath expected
                          pure (Right (), True)
                        else
                          pure
                            ( Left $
                                "Generated glossary '"
                                  ++ hsPath
                                  ++ "' is out of sync with '"
                                  ++ mdPath
                                  ++ "'. Run 'audit-index --fix' or 'keyword-mod codegen' to update."
                            , False
                            )
                else
                  if fix
                    then do
                      createDirectoryIfMissing True (takeDirectory hsPath)
                      TIO.writeFile hsPath expected
                      pure (Right (), True)
                    else
                      pure
                        ( Left $
                            "Generated glossary '"
                              ++ hsPath
                              ++ "' is missing. Run 'audit-index --fix' or 'keyword-mod codegen' to generate it."
                        , False
                        )
