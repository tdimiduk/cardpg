{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Core.Render.Stats where

import Data.Text (Text)

import Core.Render (Render (..))
import Core.Render.Util (renderSpace)
import Core.Stats (ResourceType, StackPower (..), prettyModifier)

instance
  ( Monad m
  , Render Text m
  , Render ResourceType m
  )
  => Render StackPower m
  where
  render (StackPower base 0 Nothing) = render base
  render (StackPower base modifier conditional) = do
    render base
    renderSpace
    render (prettyModifier modifier)
    case conditional of
      Nothing -> pure ()
      Just c -> do
        renderSpace
        render c
