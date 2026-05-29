module Frontend.Game.ActorDetails.Stats
  ( statsWidget
  ) where

import Data.Text (Text)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map)

import Core.Logic.Combat (computeDefense, computeResilience)
import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

statsWidget :: (DomBuilder t m, PostBuild t m) => Dynamic t ActorState -> m ()
statsWidget actorState =
  colWith (S.gap S.S2 . S.p S.S2) $
    rowWith (S.itemsCenter . S.justifyAround . S.gap S.S4) $ do
      derivedStatDisplay "🛡" "Defense" (fmap (\as -> computeDefense as.tableState) actorState)
      derivedStatDisplay "💖" "Resilience" (fmap (\as -> computeResilience as.tableState) actorState)

derivedStatDisplay
  :: (DomBuilder t m, PostBuild t m) => Text -> Text -> Dynamic t Int -> m ()
derivedStatDisplay icon label valDyn =
  rowWith (S.itemsCenter . S.gap S.S2) $ do
    elS "span" S.textLg $ text icon
    divS (S.textSm . S.fontBold . S.text S.Blue 4) $ text $ label <> ":"
    divS (S.textLg . S.fontBold . S.textWhite) $ dynText (fmap tshow valDyn)
