{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Frontend.Game.PhaseDisplay
  ( PhaseDisplayConfig (..)
  , phaseDisplayWidget
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core hiding (button)

import Api.Request qualified as Req
import Api.Types (Phase (..))
import Core.Util (tshow)

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
     , ApiRequester t m
     )
  => PhaseDisplayConfig t
  -> m ()
phaseDisplayWidget config = do
  divS
    ( S.wFull
        . S.p 4
        . S.borderB
        . (S.border S.Gray 10)
        . (S.bg S.Gray 11)
    )
    $ do
      divS (S.flexCol . S.gap 2) $ do
        -- Phase Text
        divS (S.flex . S.itemsCenter . S.justifyBetween . S.wFull) $ do
          divS (S.flex . S.itemsCenter . S.gap 2) $ do
            text "Phase:"
            dyn_ $ ffor config.phase $ \p -> do
              let colorStyle = case p of
                    Planning -> (S.text S.Blue 5)
                    Resolution -> (S.text S.Red 5)
              elS "span" (S.fontBold . colorStyle) $ text (tshow p)

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
     , ApiRequester t m
     )
  => PhaseDisplayConfig t
  -> m ()
planningControls config = do
  divS (S.flex . S.itemsCenter . S.gap 2) $ do
    btnClick <- button (def :: ButtonConfig t){size = constDyn SizeSmall} $ text "Start Resolution"
    -- Ready Count
    divS (S.text S.Gray 4) $ do
      text "Ready: "
      dynText $ (\r t -> tshow r <> "/" <> tshow t) <$> config.readyCount <*> config.totalCount

    let req = Req.StartResolution <$ btnClick

    _ <- requesting req
    pure ()

resolutionControls
  :: forall t m
   . (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m, ApiRequester t m)
  => PhaseDisplayConfig t -> m ()
resolutionControls _ = do
  divS (S.flex . S.itemsCenter . S.gap 2) $ do
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
