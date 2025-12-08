{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Main where

import CardCompiler.Parser (ParsedCard (..), RawCard (..), convertCard)
import qualified CardCompiler.VttExporter as Vtt
import CardPG.Core.Card (ActorT (..), CoreCard, ItemCard)
import Control.Monad (forM_, unless)
import Data.Aeson (Result (..), Value (..), eitherDecode, fromJSON)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import Data.Either (partitionEithers)
import qualified Data.List.NonEmpty as NE
import qualified Data.Map.Strict as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Yaml (encode)
import System.Directory (createDirectoryIfMissing)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))

main :: IO ()
main = do
  args <- getArgs
  case args of
    [inputFile, outputDir] -> run inputFile outputDir Nothing
    [inputFile, outputDir, tag] -> run inputFile outputDir (Just tag)
    ("export-vtt" : outputFile : inputFiles) -> Vtt.loadAndExport inputFiles outputFile
    _ -> die "Usage: hs-card-compiler <input.json> <output_dir> [tag] OR hs-card-compiler export-vtt <output.json> <input_yaml>..."

run :: FilePath -> FilePath -> Maybe String -> IO ()
run inputFile outputDir tag = do
  content <- LBS.readFile inputFile
  case eitherDecode content of
    Left err -> die $ "Failed to parse JSON: " ++ err
    Right val -> do
      cards <- case val of
        Array _ -> case fromJSON val of
          Success cs -> return cs
          Error e -> die $ "Failed to parse list of cards: " ++ e
        Object _ -> case fromJSON val of
          Success (m :: Map.Map Text [RawCard]) -> return $ concat (Map.elems m)
          Error e -> die $ "Failed to parse map of cards: " ++ e
        _ -> die "Input JSON must be an array of cards or a map of character names to lists of cards"

      createDirectoryIfMissing True outputDir
      processCards outputDir cards tag

processCards :: FilePath -> [RawCard] -> Maybe String -> IO ()
processCards outputDir cards tag = do
  let validCards = filter isValidCard cards
      cardsByActor = Map.fromListWith (++) [(fromMaybe "unknown" (rcActor c), [c]) | c <- validCards]

  forM_ (Map.toList cardsByActor) $ \(actorName, actorCards) -> do
    let results = map convertCard actorCards
        (failures, successes) = partitionEithers results

    -- Filter out "Skipping empty card row" messages to reduce noise
    let meaningfulFailures = filter (/= "Skipping empty card row") failures
    forM_ meaningfulFailures $ \err -> putStrLn $ "Failed to convert card for actor " ++ show actorName ++ ": " ++ err

    unless (null successes) $ do
      let (items, deck) = splitCards successes

      if length deck /= 24
        then putStrLn $ "Warning: Actor " ++ show actorName ++ " has " ++ show (length deck) ++ " cards in deck. Expected 24. Skipping."
        else do
          let actorData =
                Actor
                  { _name = actorName,
                    _tags = fmap (\t -> NE.fromList [T.pack t]) tag,
                    _items = items,
                    _deck = deck,
                    _id = Just (Vtt.slugify actorName)
                  }
          let fileName = T.unpack (sanitize actorName) ++ ".yaml"
          let outputPath = outputDir </> fileName
          BS.writeFile outputPath (encode actorData)
          putStrLn $ "Wrote " ++ outputPath

isValidCard :: RawCard -> Bool
isValidCard c = case rcActor c of
  Nothing -> False
  Just t | T.null (T.strip t) -> False
  _ -> True

splitCards :: [ParsedCard] -> ([ItemCard], [CoreCard])
splitCards = foldr f ([], [])
  where
    f (PItem i) (is, cs) = (i : is, cs)
    f (PCore c) (is, cs) = (is, c : cs)

sanitize :: Text -> Text
sanitize = T.replace " " "_" . T.toLower
