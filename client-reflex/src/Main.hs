{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Monad (forM_, void)
import Data.Aeson (eitherDecode, encode)
import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as BL
import Data.Map qualified as Map
import Data.Text qualified as T
import Data.Text.Encoding (encodeUtf8)
import Data.UUID (UUID)
import Data.UUID.V4 qualified as UUID
import Data.Yaml qualified as Yaml
import Language.Javascript.JSaddle.WebSockets (jsaddleApp, jsaddleOr)
import Network.Wai.Handler.Warp (run)
import Network.WebSockets (defaultConnectionOptions)
import Reflex.Dom.Core
import System.Environment (getArgs, lookupEnv)
import System.FilePath (takeBaseName)

import Api.Reflex (ReflexServerMessage (..))
import Api.Types qualified as Api
import Core.Card (ActorDefinition (..), CardInstance, CoreCard)
import Core.State
  ( ActionStack (..)
  , ActorState (..)
  , CoreCardState (..)
  , NarrativeStack (..)
  , PlannedAction (..)
  )
import Core.Util (tshow)

import Frontend.Card ()
import Frontend.Catalog (catalogWidget)
import Frontend.Html (Render (..))

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--static"] -> do
      putStrLn "Generating static catalog.html..."
      (_, body) <- renderStatic catalogWidget
      let html =
            "<!DOCTYPE html><html><head><meta charset='utf-8'><title>CardPG Catalog</title><link rel='stylesheet' href='cardpg-client-reflex/static/output.css'></head><body>"
              <> BL.fromStrict body
              <> "</body></html>"
      BL.writeFile "catalog.html" html
      BL.writeFile "catalog.html" html
      putStrLn "Done."
    ["--deck", deckPath] -> do
      putStrLn $ "Generating deck for " <> deckPath
      -- Read the YAML file
      yamlContent <- BS.readFile deckPath
      case Yaml.decodeEither' yamlContent of
        Left err -> putStrLn $ "Error decoding YAML: " <> show err
        Right (actorDef :: ActorDefinition) -> do
          let baseName = takeBaseName deckPath
              outName = baseName <> ".html"
          putStrLn $ "Rendering to " <> outName

          (_, body) <- renderStatic (deckWidget actorDef)
          let html =
                "<!DOCTYPE html><html><head><meta charset='utf-8'><title>"
                  <> BL.fromStrict (encodeUtf8 $ actorDef.name)
                  <> "</title><link rel='stylesheet' href='cardpg-client-reflex/static/output.css'></head><body>"
                  <> BL.fromStrict body
                  <> "</body></html>"
          BL.writeFile outName html
          putStrLn "Done."
    _ -> do
      putStrLn "Starting CardPG Reflex Client..."
      clientId <- UUID.nextRandom
      port <- maybe 3003 read <$> lookupEnv "JSADDLE_WARP_PORT"
      putStrLn $ "Running jsaddle-warp server on port " <> show port

      -- Build the jsaddle application with websocket support
      jsaddleApplication <-
        jsaddleOr
          defaultConnectionOptions
          (mainWidgetWithHead headWidget (appWidget clientId))
          jsaddleApp

      run port jsaddleApplication

headWidget :: (DomBuilder t m) => m ()
headWidget = do
  el "title" $ text "CardPG Reflex Client"
  elAttr "meta" ("charset" =: "utf-8") blank
  elAttr "link" ("rel" =: "stylesheet" <> "href" =: "/output.css") blank

bodyWidget :: (MonadWidget t m) => UUID -> m ()
bodyWidget clientId = do
  clickEvt <- button "Toggle Catalog Mode"
  isCatalog <- toggle False clickEvt
  el "hr" blank
  dyn_ $ ffor isCatalog $ \case
    True -> catalogWidget
    False -> appWidget clientId

appWidget :: (MonadWidget t m) => UUID -> m ()
appWidget clientId = do
  let
    wsUrl = "ws://localhost:3004/api?clientId=" <> T.pack (show clientId) <> "&name=ReflexReflex"

  rec let
        -- Send Join message immediately on open using Api types for compatibility with input parser
        joinMsg = Api.Join "ReflexReflex" Nothing
        sendEvt = fmap (const [BL.toStrict $ encode joinMsg]) (_webSocket_open ws)

        wsConfig = def{_webSocketConfig_send = sendEvt}

      ws <- webSocket wsUrl wsConfig

      let serverMsgEvt = fmap (eitherDecode . BL.fromStrict) (_webSocket_recv ws)

      let
        updateActors (Right (ReflexWelcome _ a)) _ = a
        updateActors (Right (ReflexUpdate a)) _ = a
        updateActors _ old = old

      actorsMapDyn <- foldDyn updateActors Map.empty serverMsgEvt

      -- Actor Selection State
      rec selectedActorId <- holdDyn Nothing (fmap Just selectEvt)

          -- Layout: Sidebar + Main Content
          selectEvt <- divClass "flex flex-row h-screen bg-slate-950 text-slate-100 overflow-hidden" $ do
            -- Sidebar (Left)
            selectEvt' <- divClass "w-72 bg-slate-950 border-r border-slate-800 flex flex-col h-full z-20 shadow-xl" $ do
              -- Sidebar Header (Static for now)
              divClass "p-6 border-b border-slate-800" $ do
                elClass "h1" "text-xl font-bold text-slate-100" $ text "CardPG"

              -- Actor List or Active Actor Details
              dyn_ $ ffor selectedActorId $ \case
                Nothing -> divClass "p-4 text-center text-slate-500 italic text-sm" $ text "Select an actor"
                Just aid -> do
                  -- Active Actor Header (Mini)
                  divClass "p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-3" $ do
                    divClass
                      "w-10 h-10 rounded-full border-2 border-slate-600 bg-slate-800 flex items-center justify-center shrink-0"
                      $ text "A" -- Placeholder Avatar
                    divClass "flex-1 overflow-hidden" $ do
                      -- We need to look up the name from the map, but for now just show ID
                      elClass "div" "font-bold text-slate-100 truncate" $ text $ tshow aid
                      elClass "div" "text-xs text-slate-500 uppercase" $ text "Player"

              -- Actor List (Always visible in this simple version, or switchable)
              divClass "flex-1 overflow-y-auto p-4 space-y-2" $ do
                selectClick <- listWithKey actorsMapDyn $ \aid actorDyn -> do
                  (e, _) <- elClass'
                    "button"
                    "w-full text-left px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded transition-colors group"
                    $ do
                      dyn_ $ ffor actorDyn $ \actor -> do
                        text $ actor.name
                  return (aid <$ domEvent Click e)

                -- Aggregate clicks
                return $ switchDyn $ fmap (leftmost . Map.elems) selectClick

            -- Main Content Area (Right)
            divClass "flex-1 relative bg-slate-900 overflow-hidden flex flex-col" $ do
              -- Top Bar / Game Board Area (Placeholder)
              divClass "flex-1 flex items-center justify-center text-slate-700" $
                text "Game Board Area"

              -- Player Hand Area (Bottom Overlay)
              dyn_ $ ffor selectedActorId $ \case
                Nothing -> blank
                Just aid -> do
                  let actorDyn = fmap (Map.lookup aid) actorsMapDyn
                  handWidget actorDyn

            return selectEvt'

  return ()

handWidget :: (MonadWidget t m) => Dynamic t (Maybe ActorState) -> m ()
handWidget actorDyn = do
  divClass "absolute bottom-0 left-0 right-0 flex justify-center items-end pb-4 pointer-events-none" $ do
    divClass "pointer-events-auto flex items-end justify-center px-8 gap-12" $ do
      -- Planned Action Section (Left)
      dyn_ $ ffor actorDyn $ \case
        Just actor -> maybe blank plannedActionWidget actor.coreState.planned
        Nothing -> blank

      -- Hand Section (Right)
      let handDyn = ffor actorDyn $ \case
            Just actor -> actor.coreState.hand
            Nothing -> []

      -- We need to check if there is a planned action to know if we should dim the hand
      -- But for now, we'll just render the hand as is.

      divClass "flex items-end transition-opacity duration-300 min-h-[260px]" $ do
        void $ simpleList handDyn $ \cardDyn -> do
          divClass "pointer-events-auto relative group w-[160px]" $ do
            divClass
              "transition-transform duration-200 ease-out origin-bottom hover:-translate-y-8 hover:z-50 cursor-pointer"
              $ do
                dyn_ $ ffor cardDyn render

plannedActionWidget :: (MonadWidget t m) => PlannedAction -> m ()
plannedActionWidget planned = case planned of
  PStandard (ActionStack action res) -> do
    divClass "flex flex-col items-center gap-2" $ do
      -- Revise Button (Floating above)
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"

      -- Stack
      divClass "relative mt-2 w-[160px] h-[220px]" $ do
        -- Resources (Underneath, shifted left)
        -- We iterate with index to shift them
        forM_ (zip [1 :: Int ..] res) $ \(i, r) -> do
          -- Style for shift: translate(-50px * i) matching React
          -- 50px covers the number strip + padding
          let offset = negate (i * 50)
              styleStr = "transform: translate(" <> tshow offset <> "px, 0px); z-index: " <> tshow (10 - i)
          elAttr "div" ("style" =: styleStr <> "class" =: "absolute top-0 left-0 shadow-xl brightness-75") $
            render r

        -- Action Card (Top)
        divClass "absolute top-0 left-0 z-20 shadow-2xl hover:scale-105 transition-transform" $ do
          render action
          divClass
            "absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-0.5 rounded shadow z-50"
            $ text "PLANNED"
  PNarrative (NarrativeStack cards _color) -> do
    divClass "flex flex-col items-center gap-2" $ do
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"

      divClass "flex -space-x-8" $ do
        mapM_
          (divClass "relative z-10 hover:z-20 transform hover:-translate-y-2 transition-transform" . render)
          cards
  PPass -> do
    divClass "flex flex-col items-center gap-2" $ do
      elClass
        "button"
        "text-red-400 hover:text-red-300 text-[10px] font-bold uppercase flex items-center gap-1 bg-slate-900/80 px-3 py-1 rounded-full border border-slate-700/50 backdrop-blur transition-colors"
        $ do
          text "↺ Revise"
      divClass "text-slate-500 italic text-sm" $ text "Passed turn"

deckWidget :: (DomBuilder t m) => ActorDefinition -> m ()
deckWidget actor = do
  divClass "print-deck-grid" $ do
    mapM_ render actor.nature
    mapM_ render actor.items
    mapM_ render actor.deck
