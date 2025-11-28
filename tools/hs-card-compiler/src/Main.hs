{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Main where

import Control.Monad (forM_)
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
import System.Directory (createDirectoryIfMissing)

import CardCompiler.Parser (RawCard(..), convertCard, ParsedCard(..))
import CardPG.Core.Card (CoreCard(..), ItemCard(..))

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
  forM_ cards $ \rc -> do
    case convertCard rc of
      Left err -> putStrLn $ "Failed to convert card " ++ show (rcName rc) ++ ": " ++ err
      Right card -> do
        let fileName = T.unpack (sanitize (rcName rc)) ++ ".yaml"
        let outputPath = outputDir </> fileName
        BS.writeFile outputPath (encode card)
        putStrLn $ "Wrote " ++ outputPath

sanitize :: Text -> Text
sanitize = T.replace " " "_" . T.toLower
