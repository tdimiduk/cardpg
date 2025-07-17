module Frontend.Card.Consequence where

import qualified Data.Text as T

import Reflex.Dom.Core

import Common.Card

import Frontend.Card.Common

card :: DomBuilder t m => ConsequenceCard -> m ()
card c = divClass "card" $ do
  divClass "flex" $ do
    divClass "name" $ text $ name c
    divClass "expand" blank
    divClass "cost" $ text $ T.pack $ show $ severity c
  art
  divClass "textbox" $ renderCardBlocks $ effect c
