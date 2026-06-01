module Frontend.Util where

import Control.Monad.Fix (MonadFix)
import Data.Map qualified as Map
import Data.Set qualified as Set
import Data.Text (Text)
import Reflex.Dom.Core

import Api.Request

type ApiRequester t m = (ApiRequester' t m, ApiRequester' t (Client m))
type ApiRequester' t m = (Requester t m, Request m ~ ApiRequest, Response m ~ Either Text)

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
