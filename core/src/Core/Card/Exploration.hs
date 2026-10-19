{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Core.Card.Exploration
  ( LocationId (..)
  , TravelId (..)
  , ClockDeckId (..)
  , ClockEventId (..)
  , NodeId (..)
  , ModuleId (..)
  , ExitStatus (..)
  , LocationExit (..)
  , ChallengeDef (..)
  , ActionScope (..)
  , ExplorationAction (..)
  , LocationCard (..)
  , TravelRoute (..)
  , TravelExpedients (..)
  , TravelCard (..)
  , ClockUrgency (..)
  , ClockNarrative (..)
  , SetExitStatus (..)
  , ChallengeModifier (..)
  , ClockEffect (..)
  , ClockEventCard (..)
  , ClockConfig (..)
  , ScenarioActor (..)
  , ModuleManifest (..)
  , ExpeditionTime (..)
  ) where

import Control.Applicative ((<|>))
import Data.Aeson
  ( FromJSON (..)
  , FromJSONKey
  , Object
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
import Data.Aeson.Key (Key)
import Data.Aeson.Types (Parser)
import Data.Foldable (toList)
import Data.List.NonEmpty (NonEmpty (..))
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe)
import Data.String (IsString)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Generics (Generic)

import Core.DSL (parseText)
import Core.Keyword (Keyword)
import Core.NonEmptyText (NonEmptyText)
import Core.RichText (RichText)
import Core.Stats (ResourceType)
import Core.Time (Duration (..), ExpeditionTime (..), TimeUnit (..))

--------------------------------------------------------------------------------
-- Aeson Field Parsing Helpers
--------------------------------------------------------------------------------

-- | Parse the first matching optional key from an object.
--
-- Note: Do NOT chain optional lookups with @o .:? k1 <|> o .:? k2@ in 'Parser',
-- because '.:?' succeeds with @pure Nothing@ when a key is absent, short-circuiting
-- '<|>' without trying subsequent keys. 'altOpt' inspects each key in order and
-- selects the first 'Just' value.
altOpt :: (FromJSON a) => Object -> [Key] -> Parser (Maybe a)
altOpt o keys = do
  results <- mapM (o .:?) keys
  pure $ foldr (<|>) Nothing results

-- | Parse the first matching key with a fallback default.
altDef :: (FromJSON a) => a -> Object -> [Key] -> Parser a
altDef def o keys = fromMaybe def <$> altOpt o keys

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

newtype ModuleId = ModuleId {unModuleId :: Text}
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey, IsString)

--------------------------------------------------------------------------------
-- Challenges & Actions
--------------------------------------------------------------------------------

