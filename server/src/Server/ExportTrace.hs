{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Server.ExportTrace
  ( Command (..)
  , ExportOptions (..)
  , runCli
  , listSessions
  , exportSession
  , generateTrace
  , getEventCounts
  ) where

import Control.Monad (forM_, unless, when)
import Data.Aeson (Result (..), Value, fromJSON)
import Data.IORef (readIORef)
import Data.Int (Int32)
import Data.List (nub, sortOn)
import Data.List.NonEmpty qualified as NE
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import Data.Maybe (isNothing, mapMaybe)
import Data.Ord (Down (..))
import Data.Pool (withResource)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as T
import Data.Time (defaultTimeLocale, formatTime)
import Data.UUID qualified as UUID
import Database.Beam.Postgres (PgJSONB (..))
import Database.PostgreSQL.Simple qualified as Pg
import Options.Applicative hiding (Failure, Success)
import System.Directory (createDirectoryIfMissing, findExecutable)
import System.FilePath (takeDirectory)
import System.IO (hPutStrLn, stderr)
import System.Process (readProcessWithExitCode)
import Text.Printf (printf)

import Api.Types (LogPayload (..))
import Core.Card (CardInstance, ConsequenceCard (..), CoreCard (..), Identified (..), keywordToText)
import Core.DSL (toText)
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId (..), ChallengeId (..))
import Core.Rules ()
import Core.State
  ( ActionStack (..)
  , ActiveChallenge (..)
  , ActiveDefense (..)
  , ActorState (..)
  , DefenseDetails (..)
  , GameEvent (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  , RevealedEffect (..)
  )
import Core.Stats (ResourceType (..), getStat)
import Server.Config (Config (..), loadConfig)
import Server.DB
  ( Game
  , GameEventRecord
  , initDB
  , initInMemoryDB
  , listGames
  , loadGame
  , loadGameEvents
  , loadGameRecord
  , withGargoyleDB
  )
import Server.DB.Schema (GameEventRecordT (..), GameT (..), SqlSerial (..))
import Server.Types (GameState (..), InMemoryStorage (..), StorageBackend (..))

-- ---------------------------------------------------------------------------
-- CLI Options & Command Types
-- ---------------------------------------------------------------------------

data Command
  = CmdList
  | CmdExport ExportOptions
  deriving (Show, Eq)

data ExportOptions = ExportOptions
  { gameId :: Maybe Text
  , latest :: Bool
  , outputFile :: Maybe FilePath
  , stdoutOnly :: Bool
  }
  deriving (Show, Eq)

exportOptionsParser :: Parser ExportOptions
exportOptionsParser =
  ExportOptions
    <$> optional
      ( strOption
          ( long "game"
              <> short 'g'
              <> metavar "GAME_ID"
              <> help "Specific game session ID to export"
          )
      )
    <*> switch
      ( long "latest"
          <> help "Export the most recent game session (default)"
      )
    <*> optional
      ( strOption
          ( long "output"
              <> short 'o'
              <> metavar "FILE"
              <> help "Output markdown file path (defaults to design/traces/<GAME_ID>.md)"
          )
      )
    <*> switch
      ( long "stdout"
          <> help "Only print trace to stdout, without writing to a file"
      )

commandParser :: Parser Command
commandParser =
  subparser
    ( command
        "list"
        ( info
            (pure CmdList)
            (progDesc "List recorded game sessions")
        )
        <> command
          "export"
          ( info
              (CmdExport <$> exportOptionsParser)
              (progDesc "Export game session to markdown trace")
          )
    )
    <|> (CmdExport <$> exportOptionsParser)

optsInfo :: ParserInfo Command
optsInfo =
  info
    (helper <*> commandParser)
    ( fullDesc
        <> progDesc "Export recorded CardPG play sessions as Markdown gameplay traces"
        <> header "export-trace - Gameplay Trace Exporter & Target Inference Engine"
    )

-- ---------------------------------------------------------------------------
-- Entry Point
-- ---------------------------------------------------------------------------

runCli :: IO ()
runCli = do
  cmd <- execParser optsInfo
  cfg <- loadConfig
  let runWithBackend act
        | cfg.useInMemoryDB = do
            backend <- initInMemoryDB
            act backend
        | cfg.useGargoyle = withGargoyleDB "db" act
        | otherwise = do
            backend <- initDB cfg.dbConfig
            act backend
  runWithBackend $ \backend -> case cmd of
    CmdList -> listSessions backend
    CmdExport opts -> exportSession backend opts

-- ---------------------------------------------------------------------------
-- Session Listing
-- ---------------------------------------------------------------------------

getEventCounts :: StorageBackend -> IO (Map Text Int)
getEventCounts (InMemoryBackend ref) = do
  st <- readIORef ref
  pure $ Map.map length st.events
getEventCounts (PostgresBackend pool) = do
  withResource pool $ \conn -> do
    rows <- Pg.query_ conn "SELECT game_id, COUNT(*) FROM events GROUP BY game_id"
    pure $ Map.fromList rows

listSessions :: StorageBackend -> IO ()
listSessions backend = do
  games <- listGames backend
  counts <- getEventCounts backend
  let sortedGames = sortOn (Down . (.gameStartedAt)) games
  putStrLn $
    printf
      "%-23s %-10s %-17s %-8s %-18s %s"
      ("SESSION ID" :: String)
      ("SCENARIO" :: String)
      ("STARTED" :: String)
      ("ROUNDS" :: String)
      ("COMBATANTS" :: String)
      ("EVENTS" :: String)
  forM_ sortedGames $ \g -> do
    let gId = T.unpack g.gameId
        scenario = T.unpack g.scenarioName
        started = formatTime defaultTimeLocale "%Y-%m-%d %H:%M" g.gameStartedAt
        rNum = show g.currentRound
        PgJSONB names = g.actorNames
        combatants = T.unpack (T.intercalate ", " names)
        evCount = show (Map.findWithDefault 0 g.gameId counts)
    putStrLn $ printf "%-23s %-10s %-17s %-8s %-18s %s" gId scenario started rNum combatants evCount

-- ---------------------------------------------------------------------------
-- Session Export
-- ---------------------------------------------------------------------------

exportSession :: StorageBackend -> ExportOptions -> IO ()
exportSession backend opts = do
  targetGId <- case opts.gameId of
    Just gid -> pure gid
    Nothing -> do
      games <- listGames backend
      counts <- getEventCounts backend
      let gamesWithEvents = filter (\g -> Map.findWithDefault 0 g.gameId counts > 0) games
          sorted = sortOn (Down . (.gameStartedAt)) (if null gamesWithEvents then games else gamesWithEvents)
      case sorted of
        [] -> do
          hPutStrLn stderr "Error: No recorded game sessions found."
          pure ""
        (g : _) -> pure g.gameId

  unless (T.null targetGId) $ do
    mGameRec <- loadGameRecord backend targetGId
    case mGameRec of
      Nothing -> hPutStrLn stderr $ "Error: Game session not found: " ++ T.unpack targetGId
      Just gRec -> do
        mGameState <- loadGame backend targetGId
        events <- loadGameEvents backend targetGId
        let markdown = generateTrace gRec mGameState events
            defaultOutPath = "design/traces/" <> T.unpack targetGId <> ".md"
            mOutPath = case opts.outputFile of
              Just p -> Just p
              Nothing -> if opts.stdoutOnly then Nothing else Just defaultOutPath

        case mOutPath of
          Just outPath -> do
            createDirectoryIfMissing True (takeDirectory outPath)
            T.writeFile outPath markdown
            runPrettier [outPath]
            hPutStrLn stderr $ "Trace exported to: " ++ outPath
            -- Also print to stdout if output was defaulted
            when (isNothing opts.outputFile) $
              T.putStrLn markdown
          Nothing ->
            T.putStrLn markdown

-- | Run prettier --write on given files if available (direct binary or via pre-commit fallback)
runPrettier :: [FilePath] -> IO ()
runPrettier [] = pure ()
runPrettier files = do
  mPrettier <- findExecutable "prettier"
  case mPrettier of
    Just bin -> do
      _ <- readProcessWithExitCode bin ("--write" : files) ""
      pure ()
    Nothing -> do
      mPreCommit <- findExecutable "pre-commit"
      case mPreCommit of
        Just bin -> do
          _ <- readProcessWithExitCode bin (["run", "prettier", "--files"] ++ files) ""
          pure ()
        Nothing -> pure ()

-- ---------------------------------------------------------------------------
-- Internal Event & Round Reconstruction
-- ---------------------------------------------------------------------------

data ParsedEvent = ParsedEvent
  { rawId :: Int32
  , roundNum :: Int32
  , actorId :: Maybe Text
  , event :: InternalEvent
  }

data InternalEvent
  = EvActionRevealed PlannedAction RevealedEffect
  | EvActionPlanned PlannedAction
  | EvPlanCanceled PlannedAction
  | EvCardDefended ActiveChallenge (CardInstance CoreCard)
  | EvDefenseEnded ActiveDefense DefenseDetails
  | EvConsequenceAdded (CardInstance ConsequenceCard)
  | EvCardDrawn (CardInstance CoreCard)
  | EvRoundStarted Int
  | EvLogChallenge ActiveChallenge PlannedAction
  | EvOther Text Value
  deriving (Show)

parseRecord :: GameEventRecord -> ParsedEvent
parseRecord r =
  let PgJSONB val = r.eventData
      mAid = r.actorId
      rNum = r.roundNumber
      eId = case r.eventId of
        SqlSerial i -> i
      evt = case r.eventType of
        "ActionRevealed" -> case fromJSON val of
          Success (ActionRevealed plan effect) -> EvActionRevealed plan effect
          _ -> EvOther r.eventType val
        "ActionPlanned" -> case fromJSON val of
          Success (ActionPlanned plan) -> EvActionPlanned plan
          _ -> EvOther r.eventType val
        "PlanCanceled" -> case fromJSON val of
          Success (PlanCanceled plan) -> EvPlanCanceled plan
          _ -> EvOther r.eventType val
        "CardDefended" -> case fromJSON val of
          Success (CardDefended chal card) -> EvCardDefended chal card
          _ -> EvOther r.eventType val
        "DefenseEnded" -> case fromJSON val of
          Success (DefenseEnded def details) -> EvDefenseEnded def details
          _ -> EvOther r.eventType val
        "ConsequenceAdded" -> case fromJSON val of
          Success (ConsequenceAdded card) -> EvConsequenceAdded card
          _ -> EvOther r.eventType val
        "CardDrawn" -> case fromJSON val of
          Success (CardDrawn card) -> EvCardDrawn card
          _ -> EvOther r.eventType val
        "RoundStarted" -> case fromJSON val of
          Success (RoundStarted n) -> EvRoundStarted n
          _ -> EvOther r.eventType val
        "LogChallenge" -> case fromJSON val of
          Success (LogChallenge chal plan) -> EvLogChallenge chal plan
          _ -> EvOther r.eventType val
        _ -> EvOther r.eventType val
   in ParsedEvent eId rNum mAid evt

data DefenseFlip = DefenseFlip
  { cardName :: Text
  , statColor :: ResourceType
  , statVal :: Int
  , cumulativeVal :: Int
  }

data ChallengeResolution = ChallengeResolution
  { challenge :: ActiveChallenge
  , attackerId :: Maybe Text
  , defenderId :: Maybe Text
  , defenseFlips :: [DefenseFlip]
  , consequences :: [CardInstance ConsequenceCard]
  , endedDetails :: Maybe DefenseDetails
  }

data ActorDeclaration
  = DeclAttack Text [Text] ResourceType Int
  | DeclPass
  | DeclPlanned Text
  | DeclNone

-- ---------------------------------------------------------------------------
-- Markdown Generator & Target Inference Engine
-- ---------------------------------------------------------------------------

generateTrace :: Game -> Maybe GameState -> [GameEventRecord] -> Text
generateTrace gRec mGameState eventRecords =
  let parsedEvents = map parseRecord eventRecords

      -- Build actor name mapping
      actorMapFromState = case mGameState of
        Just gs ->
          Map.fromList
            [ (UUID.toText u, a.name)
            | (ActorId u, a) <- Map.toList gs.actors
            ]
        Nothing -> Map.empty

      PgJSONB rawActorNames = gRec.actorNames

      -- Combatant ordering with ID
      combatants :: [(Text, Text)]
      combatants = case mGameState of
        Just gs ->
          [ (a.name, UUID.toText u)
          | (ActorId u, a) <- Map.toList gs.actors
          ]
        Nothing ->
          let PgJSONB val = gRec.gameState
           in case fromJSON val of
                Success (gs :: GameState) ->
                  [ (a.name, UUID.toText u)
                  | (ActorId u, a) <- Map.toList gs.actors
                  ]
                _ ->
                  let distinctAids = nub (mapMaybe (.actorId) parsedEvents)
                   in zip rawActorNames (distinctAids ++ repeat "")

      actorNameMap :: Map Text Text
      actorNameMap =
        if Map.null actorMapFromState
          then Map.fromList [(aid, name) | (name, aid) <- combatants, not (T.null aid)]
          else actorMapFromState

      lookupActorName :: Maybe Text -> Text
      lookupActorName Nothing = "Unknown"
      lookupActorName (Just aid) = Map.findWithDefault aid aid actorNameMap

      -- Identify rounds
      maxRecordRound = if null parsedEvents then 1 else maximum (map (.roundNum) parsedEvents)
      totalRounds = max (fromIntegral gRec.currentRound) (fromIntegral maxRecordRound)
      rounds = [1 .. totalRounds]

      -- Global map of defense flips by challenge ID
      flipsByChallenge :: Map ChallengeId [(Maybe Text, CardInstance CoreCard)]
      flipsByChallenge =
        Map.fromListWith
          (flip (++))
          [ (chal.id, [(p.actorId, card)])
          | p <- parsedEvents
          , EvCardDefended chal card <- [p.event]
          ]

      -- Global map of DefenseEnded details by challenge ID
      endedByChallenge :: Map ChallengeId DefenseDetails
      endedByChallenge =
        Map.fromList
          [ (c.id, details)
          | p <- parsedEvents
          , EvDefenseEnded (ActiveDefense c _) details <- [p.event]
          ]

      -- Render Header
      headerMd =
        T.unlines
          [ "# Play Trace: " <> gRec.scenarioName <> " (" <> gRec.gameId <> ")"
          , ""
          , "## Context & Combatants"
          , ""
          , "- **Session**: `"
              <> gRec.gameId
              <> "` (Recorded: `"
              <> T.pack (formatTime defaultTimeLocale "%Y-%m-%d %H:%M:%S UTC" gRec.gameStartedAt)
              <> "`)"
          , "- **Combatants**:"
          ]
          <> T.unlines
            [ "  - " <> name <> if T.null aid then "" else " (ID: `" <> aid <> "`)"
            | (name, aid) <- combatants
            ]
          <> T.unlines
            [ ""
            , "---"
            , ""
            , "## Round Sequence"
            ]

      -- Render each round
      roundsMd =
        T.intercalate
          "\n---\n\n"
          (map (renderRound parsedEvents combatants lookupActorName flipsByChallenge endedByChallenge) rounds)
   in headerMd <> "\n" <> roundsMd

renderRound
  :: [ParsedEvent]
  -> [(Text, Text)]
  -> (Maybe Text -> Text)
  -> Map ChallengeId [(Maybe Text, CardInstance CoreCard)]
  -> Map ChallengeId DefenseDetails
  -> Int
  -> Text
renderRound allEvents combatants lookupName flipsByChal endedByChal roundIdx =
  let rNum = fromIntegral roundIdx :: Int32
      roundEvents = filter (\e -> e.roundNum == rNum) allEvents

      -- Step 1: Reconstruct Declarations (Filter Noise)
      declarations =
        [ (name, aid, getActorDeclaration aid roundEvents)
        | (name, aid) <- combatants
        ]

      -- Collect challenges revealed in this round
      roundChallenges =
        [ (p.actorId, chal)
        | p <- roundEvents
        , case p.event of
            EvActionRevealed _ (REChallenge _) -> True
            EvLogChallenge _ _ -> True
            _ -> False
        , let chal = case p.event of
                EvActionRevealed _ (REChallenge c) -> c
                EvLogChallenge c _ -> c
                _ -> error "impossible"
        ]
      -- Deduplicate challenges by ID
      uniqueChallenges = Map.toList $ Map.fromList [(c.id, (mAid, c)) | (mAid, c) <- roundChallenges]

      -- Target Inference for each challenge
      reconstructedChallenges :: [ChallengeResolution]
      reconstructedChallenges =
        [ let rawFlips = Map.findWithDefault [] cid flipsByChal
              mEnded = Map.lookup cid endedByChal
              -- Target inference:
              -- 1) Any actor who emitted CardDefended referencing cid
              defendersFromFlips = mapMaybe fst rawFlips
              inferredDefender = case defendersFromFlips of
                (d : _) -> Just d
                [] ->
                  -- 2) In 1v1 encounter, other combatant
                  if length combatants == 2
                    then case mAttacker of
                      Just att -> case filter (\(_, aid) -> aid /= att) combatants of
                        [(_, otherAid)] -> Just otherAid
                        _ -> Nothing
                      Nothing -> Nothing
                    else Nothing

              -- Compute cumulative flips
              computedFlips = computeCumulativeFlips chal.challengeColor (map snd rawFlips)

              -- Consequences for this defender
              consList = case inferredDefender of
                Just defId ->
                  [ ccard
                  | p <- allEvents
                  , p.roundNum == rNum
                      || (p.roundNum == rNum + 1 && p.rawId <= nextRoundPlanningStart allEvents (rNum + 1))
                  , p.actorId == Just defId
                  , EvConsequenceAdded ccard <- [p.event]
                  ]
                Nothing -> []
           in ChallengeResolution
                { challenge = chal
                , attackerId = mAttacker
                , defenderId = inferredDefender
                , defenseFlips = computedFlips
                , consequences = consList
                , endedDetails = mEnded
                }
        | (cid, (mAttacker, chal)) <- uniqueChallenges
        ]

      -- Render Round Sections
      planStepMd = renderPlanStep declarations
      impactStepMd = renderImpactStep lookupName reconstructedChallenges
      consequencesStepMd = renderConsequencesStep lookupName reconstructedChallenges
      wrapUpStepMd = renderWrapUpStep lookupName roundEvents roundIdx (null roundChallenges)
   in T.unlines
        [ "### Round " <> T.pack (show roundIdx)
        , ""
        , "#### 1. Plan Step"
        , ""
        , T.stripEnd planStepMd
        , ""
        , "#### 2. Resolution: Step 1 - Determine Impact"
        , ""
        , T.stripEnd impactStepMd
        , ""
        , "#### 3. Resolution: Step 2 - Consequences"
        , ""
        , T.stripEnd consequencesStepMd
        , ""
        , "#### 4. Round Wrap-Up"
        , ""
        , T.stripEnd wrapUpStepMd
        ]

