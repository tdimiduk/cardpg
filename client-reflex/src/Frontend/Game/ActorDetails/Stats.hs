module Frontend.Game.ActorDetails.Stats
  ( statsWidget
  ) where

import Data.Text (Text)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map)

import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Game.ActorLogic (actorDefense, actorResilience)
import Frontend.Style.Class (MonadStyle)
import Frontend.Style.Common
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout

statsWidget :: (DomBuilder t m, PostBuild t m, MonadStyle m) => Dynamic t ActorState -> m ()
statsWidget actorState =
  colWith (S.gap2 . S.p2) $
    rowWith (S.itemsCenter . S.justifyAround . S.gap4) $ do
      derivedStatDisplay "🛡" "Defense" (actorDefense actorState)
      derivedStatDisplay "💖" "Resilience" (actorResilience actorState)

derivedStatDisplay
  :: (DomBuilder t m, PostBuild t m, MonadStyle m) => Text -> Text -> Dynamic t Int -> m ()
derivedStatDisplay icon label valDyn =
  rowWith (S.itemsCenter . S.gap2) $ do
    elT "span" S.textLg $ text icon
    divT (S.textSm . S.fontBold . S.textBlue300) $ text $ label <> ":"
    divT (S.textLg . S.fontBold . S.textWhite) $ dynText (fmap tshow valDyn)
