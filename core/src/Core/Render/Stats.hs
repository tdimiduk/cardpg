{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Core.Render.Stats where

import Data.Default (Default, def)
import Data.Text (Text)

import Core.Language (sepSpace)
import Core.Render (IconMode (..), RenderStrategy (..))
import Core.Stats (ResourceType, StackPower (..), prettyModifier)

instance
  ( Monad m
  , RenderStrategy mode Text m
  , RenderStrategy mode ResourceType m
  , StrategyConfig mode ResourceType ~ IconMode
  , Default (StrategyConfig mode Text)
  )
  => RenderStrategy mode StackPower m
  where
  type StrategyConfig mode StackPower = IconMode
  renderStrategyWith c (StackPower base 0 Nothing) = renderStrategyWith @mode c base
  renderStrategyWith c (StackPower base modifier conditional) = do
    renderStrategyWith @mode c base
    renderStrategyWith @mode def sepSpace
    renderStrategyWith @mode def (prettyModifier modifier) -- prettyModifier returns Text
    case conditional of
      Nothing -> pure ()
      Just a -> do
        renderStrategyWith @mode def sepSpace
        renderStrategyWith @mode def a
