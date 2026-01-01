{-# LANGUAGE OverloadedStrings #-}

module Main where

import Reflex.Dom

import CardPG.Core.Hardcoded (fatigueCard)
import Frontend.Card ()
import Frontend.Html

import Frontend.Style (appCss)

main :: IO ()
main = mainWidgetWithHead headWidget bodyWidget

headWidget :: (MonadWidget t m) => m ()
headWidget = do
  el "style" $ text appCss

bodyWidget :: (MonadWidget t m) => m ()
bodyWidget = do
  render fatigueCard
  el "p" $ text "This is a minimal spike to test the build setup."
