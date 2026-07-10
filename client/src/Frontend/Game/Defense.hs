module Frontend.Game.Defense
  ( DefenseTarget (..)
  , DefenseAction (..)
  , defensePreview
  ) where

import Data.Text (Text)

import Core.Card (CardInstance, CoreCard)
import Core.Logic.Combat (computeDefenseDetails)
import Core.State
  ( ActiveChallenge
  , ActorState
  , DefenseDetails
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

-- | Compute live defense preview from the actor's current state.
--
-- This is computed client-side using shared core logic — no server round-trip
-- needed. The React client had to wait for server-computed defenseDetails;
-- the Reflex client can derive these instantly from the live ActorState.
defensePreview :: ActorState -> DefenseDetails
defensePreview = computeDefenseDetails
