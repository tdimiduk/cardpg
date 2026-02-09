{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.PhaseDisplay
  ( PhaseDisplayConfig (..)
  , phaseDisplayWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)
import Web.Atomic.CSS.Layout (flexCol)

import Api.Request qualified as Req
import Api.Types (Phase (..))
import Core.Util (tshow)

import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button
import Frontend.Util (ApiRequester)

data PhaseDisplayConfig t = PhaseDisplayConfig
  { phase :: Dynamic t Phase
  , readyCount :: Dynamic t Int
  , totalCount :: Dynamic t Int
  }

phaseDisplayWidget
  :: forall t m
   . ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadStyle m
     , ApiRequester t m
     )
  => PhaseDisplayConfig t
  -> m ()
phaseDisplayWidget config = do
  divT
    ( S.wFull
        . S.p4
        . S.borderB
        . S.borderSlate800
        . S.bgSlate900
    )
    $ do
      divT (S.flexCol . S.gap2) $ do
        -- Phase Text
        divT (S.flex . S.itemsCenter . S.justifyBetween . S.wFull) $ do
          divT (S.flex . S.itemsCenter . S.gap2) $ do
            text "Phase:"
            dyn_ $ ffor config.phase $ \p -> do
              let colorStyle = case p of
                    Planning -> S.textBlue400
                    Resolution -> S.textRed400
              elT "span" (S.fontBold . colorStyle) $ text (tshow p)

        -- Phase Controls / Status
        dyn_ $ ffor config.phase $ \case
          Planning -> planningControls config
          Resolution -> resolutionControls config

planningControls
  :: forall t m
   . ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadStyle m
     , ApiRequester t m
     )
  => PhaseDisplayConfig t
  -> m ()
planningControls config = do
  divT (S.flex . S.itemsCenter . S.gap2) $ do
    btnClick <- button (def :: ButtonConfig t){size = constDyn SizeSmall} $ text "Start Resolution"
    -- Ready Count
    divT S.textSlate400 $ do
      text "Ready: "
      dynText $ (\r t -> tshow r <> "/" <> tshow t) <$> config.readyCount <*> config.totalCount

    let req = Req.StartResolution <$ btnClick

    _ <- requesting req
    pure ()

resolutionControls
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, MonadStyle m, ApiRequester t m)
  => PhaseDisplayConfig t -> m ()
resolutionControls _ = do
  divT (S.flex . S.itemsCenter . S.gap2) $ do
    btnClick <-
      button
        (def :: ButtonConfig t)
          { size = constDyn SizeSmall
          , variant = constDyn VariantSecondary
          }
        $ text "End Round"

    let req = Req.EndRound <$ btnClick

    _ <- requesting req
    pure ()
