{-# LANGUAGE FlexibleContexts #-}

module CardCompiler.VttExporter where

import Control.Monad (foldM)
import Data.Aeson (ToJSON (..), genericToJSON)
import qualified Data.Aeson as Aeson
import qualified Data.ByteString.Lazy as LBS
import Data.List (mapAccumL)

import qualified Data.Map as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Yaml as Yaml
import GHC.Generics (Generic)
import Optics ((^.))

import CardPG.Core.Card
  ( ActorDefinition
  , ActorDefinitionT (..)
  , ActorMachine
  , ConsequenceCard
  , ConsequenceCardMachine
  , ConsequenceCardT (..)
  , CoreCard
  , CoreCardMachine
  , CoreCardT (..)
  , DSLRule (..)
  , ItemCard
  , ItemCardMachine
  , ItemCardT (..)
  , NatureCardT (..)
  , Rule
  )
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.RichText (RichString, RichText, getRichText)

-- | VTT Export Data
data VttExport = VttExport
  { _actors :: [ActorMachine]
  , _statuses :: [CoreCardMachine]
  , _consequences :: [ConsequenceCardMachine]
  }
  deriving (Show, Generic)

instance ToJSON VttExport where
  toJSON = genericToJSON (cardpgJsonOptions "VttExport")

-- | Load and Export Function
loadAndExport :: [FilePath] -> FilePath -> IO ()
loadAndExport inputFiles outputFile = do
  (actors, statuses, consequences) <- foldM processFile ([], [], []) inputFiles

  let exportData =
        VttExport
          { _actors = actors
          , _statuses = statuses
          , _consequences = consequences
          }

  LBS.writeFile outputFile (Aeson.encode exportData)
  putStrLn $
    "Exported "
      ++ show (length actors)
      ++ " actors, "
      ++ show (length statuses)
      ++ " status cards, and "
      ++ show (length consequences)
      ++ " consequence cards to "
      ++ outputFile
  where
    processFile ::
      ([ActorMachine], [CoreCardMachine], [ConsequenceCardMachine]) ->
      FilePath ->
      IO ([ActorMachine], [CoreCardMachine], [ConsequenceCardMachine])
    processFile (accActors, accStatuses, accConsequences) file = do
      result <- Yaml.decodeFileEither file
      case result of
        Right (actor :: ActorDefinition) -> do
          return (convertActor actor : accActors, accStatuses, accConsequences)
        Left _ -> do
          -- Try parsing as list of CoreCards (Status Library)
          resultCards <- Yaml.decodeFileEither file
          case resultCards of
            Right (cards :: [CoreCard]) -> do
              let vttCards =
                    map
                      (\c -> toVttCoreCard c (fromMaybe (slugify (getRawText (c ^. #name))) (c ^. #id)))
                      cards
              return (accActors, vttCards ++ accStatuses, accConsequences)
            Left _ -> do
              -- Try parsing as list of ConsequenceCards
              resultConsequences <- Yaml.decodeFileEither file
              case resultConsequences of
                Right (consequences :: [ConsequenceCard]) -> do
                  let vttConsequences = map toVttConsequenceCard consequences
                  return (accActors, accStatuses, vttConsequences ++ accConsequences)
                Left err -> do
                  putStrLn $
                    "Warning: Failed to parse " ++ file ++ " as Actor, Card List, or Consequence List: " ++ show err
                  return (accActors, accStatuses, accConsequences)

-- | Convert Actor (Human) to ActorMachine (Machine)
convertActor :: ActorDefinition -> ActorMachine
convertActor ActorDefinition{..} =
  ActorDefinition
    { id = actorId
    , items = map (convertItem actorId) items
    , nature = map (convertNature actorId) nature
    , deck = processDeck actorId deck
    , ..
    }
  where
    actorId = fromMaybe (slugify name) id

convertItem :: Text -> ItemCard -> ItemCardMachine
convertItem actorId ItemCard{..} =
  ItemCard
    { id = fromMaybe (actorId <> "-" <> slugify (getRawText name)) id
    , flavor = fmap getRichText flavor
    , ..
    }

convertNature :: Text -> NatureCardT (Maybe Text) RichString -> NatureCardT Text RichText
convertNature actorId NatureCard{..} =
  NatureCard
    { id = fromMaybe (actorId <> "-" <> slugify (getRawText name)) id
    , flavor = fmap getRichText flavor
    , ..
    }

-- | Process deck to ensure unique IDs for duplicates
processDeck :: Text -> [CoreCard] -> [CoreCardMachine]
processDeck actorId cards =
  let
    -- 1. Calculate frequencies of card slugs (names)
    -- Use lens to disambiguate name
    getCardNameSlug c = slugify (getRawText (c ^. #name))
    cardSlugs = map getCardNameSlug cards
    freqMap = Map.fromListWith (+) $ zip cardSlugs (repeat 1 :: [Int])

    -- 2. Map over cards with state (counter map)
    (_, vttCards) = mapAccumL (assignId actorId freqMap) Map.empty cards
   in
    vttCards

-- | Assign ID based on frequency and current count
assignId ::
  Text -> Map.Map Text Int -> Map.Map Text Int -> CoreCard -> (Map.Map Text Int, CoreCardMachine)
assignId actorId freqMap counters card =
  let cardSlug = slugify (getRawText (card ^. #name))
      count = Map.findWithDefault 0 cardSlug counters
      total = Map.findWithDefault 0 cardSlug freqMap

      -- Determine new ID: {actorId}-{cardSlug} or {actorId}-{cardSlug}_{count}
      baseId = actorId <> "-" <> cardSlug
      finalId =
        if total > 1
          then baseId <> "_" <> T.pack (show count)
          else baseId

      -- Update counter
      newCounters = Map.insert cardSlug (count + 1) counters

      -- Create VttCoreCard
      vttCard = toVttCoreCard card finalId
   in (newCounters, vttCard)

-- | Convert CoreCard to CoreCardMachine with specific ID
toVttCoreCard :: CoreCard -> Text -> CoreCardMachine
toVttCoreCard CoreCard{..} finalId =
  CoreCard
    { id = finalId
    , rules = fmap (fmap convertRule) rules
    , flavor = fmap getRichText flavor
    , ..
    }

convertRule :: DSLRule -> Rule
convertRule (DSLRule r) = fmap getRichText r

-- | Simple slugify
slugify :: Text -> Text
slugify = T.toLower . T.replace " " "-"

toVttConsequenceCard :: ConsequenceCard -> ConsequenceCardMachine
toVttConsequenceCard ConsequenceCard{..} =
  ConsequenceCard
    { id = fromMaybe (slugify (getRawText name)) id
    , rules = fmap (fmap convertRule) rules
    , ..
    }
