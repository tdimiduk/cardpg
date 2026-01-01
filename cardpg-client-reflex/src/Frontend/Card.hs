{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Frontend.Card
  (
  ) where

import Control.Monad (forM_)
import Data.List.NonEmpty (NonEmpty (..))
import Data.List.NonEmpty qualified as NE
import Data.Text (Text)
import Data.Text qualified as T
import Optics.Core ((^.))

import Reflex.Dom.Core

import CardPG.Core.Card
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.Primitives
  ( Difficulty (..)
  , ResourceType (..)
  , StackPower (..)
  , Stats (..)
  , getStat
  )
import CardPG.Core.RichText (Inline (..), RichText (..), unsafeSimpleString)
import CardPG.Core.RuleDefs

import Frontend.Card.Common (art, inParensLS, tshow)
import Frontend.Html

-- Legacy helper
asCardText :: Text -> RichText
asCardText = unsafeSimpleString

instance (DomBuilder t m) => Render CoreCard m where
  render c = divClass "card" $ do
    divClass "flex" $ do
      divClass "name" $ text $ getRawText c.name
      divClass "expand" blank
      maybe blank (divClass "cost" . text . tshow) (c.cost)
    divClass "flex" $ do
      render c.stats
      art
    divClass "textbox" $ do
      render c.rules
      render c.flavor

instance (DomBuilder t m) => Render (Stats Int) m where
  render s = do
    divClass "numbers" $ do
      let r s' = (\v -> if v > 0 then render (ColorValue (StackPower s' v Nothing)) else blank) $ getStat s' s
      r Red
      r Yellow
      r Blue

-- Rules rendering to match legacy textbox style
instance (DomBuilder t m) => Render Rule m where
  render rule = divClass "action" $ case rule of
    RuleAttack x -> render x
    RuleGeneral x -> render x
    RuleTask x -> render x
    RuleTrigger x -> render x
    RuleOngoing x -> render x
    RuleNarrative x -> render x
    RulePassive x -> render x

instance (DomBuilder t m) => Render AttackDef m where
  render def = do
    -- Simple rendering for now, mimicking standard attack line
    el "p" $ do
      text "Attack "
      render (ColorValue (StackPower def.resistedBy 0 Nothing))
      -- TODO: Render power (source, modifier) nicely
      text $ ": " <> tshow def.power.modifier
      forM_ def.effect $ \eff -> do
        text " "
        render eff

instance (DomBuilder t m) => Render GeneralDef m where
  render def = do
    el "p" $ do
      text $ getRawText def.name
      maybe blank inParensLS (def.cost)
      text ": "
      render def.effect

instance (DomBuilder t m) => Render TaskDef m where
  render def = do
    el "p" $ do
      text $ getRawText def.name
      case (def.check, def.time) of
        (Just c, Just t) -> text " (" >> render c >> render ", " >> render t >> text ")"
        (Just c, Nothing) -> inParensLS c
        (Nothing, Just t) -> inParensLS t
        (Nothing, Nothing) -> blank
      text ": "
      render def.effect

instance (DomBuilder t m) => Render TriggerDef m where
  render def = do
    el "p" $ do
      text $ "When " <> getRawText def.trigger
      text " -> "
      render def.effect

instance (DomBuilder t m) => Render OngoingDef m where
  render def = do
    el "p" $ do
      render def.life
      text ": "
      render def.effect

instance (DomBuilder t m) => Render PassiveDef m where
  render def = do
    el "p" $ do
      text $ "Passive: " <> tshow def.bonus.modifier

-- TODO: Render stack power fully
