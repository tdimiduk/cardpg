module Frontend.Game.ActorDetails.Stats
  ( statsWidget
  ) where

import Data.Text (Text)
import Reflex.Dom.Core
import Prelude hiding (filter, id, map, (.))

import Core.State (ActorState (..))
import Core.Util (tshow)
import Frontend.Game.ActorLogic (actorDefense, actorResilience)
import Frontend.Style

statsWidget :: (DomBuilder t m, PostBuild t m) => Dynamic t ActorState -> m ()
statsWidget actorState =
  colWith ["gap-2", "p-2"] $
    rowWith [itemsCenter, "justify-around", "gap-4"] $ do
      derivedStatDisplay "🛡" "Defense" (actorDefense actorState)
      derivedStatDisplay "💖" "Resilience" (actorResilience actorState)

derivedStatDisplay :: (DomBuilder t m, PostBuild t m) => Text -> Text -> Dynamic t Int -> m ()
derivedStatDisplay icon label valDyn =
  rowWith [itemsCenter, "gap-2"] $ do
    elStyle "span" ["text-lg"] $ text icon
    divStyle [textSm, fontBold, "text-blue-300"] $ text $ label <> ":"
    divStyle ["text-lg", fontBold, "text-white"] $ dynText (fmap tshow valDyn)
