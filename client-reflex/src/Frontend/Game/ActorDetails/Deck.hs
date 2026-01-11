{-# LANGUAGE OverloadedRecordDot #-}

module Frontend.Game.ActorDetails.Deck
  ( deckWidget
  ) where

import Control.Category ((.))
import Reflex.Dom.Core hiding (button)
import Prelude hiding (filter, id, map, (.))

import Api.Request (ApiRequest)
import Api.Request qualified as Req
import Core.Primitives (ActorId)
import Core.State (ActorState (..), CoreCardState (..))
import Core.Util (tshow)
import Frontend.Icons (iconDeck, iconRefresh)
import Frontend.Style
import Frontend.UI.Button

deckWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , Requester t m
     , Request m ~ ApiRequest
     )
  => ActorId
  -> Dynamic t ActorState
  -> m ()
deckWidget actorId actorState = do
  colWith ["gap-2", "p-2", "bg-slate-950", rounded, "text-slate-100"] $ do
    -- Header Row
    rowWith [justifyBetween, itemsCenter, "mb-2"] $ do
      divStyle [flex, itemsCenter, "gap-2", textSm, fontBold, uppercase, "text-slate-400", trackingWider] $ do
        elClass "div" "w-5 h-5" iconDeck
        text "Deck"

      -- Reshuffle Button
      reshuffleClick <-
        button
          def
            { _buttonConfig_variant = constDyn VariantSecondary
            , _buttonConfig_size = constDyn SizeSmall
            }
          $ do
            elClass "div" "w-3 h-3 mr-1" iconRefresh
            text "Reshuffle"

      requesting_ $ Req.ReshuffleDeck actorId <$ reshuffleClick

    let cs = fmap (.coreState) actorState

    -- Cards Row
    rowGap "gap-2" $ do
      let deckBox =
            [ flex1
            , "border"
            , "border-slate-800"
            , "bg-slate-900"
            , rounded
            , "p-3"
            , flex
            , flexCol
            , itemsCenter
            , "gap-2"
            ]
      let labelStyle = ["text-slate-400", textXs]
      let countStyle = ["text-2xl", fontBold, "text-white"]

      -- Draw Pile Box
      divStyle deckBox $ do
        divStyle ([flex, flexRow, itemsCenter, "gap-2"] <> labelStyle) $ text "Draw Pile"
        elStyle "div" countStyle $ dynText $ fmap (tshow . length . (.deck)) cs

        -- Draw Button
        drawClick <-
          button
            def
              { _buttonConfig_variant = constDyn VariantSecondary
              , _buttonConfig_size = constDyn SizeSmall
              , _buttonConfig_fullWidth = True
              }
            $ text "Draw 1"

        requesting_ $ Req.DrawCards actorId <$ drawClick

      -- Discard Box
      divStyle deckBox $ do
        divStyle ([flex, flexRow, itemsCenter, "gap-2"] <> labelStyle) $ text "Discard"
        elStyle "div" countStyle $ dynText $ fmap (tshow . length . (.discard)) cs

        -- Spacer to match height of draw button
        elStyle "div" ["h-[26px]"] blank
