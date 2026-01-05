{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module CardPG.Core.Render.Rule where

import Data.Maybe (catMaybes)
import Data.Text (Text)

import CardPG.Core.Language
  ( cmdAction
  , cmdAttack
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  )
import CardPG.Core.NonEmptyText (NonEmptyText, getRawText)
import CardPG.Core.Render
import CardPG.Core.Render.Util (renderArrow, renderParens, renderSpace)
import CardPG.Core.RichText (RichText)
import CardPG.Core.RuleDefs
import CardPG.Core.Stats (Difficulty (..), ResourceType (..), StackPower (..))

type RuleRender m =
  ( Render Text m
  , Render ResourceType m
  , Render RichText m
  , Render StackPower m
  , Render Difficulty m
  , Render NonEmptyText m
  )

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render AttackDef m
  where
  render AttackDef{..} = do
    render cmdAttack
    renderSpace
    render resistedBy
    render (": Strength = " :: Text)
    render power
    case effect of
      Nothing -> pure ()
      Just e -> do
        renderArrow
        render e

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render GeneralDef m
  where
  render GeneralDef{..} = do
    render cmdAction
    renderSpace
    render (getRawText name)
    case cost of
      Nothing -> pure ()
      Just c -> do
        renderSpace
        renderParens (render c)
    maybe (pure ()) (\d -> renderSpace >> render d) difficulty
    renderSpace
    renderArrow
    renderSpace
    render effect

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render OngoingDef m
  where
  render OngoingDef{..} = do
    render cmdOngoing
    renderSpace
    renderParens (render life)
    renderSpace
    renderArrow
    renderSpace
    render effect

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render PassiveDef m
  where
  render PassiveDef{..} = do
    render cmdPassive
    renderSpace
    render bonus
    maybe (pure ()) (\c -> renderSpace >> render c) condition

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render TaskDef m
  where
  render TaskDef{..} = do
    render cmdTask
    renderSpace
    render (getRawText name)
    -- Complex logic from Printer:
    -- parts = [checkStr, timeStr, costStr]
    -- inner = T.intercalate "; " (catMaybes parts)
    -- parensContent = if T.null inner then "" else " (" <> inner <> ")"
    -- We need to replicate this structure with `Render`.
    -- This is tricky because `intercalate` implies we have the rendered output.
    -- But we are streaming.
    -- We can just render them sequentially with separators?
    -- Or we need "list intercalate" combinator for Render?

    let parts =
          catMaybes
            [ fmap (\c -> ("Check ", render c)) check
            , fmap (\t -> ("Time ", render t)) time
            , fmap (\c -> ("Cost ", render c)) cost
            ]

    if null parts
      then pure ()
      else do
        renderSpace
        renderParens $ do
          renderParts parts

    renderSpace
    renderArrow
    renderSpace
    render effect
    where
      renderParts [] = pure ()
      renderParts [(label, val)] = do
        render (label :: Text)
        val
      renderParts ((label, val) : rest) = do
        render (label :: Text)
        val
        render ("; " :: Text)
        renderParts rest

instance
  ( Monad m
  , RuleRender m
  ) =>
  Render TriggerDef m
  where
  render TriggerDef{..} = do
    render cmdWhen
    renderSpace
    render trigger
    renderSpace
    renderArrow
    renderSpace
    render effect
