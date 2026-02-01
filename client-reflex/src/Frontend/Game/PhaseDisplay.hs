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
  divStyle
    [ "w-full"
    , "p-4"
    , "border-b"
    , "border-slate-800"
    , "bg-slate-900"
    ]
    $ do
      divStyle
        [ "flex"
        , "flex-col"
        , "gap-2"
        ]
        $ do
          -- Phase Text
          divStyle [flex, itemsCenter, justifyBetween, "w-full"] $ do
            divStyle [flex, itemsCenter, "gap-2"] $ do
              text "Phase:"
              dyn_ $ ffor config.phase $ \p -> do
                let color = case p of
                      Planning -> "text-blue-400"
                      Resolution -> "text-red-400"
                elClass "span" ("font-bold " <> color) $ text (tshow p)

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
  divStyle [flex, itemsCenter, "gap-2"] $ do
    btnClick <- button (def :: ButtonConfig t){size = constDyn SizeSmall} $ text "Start Resolution"
    -- Ready Count
    divStyle ["text-slate-500"] $ do
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
  divStyle [flex, itemsCenter, "gap-2"] $ do
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
