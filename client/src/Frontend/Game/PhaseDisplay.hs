{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.PhaseDisplay
  ( phaseDisplayWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Api.Types (ClientRole (..), Phase (..))
import Core.Util (tshow)
import Data.Text (Text)

import Frontend.Game.Class
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button

phaseDisplayWidget
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Maybe (Text, ClientRole))
  -> m ()
phaseDisplayWidget identityDyn = do
  phaseDyn <- askPhase
  divS
    ( S.wFull
        <> S.p S.S4
        <> S.borderB
        <> S.border S.Gray 10
        <> S.bg S.Gray 11
    )
    $ do
      divS (S.flexCol <> S.gap S.S2) $ do
        -- Phase Text
        divS (S.flex <> S.itemsCenter <> S.justifyBetween <> S.wFull) $ do
          divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
            text "Phase:"
            dyn_ $ ffor phaseDyn $ \p -> do
              let colorStyle = case p of
                    Planning -> S.text S.Blue 5
                    Resolution -> S.text S.Red 5
              elS "span" (S.fontBold <> colorStyle) $ text (tshow p)

        -- Phase Controls / Status
        dyn_ $ ffor phaseDyn $ \case
          Planning -> planningControls identityDyn
          Resolution -> resolutionControls identityDyn

planningControls
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Maybe (Text, ClientRole))
  -> m ()
planningControls identityDyn = do
  readyCountDyn <- askReadyCount
  totalCountDyn <- askTotalCount
  divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
    dyn_ $ ffor identityDyn $ \case
      Just (_, RoleGM) -> do
        btnClick <- button (def :: ButtonConfig t){size = SizeSmall} $ text "Start Resolution"
        let req = Req.StartResolution <$ btnClick
        _ <- requestGame req
        pure ()
      _ -> do
        elS "span" (S.textXs <> S.text S.Gray 5 <> S.italic) $ text "Waiting for GM to start resolution..."
    -- Ready Count
    divS (S.text S.Gray 4) $ do
      text "Ready: "
      dynText $ (\r t -> tshow r <> "/" <> tshow t) <$> readyCountDyn <*> totalCountDyn

resolutionControls
  :: forall t m
   . (GameWidget t m)
  => Dynamic t (Maybe (Text, ClientRole))
  -> m ()
resolutionControls identityDyn = do
  divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
    dyn_ $ ffor identityDyn $ \case
      Just (_, RoleGM) -> do
        btnClick <-
          button
            (def :: ButtonConfig t)
              { size = SizeSmall
              , variant = VariantSecondary
              }
            $ text "End Round"
        let req = Req.EndRound <$ btnClick
        _ <- requestGame req
        pure ()
      _ -> do
        elS "span" (S.textXs <> S.text S.Gray 5 <> S.italic) $ text "Waiting for GM to end round..."
