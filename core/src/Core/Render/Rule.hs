{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Core.Render.Rule where

import Data.Maybe (catMaybes)
import Data.Text (Text)

import Core.Language
  ( cmdAction
  , cmdAttack
  , cmdOngoing
  , cmdPassive
  , cmdTask
  , cmdWhen
  , kwCheck
  , kwCost
  , kwStr
  , kwTime
  , sepColon
  , sepSemi
  )

import Core.NonEmptyText (NonEmptyText)
import Core.Render (Render (..), RenderStrategy (..))
import Core.Render.Util (renderArrow, renderParens, renderSpace)
import Core.RichText (RichText)
import Core.RuleDefs
import Core.Stats (Difficulty (..), ResourceType (..), StackPower (..))

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
  )
  => RenderStrategy mode AttackDef m
  where
  renderStrategy def = do
    render def.resistedBy
    render sepColon
    renderSpace
    render kwStr
    renderSpace
    render ("= " :: Text)
    render def.power
    case def.effect of
      Nothing -> pure ()
      Just e -> do
        renderArrow
        render e

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode GeneralDef m
  where
  renderStrategy def = do
    render cmdAction
    renderSpace
    render def.name
    case def.cost of
      Nothing -> pure ()
      Just c -> do
        renderSpace
        renderParens (render c)
    maybe (pure ()) (\d -> renderSpace >> render d) def.difficulty
    renderSpace
    renderArrow
    renderSpace
    render def.effect

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode OngoingDef m
  where
  renderStrategy def = do
    render cmdOngoing
    renderSpace
    renderParens (render def.life)
    renderSpace
    renderArrow
    renderSpace
    render def.effect

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode PassiveDef m
  where
  renderStrategy def = do
    render cmdPassive
    renderSpace
    render def.bonus
    maybe (pure ()) (\c -> renderSpace >> render c) def.condition

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode TaskDef m
  where
  renderStrategy def = do
    render cmdTask
    renderSpace
    render def.name
    let parts =
          catMaybes
            [ fmap (\c -> (kwCheck, render c)) def.check
            , fmap (\t -> (kwTime, render t)) def.time
            , fmap (\c -> (kwCost, render c)) def.cost
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
    render def.effect
    where
      renderParts :: [(Text, m ())] -> m ()
      renderParts [] = pure ()
      renderParts [(label, val)] = do
        render (label :: Text)
        renderSpace
        val
      renderParts ((label, val) : rest) = do
        render (label :: Text)
        renderSpace
        val
        render sepSemi
        renderSpace
        renderParts rest

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode TriggerDef m
  where
  renderStrategy def = do
    render cmdWhen
    renderSpace
    render def.trigger
    renderSpace
    renderArrow
    renderSpace
    render def.effect