-- Helper to find the first planning event of the next round
nextRoundPlanningStart :: [ParsedEvent] -> Int32 -> Int32
nextRoundPlanningStart events nextRound =
  let nextRoundEvts = filter (\e -> e.roundNum == nextRound) events
      planningEvts =
        [ e.rawId
        | e <- nextRoundEvts
        , case e.event of
            EvActionPlanned{} -> True
            EvActionRevealed{} -> True
            _ -> False
        ]
   in case planningEvts of
        (firstPlanId : _) -> firstPlanId
        [] -> maxBound

getActorDeclaration :: Text -> [ParsedEvent] -> ActorDeclaration
getActorDeclaration aid events =
  let actorEvents = filter (\e -> e.actorId == Just aid) events
      -- Prefer ActionRevealed, then LogChallenge, then latest ActionPlanned
      mRevealed = listToMaybeReverse [p | p <- actorEvents, case p.event of EvActionRevealed{} -> True; _ -> False]
      mLogChal = listToMaybeReverse [p | p <- actorEvents, case p.event of EvLogChallenge{} -> True; _ -> False]
      mLastPlanned =
        listToMaybeReverse
          [ p
          | p <- actorEvents
          , case p.event of EvActionPlanned{} -> True; EvPlanCanceled{} -> True; _ -> False
          ]
   in case mRevealed of
        Just p -> case p.event of
          EvActionRevealed plan (REChallenge chal) ->
            let (acName, res) = extractPlanCards plan
             in DeclAttack acName res chal.challengeColor chal.challengeStrength
          EvActionRevealed PPass REPass -> DeclPass
          EvActionRevealed plan _ ->
            let (acName, _) = extractPlanCards plan
             in DeclPlanned acName
          _ -> DeclNone
        Nothing -> case mLogChal of
          Just p -> case p.event of
            EvLogChallenge chal plan ->
              let (acName, res) = extractPlanCards plan
               in DeclAttack acName res chal.challengeColor chal.challengeStrength
            _ -> DeclNone
          Nothing -> case mLastPlanned of
            Just p -> case p.event of
              EvActionPlanned plan -> case plan of
                PPass -> DeclPass
                _ ->
                  let (acName, _) = extractPlanCards plan
                   in DeclPlanned acName
              EvPlanCanceled _ -> DeclNone
              _ -> DeclNone
            Nothing -> DeclNone

