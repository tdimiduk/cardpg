module Frontend.Util where

import Control.Monad.Fix (MonadFix)
import Data.Map qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Reflex.Dom.Core

-- | widgetHold that automatically flattens inner events.
widgetHoldE
  :: (Reflex t, Adjustable t m, MonadHold t m)
  => m (Event t a)
  -> Event t (m (Event t a))
  -> m (Event t a)
widgetHoldE initial change = switch . current <$> widgetHold initial change

-- | dyn that automatically flattens inner events.
dynE
  :: (Reflex t, Adjustable t m, NotReady t m, PostBuild t m, MonadHold t m)
  => Dynamic t (m (Event t a))
  -> m (Event t a)
dynE d = dyn d >>= switchHold never

-- | Statefully maps a list of items to stable, monotonic sequence numbers.
-- Preserves the sequence number for items already in the list, and appends
-- new items at the end.
buildStableKeyMap
  :: (Reflex t, MonadHold t m, MonadFix m, Ord ident)
  => (item -> ident)
  -- ^ Identifier extractor
  -> Dynamic t [item]
  -- ^ Dynamic input list
  -> m (Dynamic t (Map.Map ident Int))
buildStableKeyMap getId listDyn = do
  initialList <- sample (current listDyn)
  let initialMap = Map.fromList (zip (map getId initialList) [0 ..])
      initialNext = length initialList

  let updateMap newList (currentMap, nextSeq) =
        let newIds = map getId newList
            retainedMap = Map.restrictKeys currentMap (Set.fromList newIds)
            foldFn (accMap, seqNum) itemId =
              if Map.member itemId accMap
                then (accMap, seqNum)
                else (Map.insert itemId seqNum accMap, seqNum + 1)
            (finalMap, finalNext) = foldl foldFn (retainedMap, nextSeq) newIds
         in (finalMap, finalNext)

  accumState <- foldDyn updateMap (initialMap, initialNext) (updated listDyn)
  return (fst <$> accumState)
