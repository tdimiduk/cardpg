module Frontend.Game.ActorDetails.Stats
  ( statsWidget
  ) where

import Data.Text (Text)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map)

import Core.Logic.Combat (computeDefense, computeResilience)
import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Icons (iconDefense, iconResilience)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

statsWidget :: (DomBuilder t m, PostBuild t m) => Dynamic t ActorState -> m ()
statsWidget actorState =
  colWith (S.gap S.S2 <> S.p S.S2) $
    rowWith (S.itemsCenter <> S.justifyAround <> S.gap S.S4) $ do
      derivedStatDisplay
        (divS (S.w S.S5 <> S.h S.S5 <> S.text S.Gray 4) iconDefense)
        "Defense"
        (fmap (\as -> computeDefense as.tableState) actorState)
      derivedStatDisplay
        (divS (S.w S.S5 <> S.h S.S5 <> textEmerald) iconResilience)
        "Resilience"
        (fmap (\as -> computeResilience as.tableState) actorState)

derivedStatDisplay
  :: (DomBuilder t m, PostBuild t m) => m () -> Text -> Dynamic t Int -> m ()
derivedStatDisplay iconWidget label valDyn =
  rowWith (S.itemsCenter <> S.gap S.S2) $ do
    iconWidget
    divS (S.textSm <> S.fontBold <> S.text S.Blue 4) $ text $ label <> ":"
    divS (S.textLg <> S.fontBold <> S.textWhite) $ dynText (fmap tshow valDyn)
