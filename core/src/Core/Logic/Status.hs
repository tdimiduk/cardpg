{- HLINT ignore "Redundant id" -}

module Core.Logic.Status
  ( addStatus
  , destroyStatus
  , addConsequence
  , addConsequenceForChallenge
  , destroyConsequence
  , isDefeated
  ) where

import Control.Lens
import Control.Monad.RWS (ask, tell)
import Control.Monad.State (get, modify, put)
import Control.Monad.Trans.Class (lift)
import Data.Generics.Labels ()
import Data.List.NonEmpty (NonEmpty (..), toList)
import Data.Map.Strict qualified as Map
import Data.Text (Text)
import Data.Text qualified as T
import System.Random (RandomGen, uniform, uniformR)

import Core.Card
  ( CardInstance
  , ConsequenceCard (..)
  , CoreCard (..)
  , Identified (..)
  )
import Core.Keyword (keywordToText)
import Core.Logic.Combat (calculateResilience)
import Core.Logic.Deck (createCards)
import Core.Logic.Monad (GameM (..))
import Core.NonEmptyText (getRawText, unsafeNonEmptyText)
import Core.Primitives (CardInstanceId, CardLocation (..))
import Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ActorState (..)
  , CoreCardState (..)
  , GameEvent (..)
  , PlannedAction (..)
  , TableState (..)
  )

addStatus :: (RandomGen g) => Text -> CardLocation -> GameM g ()
addStatus statusType destination = do
  env <- ask
  let maybeTemplate = Map.lookup statusType (env ^. #statusCardTemplates)
  case maybeTemplate of
    Nothing -> return () -- Invalid status type?
    Just template -> do
      cards <- createCards template 1
      case cards of
        [card] -> do
          case destination of
            LocationHand -> modify $ #coreState . #hand %~ (card :)
            LocationDiscard -> modify $ #coreState . #discard %~ (card :)
            LocationDeck -> modify $ #coreState . #deck %~ (card :)
          tell [ActionPlanned (PStandard (ActionStack card []))]
          tell [StatusAdded statusType destination]
        _ -> return ()

destroyStatus :: Text -> Maybe CardInstanceId -> GameM g ()
destroyStatus statusType maybeCardId = do
  let matchFunc c =
        case maybeCardId of
          Just specificId -> specificId == c.id
          Nothing -> getRawText c.content.name == statusType

  let findAndRemove
        :: Lens' CoreCardState [CardInstance CoreCard] -> GameM g (Maybe (CardInstance CoreCard))
      findAndRemove location = do
        currentList <- use (#coreState . location)
        let (before, foundAndAfter) = break matchFunc currentList
        case foundAndAfter of
          (foundCard : xs) -> do
            -- Found one element 'x'
            modify $ #coreState . location .~ (before ++ xs)
            return (Just foundCard)
          [] -> return Nothing

  -- Search order: Hand, Discard, Deck
  removedHand <- findAndRemove #hand
  case removedHand of
    Just _ -> do
      tell [StatusRemoved statusType "hand"]
    Nothing -> do
      removedDiscard <- findAndRemove #discard
      case removedDiscard of
        Just _ -> do
          tell [StatusRemoved statusType "discard"]
        Nothing -> do
          removedDeck <- findAndRemove #deck
          case removedDeck of
            Just _ -> do
              tell [StatusRemoved statusType "deck"]
            Nothing -> return ()

addConsequence :: (RandomGen g) => Maybe Int -> GameM g ()
addConsequence = addConsequenceForChallenge Nothing

addConsequenceForChallenge
  :: (RandomGen g)
  => Maybe ActiveChallenge
  -> Maybe Int
  -> GameM g ()
addConsequenceForChallenge mChallenge maybeSeverity = do
  case mChallenge of
    Just challenge
      | Just pool <- challenge.consequencePool
      , any (\p -> T.toLower (T.strip p) `elem` ["fatigue", "exhaustion"]) (toList pool) -> do
          env <- ask
          cards <- createCards (env ^. #fatigueCardTemplate) 1
          case cards of
            (card : _) -> do
              modify $ #coreState . #discard %~ (card :)
              tell [StatusAdded "Fatigue" LocationDiscard]
            [] -> pure ()
    _ -> do
      finalSeverity <- case maybeSeverity of
        Just s -> return s
        Nothing -> do
          res <- calculateResilience
          tblSt <- use #tableState
          let count = length (tblSt ^. #consequences)
          return $ (count `div` res) + 1

      env <- ask
      let allTemplates = Map.elems (env ^. #consequenceCardTemplates)
      let mPool = mChallenge >>= (.consequencePool)
      let matchingTemplates = case mPool of
            Nothing -> allTemplates
            Just pool ->
              let poolList = toList pool
                  normPool = map (T.toLower . T.strip) poolList
                  matchesCard c =
                    let cName = T.toLower (getRawText c.name)
                        cTags = maybe [] (map (T.toLower . keywordToText) . toList) c.tags
                     in cName `elem` normPool || any (`elem` normPool) cTags
                  poolMatches = filter matchesCard allTemplates
               in if null poolMatches then allTemplates else poolMatches

      let candidates = filter (\c -> c.severity == finalSeverity) matchingTemplates
      let finalCandidates = if null candidates then matchingTemplates else candidates

      let fallbackCard =
            ConsequenceCard
              { name = unsafeNonEmptyText "Injury"
              , tags = Just ("Trauma" :| [])
              , passive = Nothing
              , effects = Nothing
              , severity = finalSeverity
              , notes = Nothing
              , rules = Nothing
              }
      let effectiveCandidates = if null finalCandidates then [fallbackCard] else finalCandidates

      do
        -- Pick random index
        g <- GameM . lift $ get
        let (idx, g') = uniformR (0, length effectiveCandidates - 1) g
        GameM . lift $ put g'
        let template = effectiveCandidates !! idx

        -- Create a new ID
        let (cid, g'') = uniform g'
        GameM . lift $ put g''

        let newConsequence = Identified cid template

        -- Add to TableState list (no registry)
        modify $ #tableState . #consequences %~ (newConsequence :)

        tell [ConsequenceAdded newConsequence]
        return ()

destroyConsequence :: CardInstanceId -> GameM g ()
destroyConsequence cid = do
  -- Remove from TableState
  modify $ #tableState . #consequences %~ filter (\c -> c.id /= cid)
  tell [ConsequenceRemoved (T.pack $ show cid)]

isDefeated :: ActorState -> Bool
isDefeated actor =
  let isSev3 c = c.content.severity >= 3
   in any isSev3 actor.tableState.consequences