extractPlanCards :: PlannedAction -> (Text, [Text])
extractPlanCards = \case
  PStandard (ActionStack ac res) ->
    (getRawText ac.content.name, [getRawText r.content.name | r <- res])
  PNarrative (NarrativeStack cs _) ->
    let cList = NE.toList cs
     in case cList of
          [] -> ("Narrative Action", [])
          (h : rest) -> (getRawText h.content.name, [getRawText r.content.name | r <- rest])
  PPass -> ("Passed", [])
  PExploration _ -> ("Exploration Action", [])

computeCumulativeFlips :: ResourceType -> [CardInstance CoreCard] -> [DefenseFlip]
computeCumulativeFlips col cards =
  let go _ [] = []
      go acc (c : cs) =
        let val = getStat col c.content.stats
            newAcc = acc + val
            flipItem =
              DefenseFlip
                { cardName = getRawText c.content.name
                , statColor = col
                , statVal = val
                , cumulativeVal = newAcc
                }
         in flipItem : go newAcc cs
   in go 0 cards

renderPlanStep :: [(Text, Text, ActorDeclaration)] -> Text
renderPlanStep decls =
  T.unlines $
    concat
      [ case decl of
          DeclAttack acName res col strengthVal ->
            [ "- **" <> name <> "'s Declaration**:"
            , "  - Action Card: `" <> acName <> "`"
            , "  - Resources: "
                <> (if null res then "None" else T.intercalate ", " (map (\r -> "`" <> r <> "`") res))
            , "  - Attack: **" <> T.pack (show col) <> " Strength = " <> T.pack (show strengthVal) <> "**"
            ]
          DeclPass ->
            [ "- **" <> name <> "'s Declaration**:"
            , "  - Passed"
            ]
          DeclPlanned acName ->
            [ "- **" <> name <> "'s Declaration**:"
            , "  - Planned `" <> acName <> "`"
            ]
          DeclNone ->
            [ "- **" <> name <> "'s Declaration**:"
            , "  - None"
            ]
      | (name, _, decl) <- decls
      ]

