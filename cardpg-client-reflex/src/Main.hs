{-# LANGUAGE OverloadedStrings #-}

module Main where

import Reflex.Dom

import CardPG.Core.Hardcoded (fatigueCard)
import Frontend.Card ()
import Frontend.Html

import Frontend.Style (appCss)

main :: IO ()
main = do
  putStrLn "Starting CardPG Reflex Client..."
  mainWidgetWithHead headWidget bodyWidget

headWidget :: (MonadWidget t m) => m ()
headWidget = do
  el "title" $ text "CardPG Reflex Client"
  elAttr "meta" ("charset" =: "utf-8") blank
  el "style" $ text appCss

bodyWidget :: (MonadWidget t m) => m ()
bodyWidget = do
  render fatigueCard
  el "p" $ text "This is a minimal spike to test the build setup."
