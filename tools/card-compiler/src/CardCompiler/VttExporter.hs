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
  ( ActorDefinitionDSL
  , ActorDefinition
  , ConsequenceCardDSL
  , ConsequenceCard
  , CoreCardDSL
  , CoreCard
  , ItemCardDSL
  , ItemCard
  , NatureCardDSL
  , NatureCard
  , Rule
  )
import CardPG.Core.Conversion (compileActorDefinition, compileConsequenceCard, compileCoreCard)
import CardPG.Core.Json (cardpgJsonOptions)
import CardPG.Core.NonEmptyText (getRawText)
import CardPG.Core.RichText (RichString, RichText, getRichText)

-- | Vtt Export Data
data VttExport = VttExport
  { actors :: [ActorDefinition]
  , statuses :: [CoreCard]
  , consequences :: [ConsequenceCard]
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
      ([ActorDefinition], [CoreCard], [ConsequenceCard]) ->
      FilePath ->
      IO ([ActorDefinition], [CoreCard], [ConsequenceCard])
    processFile (accActors, accStatuses, accConsequences) file = do
      result <- Yaml.decodeFileEither file
      case result of
        Right (actor :: ActorDefinitionDSL) -> do
          return (compileActorDefinition actor : accActors, accStatuses, accConsequences)
        Left _ -> do
          -- Try parsing as list of CoreCards (Status Library)
          resultCards <- Yaml.decodeFileEither file
          case resultCards of
            Right (cards :: [CoreCardDSL]) -> do
              let vttCards = compileCoreCard <$> cards
              return (accActors, vttCards ++ accStatuses, accConsequences)
            Left _ -> do
              -- Try parsing as list of ConsequenceCards
              resultConsequences <- Yaml.decodeFileEither file
              case resultConsequences of
                Right (consequences :: [ConsequenceCardDSL]) -> do
                  let vttConsequences = map compileConsequenceCard consequences
                  return (accActors, accStatuses, vttConsequences ++ accConsequences)
                Left err -> do
                  putStrLn $
                    "Warning: Failed to parse " ++ file ++ " as Actor, Card List, or Consequence List: " ++ show err
                  return (accActors, accStatuses, accConsequences)

-- | Simple slugify
slugify :: Text -> Text
slugify = T.toLower . T.replace " " "-"

