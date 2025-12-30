{-# LANGUAGE OverloadedStrings #-}

module Main where

import Reflex.Dom

main :: IO ()
main = mainWidget $ do
  el "h1" $ text "Welcome to CardPG Reflex Client"
  el "p" $ text "This is a minimal spike to test the build setup."
