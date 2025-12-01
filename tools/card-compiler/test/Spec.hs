module Main where

import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "CardCompiler" $ do
    it "compiles" $ do
      True `shouldBe` True
