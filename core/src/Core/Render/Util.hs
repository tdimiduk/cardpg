{-# LANGUAGE FlexibleContexts #-}

module Core.Render.Util
  ( renderSpace
  , renderArrow
  , renderParens
  ) where

import Data.Text (Text)

import Core.Language (sepArrow, sepCloseParen, sepOpenParen, sepSpace)
import Core.Render (Render (..))

renderSpace :: (Render Text m) => m ()
renderSpace = render sepSpace

renderArrow :: (Render Text m) => m ()
renderArrow = render sepArrow

renderParens :: (Render Text m) => m () -> m ()
renderParens inner = do
  render sepOpenParen
  inner
  render sepCloseParen
