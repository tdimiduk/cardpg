{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Card.Exploration
  ( LocationId (..)
  , TravelId (..)
  , ClockDeckId (..)
  , ClockEventId (..)
  , NodeId (..)
  , ExitStatus (..)
  , LocationExit (..)
  , ChallengeDef (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , TravelRoute (..)
  , TravelExpedients (..)
  , TravelCard (..)
  , ClockUrgency (..)
  , ClockNarrative (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  ) where

import Control.Applicative ((<|>))
import Data.Aeson
  ( FromJSON (..)
  , FromJSONKey
  , ToJSON (..)
  , ToJSONKey
  , Value (..)
  , object
  , withObject
  , withText
  , (.!=)
  , (.:)
  , (.:?)
  , (.=)
  )
import Data.List.NonEmpty (NonEmpty)
import Data.Maybe (fromMaybe)
import Data.String (IsString)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

import Core.DSL (parseText)
import Core.NonEmptyText (NonEmptyText)
import Core.RichText (RichText)
import Core.Stats (ResourceType)
import Core.Time (Duration)

--------------------------------------------------------------------------------
-- Identifier Newtypes
--------------------------------------------------------------------------------

newtype LocationId = LocationId {unLocationId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

newtype TravelId = TravelId {unTravelId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

newtype ClockDeckId = ClockDeckId {unClockDeckId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

newtype ClockEventId = ClockEventId {unClockEventId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

newtype NodeId = NodeId {unNodeId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

--------------------------------------------------------------------------------
-- Challenges & Actions
--------------------------------------------------------------------------------

data ChallengeDef = ChallengeDef
  { color :: ResourceType
  , strength :: Int
  , consequences :: Maybe (NonEmpty Text)
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ChallengeDef where
  toJSON (ChallengeDef c s mConseq) =
    object $
      [ "color" .= c
      , "strength" .= s
      ]
        <> maybe [] (\cs -> ["consequences" .= cs]) mConseq

instance FromJSON ChallengeDef where
  parseJSON = withObject "ChallengeDef" $ \o -> do
    c <- o .: "color" <|> o .: "attribute"
    s <- o .: "strength" <|> o .: "difficulty"
    mConseq <- o .:? "consequences"
    pure $ ChallengeDef c s mConseq

data ExplorationAction = ExplorationAction
  { name :: NonEmptyText
  , time :: Duration
  , challenge :: Maybe ChallengeDef
  , tags :: Maybe (NonEmpty Text)
  , narrative :: Maybe RichText
  , unblocks :: Maybe LocationId
  , timePerImpact :: Maybe Duration
  , interrupt :: Maybe ClockDeckId
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ExplorationAction where
  toJSON act =
    object $
      [ "name" .= act.name
      , "time" .= act.time
      ]
        <> maybe [] (\t -> ["time_per_impact" .= t]) act.timePerImpact
        <> ( case act.challenge of
               Just (ChallengeDef c s mConseq) ->
                 [ "color" .= c
                 , "strength" .= s
                 ]
                   <> maybe [] (\cs -> ["consequences" .= cs]) mConseq
               Nothing -> []
           )
        <> maybe [] (\ts -> ["tags" .= ts]) act.tags
        <> maybe [] (\u -> ["unblocks" .= u]) act.unblocks
        <> maybe [] (\i -> ["interrupt" .= i]) act.interrupt
        <> maybe [] (\n -> ["narrative" .= n]) act.narrative

instance FromJSON ExplorationAction where
  parseJSON = withObject "ExplorationAction" $ \o -> do
    name <- o .: "name"
    time <- o .: "time"
    nestedChallenge <- o .:? "challenge"
    flatChallenge <- do
      mColor <- o .:? "color" <|> o .:? "attribute"
      mStr <- o .:? "strength" <|> o .:? "difficulty"
      mConseq <- o .:? "consequences"
      case (mColor, mStr) of
        (Just c, Just s) -> pure (Just (ChallengeDef c s mConseq))
        _ -> pure Nothing
    let challenge = nestedChallenge <|> flatChallenge
    tags <- o .:? "tags"
    narrative <- o .:? "narrative"
    unblocks <- o .:? "unblocks"
    timePerImpact <- o .:? "time_per_impact" <|> o .:? "timePerImpact"
    interrupt <- o .:? "interrupt"
    pure $ ExplorationAction name time challenge tags narrative unblocks timePerImpact interrupt

--------------------------------------------------------------------------------
-- Locations & Exits
--------------------------------------------------------------------------------

data ExitStatus = ExitOpen | ExitBlocked
  deriving stock (Eq, Show, Generic, Enum, Bounded)

instance ToJSON ExitStatus where
  toJSON ExitOpen = String "open"
  toJSON ExitBlocked = String "blocked"

instance FromJSON ExitStatus where
  parseJSON = withText "ExitStatus" $ \case
    "open" -> pure ExitOpen
    "blocked" -> pure ExitBlocked
    other -> fail $ "Unknown ExitStatus: " ++ T.unpack other

data LocationExit = LocationExit
  { to :: LocationId
  , status :: ExitStatus
  , passage :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON LocationExit where
  toJSON exit =
    object $
      [ "to" .= exit.to
      , "status" .= exit.status
      ]
        <> maybe [] (\p -> ["passage" .= p]) exit.passage

instance FromJSON LocationExit where
  parseJSON = withObject "LocationExit" $ \o -> do
    to <- o .: "to"
    status <- o .:? "status" .!= ExitOpen
    passage <- o .:? "passage"
    pure $ LocationExit to status passage

data LocationCard = LocationCard
  { id :: LocationId
  , name :: NonEmptyText
  , cardType :: Text
  , governingClock :: Maybe ClockDeckId
  , baseTime :: Duration
  , tags :: Maybe (NonEmpty Text)
  , exits :: Maybe [LocationExit]
  , narrative :: RichText
  , actions :: Maybe [ExplorationAction]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON LocationCard where
  toJSON loc =
    object $
      [ "id" .= loc.id
      , "name" .= loc.name
      , "card_type" .= loc.cardType
      ]
        <> maybe [] (\gc -> ["governing_clock" .= gc]) loc.governingClock
        <> ["base_time" .= loc.baseTime]
        <> maybe [] (\ts -> ["tags" .= ts]) loc.tags
        <> maybe [] (\es -> ["exits" .= es]) loc.exits
        <> ["narrative" .= loc.narrative]
        <> maybe [] (\as -> ["actions" .= as]) loc.actions

instance FromJSON LocationCard where
  parseJSON = withObject "LocationCard" $ \o -> do
    cardId <- o .: "id"
    name <- o .: "name"
    ct <- o .:? "card_type" <|> o .:? "type"
    let cardType = fromMaybe "Location" ct
    gc <- o .:? "governing_clock" <|> o .:? "governingClock"
    bt <- o .: "base_time" <|> o .: "baseTime"
    tags <- o .:? "tags"
    exits <- o .:? "exits"
    narrative <- o .: "narrative"
    actions <- o .:? "actions"
    pure $ LocationCard cardId name cardType gc bt tags exits narrative actions

--------------------------------------------------------------------------------
-- Travel Cards
--------------------------------------------------------------------------------

data TravelRoute = TravelRoute
  { from :: NodeId
  , to :: NodeId
  , distanceLeagues :: Maybe Double
  , baseTime :: Duration
  , terrainTags :: Maybe (NonEmpty Text)
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TravelRoute where
  toJSON r =
    object $
      [ "from" .= r.from
      , "to" .= r.to
      ]
        <> maybe [] (\d -> ["distance_leagues" .= d]) r.distanceLeagues
        <> ["base_time" .= r.baseTime]
        <> maybe [] (\ts -> ["terrain_tags" .= ts]) r.terrainTags

instance FromJSON TravelRoute where
  parseJSON = withObject "TravelRoute" $ \o -> do
    from <- o .: "from"
    to <- o .: "to"
    dl <- o .:? "distance_leagues" <|> o .:? "distanceLeagues"
    bt <- o .: "base_time" <|> o .: "baseTime"
    tt <- o .:? "terrain_tags" <|> o .:? "terrainTags"
    pure $ TravelRoute from to dl bt tt

data TravelExpedients = TravelExpedients
  { campRestriction :: Maybe Text
  , actions :: Maybe [ExplorationAction]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TravelExpedients where
  toJSON expeds =
    object $
      maybe [] (\cr -> ["camp_restriction" .= cr]) expeds.campRestriction
        <> maybe [] (\as -> ["actions" .= as]) expeds.actions

instance FromJSON TravelExpedients where
  parseJSON = withObject "TravelExpedients" $ \o -> do
    cr <- o .:? "camp_restriction" <|> o .:? "campRestriction"
    as <- o .:? "actions"
    pure $ TravelExpedients cr as

data TravelCard = TravelCard
  { id :: TravelId
  , name :: NonEmptyText
  , cardType :: Text
  , governingClock :: Maybe ClockDeckId
  , route :: TravelRoute
  , tags :: Maybe (NonEmpty Text)
  , narrative :: RichText
  , paces :: NonEmpty ExplorationAction
  , expedients :: Maybe TravelExpedients
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON TravelCard where
  toJSON trv =
    object $
      [ "id" .= trv.id
      , "name" .= trv.name
      , "card_type" .= trv.cardType
      ]
        <> maybe [] (\gc -> ["governing_clock" .= gc]) trv.governingClock
        <> ["route" .= trv.route]
        <> maybe [] (\ts -> ["tags" .= ts]) trv.tags
        <> [ "narrative" .= trv.narrative
           , "paces" .= trv.paces
           ]
        <> maybe [] (\ex -> ["expedients" .= ex]) trv.expedients

instance FromJSON TravelCard where
  parseJSON = withObject "TravelCard" $ \o -> do
    cardId <- o .: "id"
    name <- o .: "name"
    ct <- o .:? "card_type" <|> o .:? "type"
    let cardType = fromMaybe "Travel" ct
    gc <- o .:? "governing_clock" <|> o .:? "governingClock"
    route <- o .: "route"
    tags <- o .:? "tags"
    narrative <- o .: "narrative"
    paces <- o .: "paces"
    expedients <- o .:? "expedients"
    pure $ TravelCard cardId name cardType gc route tags narrative paces expedients

--------------------------------------------------------------------------------
-- Clock Event Cards
--------------------------------------------------------------------------------

data ClockUrgency
  = Immediate
  | OngoingModifier
  | TelegraphedPortent
  deriving stock (Eq, Show, Generic, Enum, Bounded)

instance ToJSON ClockUrgency where
  toJSON Immediate = String "Immediate"
  toJSON OngoingModifier = String "OngoingModifier"
  toJSON TelegraphedPortent = String "TelegraphedPortent"

instance FromJSON ClockUrgency where
  parseJSON = withText "ClockUrgency" $ \case
    t | t `elem` ["Immediate", "immediate"] -> pure Immediate
    t | t `elem` ["OngoingModifier", "ongoing_modifier", "ongoingModifier"] -> pure OngoingModifier
    t
      | t `elem` ["TelegraphedPortent", "telegraphed_portent", "telegraphedPortent"] ->
          pure TelegraphedPortent
    other -> fail $ "Unknown ClockUrgency: " ++ T.unpack other

data ClockNarrative = ClockNarrative
  { summary :: RichText
  , sensoryCue :: Maybe RichText
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ClockNarrative where
  toJSON (ClockNarrative s mCue) =
    object $
      ["summary" .= s]
        <> maybe [] (\c -> ["sensory_cue" .= c]) mCue

instance FromJSON ClockNarrative where
  parseJSON (String s) = case parseText s of
    Right rt -> pure $ ClockNarrative rt Nothing
    Left err -> fail $ "ClockNarrative RichText parse failed: " ++ err
  parseJSON (Object o) = do
    summary <- o .: "summary"
    sensoryCue <- o .:? "sensory_cue" <|> o .:? "sensoryCue"
    pure $ ClockNarrative summary sensoryCue
  parseJSON v = fail $ "Expected String or Object for ClockNarrative, got " ++ show v

data ClockEffect = ClockEffect
  { target :: Text
  , text :: RichText
  , duration :: Maybe Duration
  , hazard :: Maybe ChallengeDef
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ClockEffect where
  toJSON eff =
    object $
      [ "target" .= eff.target
      , "text" .= eff.text
      ]
        <> maybe [] (\d -> ["duration" .= d]) eff.duration
        <> maybe [] (\h -> ["hazard" .= h]) eff.hazard

instance FromJSON ClockEffect where
  parseJSON = withObject "ClockEffect" $ \o -> do
    target <- o .: "target"
    text <- o .: "text"
    duration <- o .:? "duration"
    hazard <- o .:? "hazard"
    pure $ ClockEffect target text duration hazard

data ClockEventCard = ClockEventCard
  { id :: ClockEventId
  , name :: NonEmptyText
  , cardType :: Text
  , clockDeck :: ClockDeckId
  , urgency :: ClockUrgency
  , tags :: Maybe (NonEmpty Text)
  , narrative :: ClockNarrative
  , effects :: [ClockEffect]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ClockEventCard where
  toJSON clk =
    object $
      [ "id" .= clk.id
      , "name" .= clk.name
      , "card_type" .= clk.cardType
      , "clock_deck" .= clk.clockDeck
      , "urgency" .= clk.urgency
      ]
        <> maybe [] (\ts -> ["tags" .= ts]) clk.tags
        <> [ "narrative" .= clk.narrative
           , "effects" .= clk.effects
           ]

instance FromJSON ClockEventCard where
  parseJSON = withObject "ClockEventCard" $ \o -> do
    cardId <- o .: "id"
    name <- o .: "name"
    ct <- o .:? "card_type" <|> o .:? "type"
    let cardType = fromMaybe "ClockEvent" ct
    cd <- o .: "clock_deck" <|> o .: "clockDeck"
    urg <- o .: "urgency"
    tags <- o .:? "tags"
    narrative <- o .: "narrative"
    effects <- o .: "effects"
    pure $ ClockEventCard cardId name cardType cd urg tags narrative effects
