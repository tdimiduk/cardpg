module Frontend.Game.Defense
  ( DefenseTarget (..)
  , DefenseAction (..)
  , resolveAttackStack
  , defensePreview
  ) where

import Data.Text (Text)

import Api.Types (LogEntry (..), LogPayload (..))
import Core.Card (CardInstance, CoreCard)
import Core.Logic.Combat (computeDefenseDetails)
import Core.Primitives (ActorId)
import Core.State
  ( ActiveChallenge
  , ActorState
  , DefenseDetails
  , plannedActionCards
  )

-- | The challenge that is being actively defended against, bundled with
-- the attacker's card stack for display purposes.
data DefenseTarget = DefenseTarget
  { challenge :: ActiveChallenge
  -- ^ The incoming challenge to defend against
  , attackStack :: [CardInstance CoreCard]
  -- ^ Cards from the attacker's planned action (for display only)
  , attackerName :: Text
  -- ^ Display name of the attacking actor
  }

-- | Events emitted by the defense widget.
data DefenseAction
  = -- | Flip the top card of the deck as a defense card
    FlipCard
  | -- | Accept consequences; optional severity override
    TakeConsequence (Maybe Int)
  | -- | Finalize and end the active defense
    EndDefense
  | -- | Close the panel UI without ending the defense
    ClosePanel

-- | Reconstruct the attacker's card stack from a challenge log entry and actor state.
-- Used to populate the visual display of what we're defending against.
--
-- Returns the planned action's cards if the log entry is a LogChallenge.
-- Falls back to empty list for any other log type.
resolveAttackStack
  :: LogEntry
  -- ^ The LogChallenge entry
  -> ActorId
  -- ^ The attacker's actor ID (unused but kept for call-site symmetry)
  -> ActorState
  -- ^ The attacker's actor state (for looking up card instances)
  -> [CardInstance CoreCard]
resolveAttackStack logEntry _attackerId _actorState =
  case logEntry.payload of
    LogChallenge _ plannedAction ->
      -- plannedActionCards is defined in Core.State; it extracts the card instances
      -- from the planned action directly (action card + resources for Standard,
      -- all cards for Narrative, empty for Pass).
      plannedActionCards plannedAction
    _ -> []

-- | Compute live defense preview from the actor's current state.
--
-- This is computed client-side using shared core logic — no server round-trip
-- needed. The React client had to wait for server-computed defenseDetails;
-- the Reflex client can derive these instantly from the live ActorState.
defensePreview :: ActorState -> DefenseDetails
defensePreview = computeDefenseDetails
