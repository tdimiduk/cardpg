{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
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
  renderStrategy AttackDef{..} = do
    render cmdAttack
    renderSpace
    render resistedBy
    render sepColon
    renderSpace
    render kwStr
    renderSpace
    render ("= " :: Text)
    render power
    case effect of
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
  renderStrategy GeneralDef{..} = do
    render cmdAction
    renderSpace
    render name
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
  )
  => RenderStrategy mode OngoingDef m
  where
  renderStrategy OngoingDef{..} = do
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
  )
  => RenderStrategy mode PassiveDef m
  where
  renderStrategy PassiveDef{..} = do
    render cmdPassive
    renderSpace
    render bonus
    maybe (pure ()) (\c -> renderSpace >> render c) condition

instance
  ( Monad m
  , RuleRender m
  )
  => RenderStrategy mode TaskDef m
  where
  renderStrategy TaskDef{..} = do
    render cmdTask
    renderSpace
    render name
    let parts =
          catMaybes
            [ fmap (\c -> (kwCheck, render c)) check
            , fmap (\t -> (kwTime, render t)) time
            , fmap (\c -> (kwCost, render c)) cost
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
  renderStrategy TriggerDef{..} = do
    render cmdWhen
    renderSpace
    render trigger
    renderSpace
    renderArrow
    renderSpace
    render effect