data ChallengeDef = ChallengeDef
  { color :: ResourceType
  , strength :: Int
  , consequences :: Maybe (NonEmpty Keyword)
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

data ActionScope
  = ScopeSolo
  | ScopeTeamwork
  | ScopeEveryone
  deriving stock (Eq, Show, Generic, Enum, Bounded)

instance ToJSON ActionScope where
  toJSON ScopeSolo = String "Solo"
  toJSON ScopeTeamwork = String "Teamwork"
  toJSON ScopeEveryone = String "Everyone"

instance FromJSON ActionScope where
  parseJSON = withText "ActionScope" $ \case
    t | t `elem` ["Solo", "solo", "ScopeSolo"] -> pure ScopeSolo
    t | t `elem` ["Teamwork", "teamwork", "ScopeTeamwork"] -> pure ScopeTeamwork
    t | t `elem` ["Everyone", "everyone", "ScopeEveryone"] -> pure ScopeEveryone
    other -> fail $ "Unknown ActionScope: " ++ T.unpack other

data ExplorationAction = ExplorationAction
  { name :: NonEmptyText
  , time :: Duration
  , challenge :: Maybe ChallengeDef
  , tags :: Maybe (NonEmpty Text)
  , narrative :: Maybe RichText
  , unblocks :: Maybe LocationId
  , timePerImpact :: Maybe Duration
  , interrupt :: Maybe ClockDeckId
  , scope :: ActionScope
  , enablesAction :: Maybe Text
  , modifiesStrength :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ExplorationAction where
  toJSON act =
    object $
      [ "name" .= act.name
      , "time" .= act.time
      , "scope" .= act.scope
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
        <> maybe [] (\ea -> ["enables_action" .= ea]) act.enablesAction
        <> maybe [] (\ms -> ["modifies_strength" .= ms]) act.modifiesStrength
        <> maybe [] (\n -> ["narrative" .= n]) act.narrative

parseExplorationActionWithDefaultScope :: ActionScope -> Value -> Parser ExplorationAction
parseExplorationActionWithDefaultScope fallbackScope = withObject "ExplorationAction" $ \o -> do
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
  timePerImpact <- altOpt o ["time_per_impact", "timePerImpact"]
  interrupt <- o .:? "interrupt"
  mScope <- o .:? "scope"
  let defaultScope = case tags of
        Just ts | "Teamwork" `elem` ts -> ScopeTeamwork
        _ -> fallbackScope
  let actScope = fromMaybe defaultScope mScope
  enablesAction <- altOpt o ["enables_action", "enablesAction"]
  modifiesStrength <- altOpt o ["modifies_strength", "modifiesStrength"]
  pure $
    ExplorationAction
      name
      time
      challenge
      tags
      narrative
      unblocks
      timePerImpact
      interrupt
      actScope
      enablesAction
      modifiesStrength

instance FromJSON ExplorationAction where
  parseJSON = parseExplorationActionWithDefaultScope ScopeSolo

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
  , viaTravel :: Maybe TravelId
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
        <> maybe [] (\vt -> ["via_travel" .= vt]) exit.viaTravel
        <> maybe [] (\p -> ["passage" .= p]) exit.passage

instance FromJSON LocationExit where
  parseJSON = withObject "LocationExit" $ \o -> do
    to <- o .: "to"
    viaTravel <- altOpt o ["via_travel", "viaTravel"]
    status <- o .:? "status" .!= ExitOpen
    passage <- o .:? "passage"
    pure $ LocationExit to viaTravel status passage

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
    cardType <- altDef "Location" o ["card_type", "type"]
    gc <- altOpt o ["governing_clock", "governingClock"]
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
  { from :: LocationId
  , to :: LocationId
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
    dl <- altOpt o ["distance_leagues", "distanceLeagues"]
    bt <- o .: "base_time" <|> o .: "baseTime"
    tt <- altOpt o ["terrain_tags", "terrainTags"]
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
    cr <- altOpt o ["camp_restriction", "campRestriction"]
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
    cardType <- altDef "Travel" o ["card_type", "type"]
    gc <- altOpt o ["governing_clock", "governingClock"]
    route <- o .: "route"
    tags <- o .:? "tags"
    narrative <- o .: "narrative"
    pacesVal <- o .: "paces"
    pacesList <- case pacesVal of
      Array v -> mapM (parseExplorationActionWithDefaultScope ScopeEveryone) (toList v)
      _ -> fail "paces must be an array"
    paces <- case pacesList of
      (p : ps) -> pure (p :| ps)
      [] -> fail "paces array cannot be empty"
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
    sensoryCue <- altOpt o ["sensory_cue", "sensoryCue"]
    pure $ ClockNarrative summary sensoryCue
  parseJSON v = fail $ "Expected String or Object for ClockNarrative, got " ++ show v

data SetExitStatus = SetExitStatus
  { exit :: LocationId
  , status :: ExitStatus
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON SetExitStatus where
  toJSON (SetExitStatus e s) =
    object
      [ "exit" .= e
      , "status" .= s
      ]

instance FromJSON SetExitStatus where
  parseJSON (Object o) = do
    e <- o .: "exit" <|> o .: "location"
    s <- o .: "status"
    pure $ SetExitStatus e s
  parseJSON (Array v) = case toList v of
    [eVal, sVal] -> do
      e <- parseJSON eVal
      s <- parseJSON sVal
      pure $ SetExitStatus e s
    _ -> fail "SetExitStatus array must have exactly 2 elements [exit, status]"
  parseJSON v = fail $ "Expected Object or Array for SetExitStatus, got " ++ show v

data ChallengeModifier = ChallengeModifier
  { color :: Maybe ResourceType
  , strength :: Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ChallengeModifier where
  toJSON cm =
    object $
      maybe [] (\c -> ["color" .= c]) cm.color
        <> ["strength" .= cm.strength]

instance FromJSON ChallengeModifier where
  parseJSON = withObject "ChallengeModifier" $ \o -> do
    color <- o .:? "color" <|> o .:? "attribute"
    strength <- o .: "strength" <|> o .: "difficulty"
    pure $ ChallengeModifier color strength

data ClockEffect = ClockEffect
  { target :: Text
  , text :: RichText
  , duration :: Maybe Duration
  , hazard :: Maybe ChallengeDef
  , setExitStatus :: Maybe SetExitStatus
  , unguarded :: Maybe Bool
  , challengeModifier :: Maybe ChallengeModifier
  , extinguishesLight :: Bool
  , spawnActors :: Maybe [Text]
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
        <> maybe [] (\es -> ["set_exit_status" .= es]) eff.setExitStatus
        <> maybe [] (\u -> ["unguarded" .= u]) eff.unguarded
        <> maybe [] (\cm -> ["challenge_modifier" .= cm]) eff.challengeModifier
        <> ["extinguishes_light" .= True | eff.extinguishesLight]
        <> maybe [] (\sa -> ["spawn_actors" .= sa]) eff.spawnActors

instance FromJSON ClockEffect where
  parseJSON = withObject "ClockEffect" $ \o -> do
    target <- o .: "target"
    text <- o .: "text"
    duration <- o .:? "duration"
    hazard <- o .:? "hazard"
    setExitStatus <- altOpt o ["set_exit_status", "setExitStatus"]
    unguarded <- o .:? "unguarded"
    challengeModifier <- altOpt o ["challenge_modifier", "challengeModifier"]
    extinguishesLight <- altDef False o ["extinguishes_light", "extinguishesLight"]
    spawnActors <- altOpt o ["spawn_actors", "spawnActors"]
    pure $
      ClockEffect
        target
        text
        duration
        hazard
        setExitStatus
        unguarded
        challengeModifier
        extinguishesLight
        spawnActors

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
    cardType <- altDef "ClockEvent" o ["card_type", "type"]
    cd <- o .: "clock_deck" <|> o .: "clockDeck"
    urg <- o .: "urgency"
    tags <- o .:? "tags"
    narrative <- o .: "narrative"
    effects <- o .: "effects"
    pure $ ClockEventCard cardId name cardType cd urg tags narrative effects

--------------------------------------------------------------------------------
-- Scenario & Module Manifests
--------------------------------------------------------------------------------

data ScenarioActor = ScenarioActor
  { name :: Text
  , file :: FilePath
  , x :: Int
  , y :: Int
  , initialHandSize :: Maybe Int
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ScenarioActor where
  toJSON act =
    object $
      [ "name" .= act.name
      , "file" .= act.file
      , "x" .= act.x
      , "y" .= act.y
      ]
        <> maybe [] (\h -> ["initial_hand_size" .= h]) act.initialHandSize

instance FromJSON ScenarioActor where
  parseJSON = withObject "ScenarioActor" $ \o -> do
    name <- o .: "name"
    file <- o .: "file"
    x <- o .:? "x" .!= 0
    y <- o .:? "y" .!= 0
    initialHandSize <- altOpt o ["initial_hand_size", "initialHandSize"]
    pure $ ScenarioActor name file x y initialHandSize

data ClockConfig = ClockConfig
  { name :: Maybe Text
  , tickInterval :: Duration
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ClockConfig where
  toJSON cfg =
    object $
      maybe [] (\n -> ["name" .= n]) cfg.name
        <> ["tick_interval" .= cfg.tickInterval]

instance FromJSON ClockConfig where
  parseJSON = withObject "ClockConfig" $ \o -> do
    name <- o .:? "name"
    tickInterval <- altDef (Duration 30 Minute) o ["tick_interval", "tickInterval"]
    pure $ ClockConfig name tickInterval

data ModuleManifest = ModuleManifest
  { id :: ModuleId
  , name :: Text
  , startingLocation :: LocationId
  , startingTime :: ExpeditionTime
  , clockConfigs :: Map ClockDeckId ClockConfig
  , startingActors :: [ScenarioActor]
  , locationEncounters :: Map LocationId [ScenarioActor]
  }
  deriving stock (Eq, Show, Generic)

instance ToJSON ModuleManifest where
  toJSON m =
    object
      [ "id" .= m.id
      , "name" .= m.name
      , "starting_location" .= m.startingLocation
      , "starting_time" .= m.startingTime
      , "clock_configs" .= m.clockConfigs
      , "starting_actors" .= m.startingActors
      , "location_encounters" .= m.locationEncounters
      ]

instance FromJSON ModuleManifest where
  parseJSON = withObject "ModuleManifest" $ \o -> do
    idVal <- o .: "id"
    name <- o .: "name"
    startingLocation <- o .: "starting_location" <|> o .: "startingLocation"
    startingTime <- altDef (ExpeditionTime 480) o ["starting_time", "startingTime"]
    clockConfigs <- altDef Map.empty o ["clock_configs", "clockConfigs"]
    startingActors <- altDef [] o ["starting_actors", "startingActors"]
    locationEncounters <- altDef Map.empty o ["location_encounters", "locationEncounters"]
    pure $
      ModuleManifest
        idVal
        name
        startingLocation
        startingTime
        clockConfigs
        startingActors
        locationEncounters
