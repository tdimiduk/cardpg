{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE ScopedTypeVariables #-}

module CardCompiler.VttExporter where

import Data.Aeson (ToJSON(..), genericToJSON, Value(..), object, (.=))
import qualified Data.Aeson as Aeson
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.ByteString.Lazy as LBS
import GHC.Generics (Generic)
import Data.Maybe (fromMaybe)
import Control.Monad (foldM)
import qualified Data.Yaml as Yaml
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE
import qualified Data.Map as Map
import Data.List (mapAccumL)

import CardPG.Core.Card (CoreCard, ItemCard, Rule, DSLRule(..), Stats(..), Actor, ConsequenceCard, ItemCardMachine, ConsequenceCardMachine, CoreCardMachine, ActorMachine, ItemCardT(..), CoreCardT(..), ActorT(..), ConsequenceCardT(..))
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.RuleDefs (RuleT(..), DSLBase)
import CardPG.Core.NonEmptyText (getNonEmptyText, NonEmptyText)
import CardPG.Core.RichText (unRichString, RichString, RichText)


-- | VTT Export Data
data VttExport = VttExport
  { _actors   :: [ActorMachine]
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

  let exportData = VttExport
        { _actors = actors
        , _statuses = statuses
        , _consequences = consequences
        }

  LBS.writeFile outputFile (Aeson.encode exportData)
  putStrLn $ "Exported " ++ show (length actors) ++ " actors, " 
                         ++ show (length statuses) ++ " status cards, and " 
                         ++ show (length consequences) ++ " consequence cards to " ++ outputFile

  where
    processFile :: ([ActorMachine], [CoreCardMachine], [ConsequenceCardMachine]) -> FilePath -> IO ([ActorMachine], [CoreCardMachine], [ConsequenceCardMachine])
    processFile (accActors, accStatuses, accConsequences) file = do
      result <- Yaml.decodeFileEither file
      case result of
        Right (actor :: Actor) -> do
          return (convertActor actor : accActors, accStatuses, accConsequences)
        Left _ -> do
          -- Try parsing as list of CoreCards (Status Library)
          resultCards <- Yaml.decodeFileEither file
          case resultCards of
            Right (cards :: [CoreCard]) -> do
               let vttCards = map (\c@(CoreCard i n _ _ _ _ _) -> toVttCoreCard c (fromMaybe (slugify (getNonEmptyText n)) i)) cards
               return (accActors, vttCards ++ accStatuses, accConsequences)
            Left _ -> do
               -- Try parsing as list of ConsequenceCards
               resultConsequences <- Yaml.decodeFileEither file
               case resultConsequences of
                 Right (consequences :: [ConsequenceCard]) -> do
                   let vttConsequences = map toVttConsequenceCard consequences
                   return (accActors, accStatuses, vttConsequences ++ accConsequences)
                 Left err -> do
                   putStrLn $ "Warning: Failed to parse " ++ file ++ " as Actor, Card List, or Consequence List: " ++ show err
                   return (accActors, accStatuses, accConsequences)

-- | Convert Actor (Human) to ActorMachine (Machine)
convertActor :: Actor -> ActorMachine
convertActor (Actor i n t items d) = 
  let actorId = maybe (slugify n) id i
  in Actor
  { _name = n
  , _id = Just actorId
  , _tags = t
  , _items = map convertItem items
  , _deck = processDeck actorId d
  }

convertItem :: ItemCard -> ItemCardMachine
convertItem (ItemCard i n t f w v tr p d r) = 
  ItemCard
    { _id = Just $ fromMaybe (slugify (getNonEmptyText n)) i
    , _name = n
    , _tags = t
    , _flavor = fmap unRichString f
    , _weight = w
    , _value = v
    , _traits = tr
    , _passive = p
    , _defense = d
    , _resilience = r
    }

-- | Process deck to ensure unique IDs for duplicates
processDeck :: Text -> [CoreCard] -> [CoreCardMachine]
processDeck actorId cards =
  let
    -- 1. Calculate frequencies of card slugs (names)
    -- Use pattern matching to disambiguate _name
    getNameSlug (CoreCard _ n _ _ _ _ _) = slugify (getNonEmptyText n)
    cardSlugs = map getNameSlug cards
    freqMap = Map.fromListWith (+) $ zip cardSlugs (repeat 1 :: [Int])

    -- 2. Map over cards with state (counter map)
    (_, vttCards) = mapAccumL (assignId actorId freqMap) Map.empty cards
  in
    vttCards

-- | Assign ID based on frequency and current count
assignId :: Text -> Map.Map Text Int -> Map.Map Text Int -> CoreCard -> (Map.Map Text Int, CoreCardMachine)
assignId actorId freqMap counters card@(CoreCard _ n _ _ _ _ _) =
  let
    cardSlug = slugify (getNonEmptyText n)
    count = Map.findWithDefault 0 cardSlug counters
    total = Map.findWithDefault 0 cardSlug freqMap

    -- Determine new ID: {actorId}-{cardSlug} or {actorId}-{cardSlug}_{count}
    baseId = actorId <> "-" <> cardSlug
    finalId = if total > 1
              then baseId <> "_" <> T.pack (show count)
              else baseId

    -- Update counter
    newCounters = Map.insert cardSlug (count + 1) counters
    
    -- Create VttCoreCard
    vttCard = toVttCoreCard card finalId
  in
    (newCounters, vttCard)

-- | Convert CoreCard to CoreCardMachine with specific ID
toVttCoreCard :: CoreCard -> Text -> CoreCardMachine
toVttCoreCard (CoreCard _ n t s c r f) finalId = CoreCard
  { _id = Just finalId
  , _name = n
  , _tags = t
  , _stats = s
  , _cost = c
  , _rules = fmap (fmap convertRule) r
  , _flavor = fmap unRichString f
  }

convertRule :: DSLRule -> Rule
convertRule (DSLRule r) = fmap unRichString r


-- | Simple slugify
slugify :: Text -> Text
slugify = T.toLower . T.replace " " "-"


toVttConsequenceCard :: ConsequenceCard -> ConsequenceCardMachine
toVttConsequenceCard (ConsequenceCard i n t p e s nota r) = 
  ConsequenceCard
  { _id = i
  , _name = n
  , _tags = t
  , _passive = p
  , _effects = e
  , _severity = s
  , _notes = nota
  , _rules = fmap (fmap convertRule) r
  }
