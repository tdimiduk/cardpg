module Frontend.Game.SidebarRight where

import Control.Monad.Fix (MonadFix)

import Data.Text qualified as T
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Api.Types
  ( LogEntry (..)
  , LogPayload (..)
  )
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActorState)
import Core.Util (tshow)

import Frontend.Html (RenderHtml)
import Frontend.Style hiding (hidden)
import Frontend.Util

-- | Sidebar container (Right)
sidebarRightContainer :: [CssClass]
sidebarRightContainer =
  ["w-80", "bg-slate-900", "border-l", "border-slate-800", flex, flexCol, "h-full", "z-20", shadowXl]

-- | Sidebar header section
sidebarHeader :: [CssClass]
sidebarHeader = ["p-4", "bg-slate-950", "border-b", "border-slate-800", "shrink-0"]

-- | Log Area
logArea :: [CssClass]
logArea = ["flex-1", "overflow-y-auto", "p-4", "space-y-2", "custom-scrollbar"]

-- | Chat Input Area
chatArea :: [CssClass]
chatArea = ["p-3", "bg-slate-950", "border-t", "border-slate-800", "shrink-0", flex, "gap-2"]

sidebarRightWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , RenderHtml m
     , ApiRequester t m
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> Dynamic t [LogEntry]
  -- ^ List of logs (newest first in list)
  -> m ()
sidebarRightWidget activeActor logsDyn = do
  divStyle sidebarRightContainer $ do
    -- Header
    divStyle sidebarHeader $ do
      row $ do
        elStyle "h2" ["text-xs", fontBold, "text-slate-500", uppercase, trackingWider] $ text "Game Log"
        spacer
        -- Count
        elStyle "div" ["text-[10px]", "text-slate-600", "font-mono"] $
          dynText $
            fmap (T.pack . show . length) logsDyn

    -- Logs
    _ <- divStyle logArea $ do
      -- Reverse to show oldest at top, newest at bottom (standard chat log)
      simpleList (fmap reverse logsDyn) renderLogEntry

    divStyle chatArea $ chatInputRequesting activeActor
    pure ()

chatInputRequesting
  :: (DomBuilder t m, PostBuild t m, RenderHtml m, MonadFix m, MonadHold t m, ApiRequester t m)
  => Dynamic t (Maybe (Identified ActorId ActorState)) -> m ()
chatInputRequesting activeActor = do
  rec input <-
        inputElement $
          def
            & initialAttributes
            .~ mconcat
              [ "placeholder" =: "Type a message..."
              , "class" =: classes classList
              ]
            & inputElementConfig_setValue
            .~ ("" <$ success)

      let submit = keypress Enter input
      let send = current (value input) <@ submit

      -- Send Button
      (btn, _) <-
        elStyle' "button" ["bg-indigo-600", "hover:bg-indigo-500", "text-white", "p-1.5", rounded] $
          text ">"

      let clickSend = current (value input) <@ domEvent Click btn

      let msgEvt = leftmost [send, clickSend]
      r <- requesting $ attachWith (\a t -> SendChat ((.id) <$> a) t) (current activeActor) msgEvt
      let (err, success) = fanEither r
  widgetHold_ blank $ text . tshow <$> err
  pure ()
  where
    classList =
      [ "flex-1"
      , "bg-slate-900"
      , "border"
      , "border-slate-700"
      , rounded
      , "px-3"
      , "py-1.5"
      , textXs
      , "text-white"
      , "focus:outline-none"
      , "focus:border-indigo-500"
      ]

renderLogEntry :: (DomBuilder t m, PostBuild t m, RenderHtml m) => Dynamic t LogEntry -> m ()
renderLogEntry logDyn = dyn_ $ ffor logDyn $ \l -> case l.payload of
  LogChat c -> do
    divStyle ["bg-slate-800/50", rounded, "p-2", "animate-fade-in", flex, "gap-2"] $ do
      elStyle
        "div"
        ["w-6", "h-6", "rounded-full", "bg-slate-700", flex, itemsCenter, justifyCenter, "shrink-0"]
        $ text "Bot"
      divStyle ["flex-1"] $ do
        elStyle "div" ["text-[10px]", fontBold, "text-slate-500", "mb-0.5"] $
          text l.sender
        divStyle [textSm, "text-slate-200"] $ text c
  LogInfo c -> do
    let (bg, border) = ("text-slate-500", "border-slate-800")
    divStyle [textXs, bg, "italic", "p-2", "border-b", border] $ text c
  LogError c -> do
    divStyle [textXs, "text-red-500", fontBold, "p-2", "border-b", "border-red-900"] $ text c
  LogChallenge _ _ -> do
    -- Placeholder for Challenge Logs
    divStyle ["bg-red-950/30", "border", "border-red-900/50", rounded, "p-3", "mb-2"] $ do
      divStyle ["text-xs", fontBold, "text-red-300"] $ text "Challenge Action"
      divStyle [textXs, "text-slate-400"] $ text $ "By: " <> l.sender
  LogDefense{} -> do
    -- Placeholder for Defense Logs (if rendered independently)
    divStyle ["bg-blue-950/30", "border", "border-blue-900/50", rounded, "p-3", "mb-2"] $ do
      divStyle ["text-xs", fontBold, "text-blue-300"] $ text "Defense Action"
