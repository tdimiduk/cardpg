{-# LANGUAGE OverloadedStrings #-}

module Main where

import System.Environment (getArgs)
import System.Exit (die)

import qualified CardCompiler
import qualified CardCompiler.VttExporter as Vtt

main :: IO ()
main = do
  args <- getArgs
  case args of
    [inputFile, outputDir] -> CardCompiler.run inputFile outputDir Nothing
    [inputFile, outputDir, tag] -> CardCompiler.run inputFile outputDir (Just tag)
    ("export-vtt" : outputFile : inputFiles) -> Vtt.loadAndExport inputFiles outputFile
    _ ->
      die
        "Usage: hs-card-compiler <input.json> <output_dir> [tag] OR hs-card-compiler export-vtt <output.json> <input_yaml>..."