renderImpactStep :: (Maybe Text -> Text) -> [ChallengeResolution] -> Text
renderImpactStep lookupName chalRess
  | null chalRess = "- No attacks to resolve.\n"
  | all (null . (.defenseFlips)) chalRess = "- Pending resolution.\n"
  | otherwise =
      T.unlines
        [ if null chal.defenseFlips
            then "- Defense against " <> lookupName chal.attackerId <> "'s attack pending resolution."
            else
              let defLabel = case chal.defenderId of
                    Just _ -> "Defender (" <> lookupName chal.defenderId <> ")"
                    Nothing -> "Defender"
                  flipsCount = length chal.defenseFlips
                  impactCount = case chal.endedDetails of
                    Just d -> d.impact
                    Nothing -> flipsCount
                  colorTxt = T.pack (show chal.challenge.challengeColor)
                  strTxt = T.pack (show chal.challenge.challengeStrength)
                  flipsLines =
                    [ "  - Flip "
                        <> T.pack (show idx)
                        <> ": `"
                        <> f.cardName
                        <> "` ({"
                        <> colorTxt
                        <> ": "
                        <> T.pack (show f.statVal)
                        <> "}) -> Cumulative: "
                        <> T.pack (show f.cumulativeVal)
                    | (idx, f) <- zip [1 :: Int ..] chal.defenseFlips
                    ]
               in T.unlines
                    ( ["- " <> defLabel <> " flips cards against **" <> colorTxt <> " " <> strTxt <> "**:"]
                        ++ flipsLines
                        ++ [ "- **Total Flipped Cards**: " <> T.pack (show flipsCount) <> " cards."
                           , "- **Impact Generated**: **" <> T.pack (show impactCount) <> " Impact**."
                           ]
                    )
        | chal <- chalRess
        ]

