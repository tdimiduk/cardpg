{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Monad (forM_, unless)
import Data.Aeson (eitherDecode)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString as BS
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Yaml (encode)
import System.Environment (getArgs)
import System.Exit (die)
import System.FilePath ((</>))
import System.FilePath ((</>))
import System.Directory (createDirectoryIfMissing)
import qualified Data.Map.Strict as Map
import Data.List (sortBy)
import Data.Maybe (fromMaybe)

import Data.Either (partitionEithers)
import CardCompiler.Parser (RawCard(..), convertCard, ParsedCard(..), compareParsedCard, toExportActor, ExportActor(..))
import CardPG.Core.Card (CoreCard(..), ItemCard(..), Actor(..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    [inputFile, outputDir] -> run inputFile outputDir
    _ -> die "Usage: hs-card-compiler <input.json> <output_dir>"

run :: FilePath -> FilePath -> IO ()
run inputFile outputDir = do
  content <- LBS.readFile inputFile
  case eitherDecode content of
    Left err -> die $ "Failed to parse JSON: " ++ err
    Right rawCards -> do
      createDirectoryIfMissing True outputDir
      processCards outputDir rawCards

processCards :: FilePath -> [RawCard] -> IO ()
processCards outputDir cards = do
  let cardsByActor = Map.fromListWith (++) [ (fromMaybe "unknown" (rcActor c), [c]) | c <- cards ]
  
  forM_ (Map.toList cardsByActor) $ \(actor, actorCards) -> do
    let results = map convertCard actorCards
        (failures, successes) = partitionEithers results
    
    forM_ failures $ \err -> putStrLn $ "Failed to convert card for actor " ++ show actor ++ ": " ++ err
    
    unless (null successes) $ do
      let (items, deck) = splitCards successes
          actorData = Actor { _items = items, _deck = deck }
      
      case toExportActor actorData of
        Left err -> die $ "Failed to export actor " ++ show actor ++ ": " ++ err
        Right exportData -> do
          let fileName = T.unpack (sanitize actor) ++ ".yaml"
              outputPath = outputDir </> fileName
          BS.writeFile outputPath (encode exportData)
          putStrLn $ "Wrote " ++ outputPath

splitCards :: [ParsedCard] -> ([ItemCard], [CoreCard])
splitCards = foldr f ([], [])
  where
    f (PItem i) (is, cs) = (i:is, cs)
    f (PCore c) (is, cs) = (is, c:cs)

sanitize :: Text -> Text
sanitize = T.replace " " "_" . T.toLower
