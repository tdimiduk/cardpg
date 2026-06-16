{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.PhaseDisplay
  ( phaseDisplayWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Api.Types (Phase (..))
import Core.Util (tshow)

import Frontend.Game.Class
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button

phaseDisplayWidget
  :: forall t m
   . ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadGame t m
     )
  => m ()
phaseDisplayWidget = do
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
          Planning -> planningControls
          Resolution -> resolutionControls

planningControls
  :: forall t m
   . ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadGame t m
     )
  => m ()
planningControls = do
  readyCountDyn <- askReadyCount
  totalCountDyn <- askTotalCount
  divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
    btnClick <- button (def :: ButtonConfig t){size = SizeSmall} $ text "Start Resolution"
    -- Ready Count
    divS (S.text S.Gray 4) $ do
      text "Ready: "
      dynText $ (\r t -> tshow r <> "/" <> tshow t) <$> readyCountDyn <*> totalCountDyn

    let req = Req.StartResolution <$ btnClick

    _ <- requestGame req
    pure ()

resolutionControls
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, MonadGame t m)
  => m ()
resolutionControls = do
  divS (S.flex <> S.itemsCenter <> S.gap S.S2) $ do
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