renderConsequencesStep :: (Maybe Text -> Text) -> [ChallengeResolution] -> Text
renderConsequencesStep lookupName chalRess =
  let allCons = [(chal.defenderId, c) | chal <- chalRess, c <- chal.consequences]
   in if null chalRess || all (\c -> null c.defenseFlips && null c.consequences) chalRess
        then "- Pending resolution.\n"
        else
          if null allCons
            then "- Defender suffered no consequences.\n"
            else
              let groupedByDef =
                    Map.toList $
                      Map.fromListWith
                        (flip (++))
                        [(mDef, [c]) | (mDef, c) <- allCons]
               in T.unlines
                    [ let defLabel = case mDef of
                            Just _ -> "Defender (" <> lookupName mDef <> ")"
                            Nothing -> "Defender"
                          consLines =
                            concatMap renderSingleConsequence cards
                       in T.unlines (("- " <> defLabel <> " suffered:") : consLines)
                    | (mDef, cards) <- groupedByDef
                    ]

renderSingleConsequence :: CardInstance ConsequenceCard -> [Text]
renderSingleConsequence ccard =
  let c = ccard.content
      name = getRawText c.name
      sev = c.severity
      tagsTxt = case c.tags of
        Just ts -> ", Tags: " <> T.intercalate ", " (map keywordToText (NE.toList ts))
        Nothing -> ""
      passiveLine = case c.passive of
        Just p | not (T.null p) -> ["    - _Passive_: " <> p]
        _ -> []
      rulesLine = case c.rules of
        Just rs ->
          let rendered = T.intercalate ", " (map toText (NE.toList rs))
           in ["    - _Rules_: " <> rendered | not (T.null rendered)]
        Nothing -> []
   in ["  - **`" <> name <> "`** (Tier " <> T.pack (show sev) <> tagsTxt <> ")"]
        ++ passiveLine
        ++ rulesLine

renderWrapUpStep :: (Maybe Text -> Text) -> [ParsedEvent] -> Int -> Bool -> Text
renderWrapUpStep lookupName events roundIdx noAttacks =
  let drawnCards =
        [ (p.actorId, getRawText card.content.name)
        | p <- events
        , EvCardDrawn card <- [p.event]
        ]
      groupedDrawn =
        Map.toList $
          Map.fromListWith (flip (++)) [(mAid, [cName]) | (mAid, cName) <- drawnCards]
   in if not (null groupedDrawn)
        then
          T.unlines
            ( ["- Cards drawn:"]
                ++ [ "  - "
                       <> lookupName mAid
                       <> " drew "
                       <> T.pack (show (length cards))
                       <> " cards ("
                       <> T.intercalate ", " (map (\c -> "`" <> c <> "`") cards)
                       <> ")."
                   | (mAid, cards) <- groupedDrawn
                   ]
                ++ ["- Table state updated."]
            )
        else
          if noAttacks && roundIdx > 1
            then "- Round in progress.\n"
            else "- Cards drawn, fatigue cycles, table state updates.\n"

listToMaybeReverse :: [a] -> Maybe a
listToMaybeReverse [] = Nothing
listToMaybeReverse xs = Just (last xs)
