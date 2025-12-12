{-# LANGUAGE FlexibleContexts #-}

module CardCompiler.VttExporter where

import Control.Monad (foldM)
import Data.Aeson (ToJSON (..), genericToJSON)
import Data.Aeson qualified as Aeson
import Data.ByteString.Lazy qualified as LBS
import Data.List (mapAccumL)

import Data.Map qualified as Map
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Yaml qualified as Yaml
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
  { actors :: [ActorMachine]
  , statuses :: [CoreCardMachine]
  , consequences :: [ConsequenceCardMachine]
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
          { actors = actors
          , statuses = statuses
          , consequences = consequences
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
              let vttCards = toVttCoreCard <$> cards
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
    { items = map convertItem items
    , nature = map convertNature nature
    , deck = toVttCoreCard <$> deck
    , ..
    }

convertItem :: ItemCard -> ItemCardMachine
convertItem ItemCard{..} =
  ItemCard
    { flavor = fmap getRichText flavor
    , ..
    }

convertNature :: NatureCardT RichString -> NatureCardT RichText
convertNature NatureCard{..} =
  NatureCard
    { flavor = fmap getRichText flavor
    , ..
    }

-- | Convert CoreCard to CoreCardMachine with specific ID
toVttCoreCard :: CoreCard -> CoreCardMachine
toVttCoreCard CoreCard{..} =
  CoreCard
    { rules = fmap (fmap convertRule) rules
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
    { rules = fmap (fmap convertRule) rules
    , ..
    }
