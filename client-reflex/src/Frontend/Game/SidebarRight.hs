module Frontend.Game.SidebarRight where

import Control.Monad.Fix (MonadFix)

import Data.Map qualified as Map
import Data.Text qualified as T
import Reflex.Dom.Core

import Api.Request (ApiRequest (..))
import Api.Types
  ( LogEntry (..)
  , LogPayload (..)
  , LogSender (..)
  )
import Core.Primitives (ActorId, Identified (..))
import Core.State (ActiveChallenge (..), ActorState)
import Core.Util (tshow)
import Frontend.Game.PhaseDisplay (PhaseDisplayConfig, phaseDisplayWidget)
import Frontend.Render.Common (IconMode (..), renderResourceType)
import Frontend.Style.Common (Style, classNames, divS, elS, testId)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.Util

-- | Sidebar container (Right)
sidebarRightContainer :: Style
sidebarRightContainer = S.flexCol . S.w 80 . S.bgSlate900 . S.borderL . S.borderSlate800 . S.hFull . S.z 20 . S.shadowXl

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader = S.p 4 . S.bgSlate950 . S.borderB . S.borderSlate800 . S.shrink0

-- | Log Area
logArea :: Style
logArea =
  S.flex1
    . S.overflowYAuto
    . S.p 4
    . S.spaceY2
    . S.css "custom-scrollbar" "scrollbar-width" "thin"

-- | Chat Input Area
chatArea :: Style
chatArea = S.p 3 . S.bgSlate950 . S.borderT . S.borderSlate800 . S.shrink0 . S.flex . S.gap 2

sidebarRightWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , ApiRequester t m
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> Dynamic t [LogEntry]
  -- ^ List of logs (newest first in list)
  -> PhaseDisplayConfig t
  -> m ()
sidebarRightWidget activeActor logsDyn phaseConfig = do
  divS sidebarRightContainer $ do
    -- Phase Display
    phaseDisplayWidget phaseConfig

    -- Header
    divS sidebarHeader $ do
      row $ do
        elS "h2" (S.textXs . S.fontBold . S.textSlate500 . S.uppercase . S.trackingWider) $ text "Game Log"
        spacer
        -- Count
        elS
          "div"
          ( S.css "text-[10px]" "font-size" "10px"
              . S.css "text-slate-600" "color" "#475569"
              . S.css "font-mono" "font-family" "monospace"
          )
          $ dynText
          $ fmap (T.pack . show . length) logsDyn

    -- Logs
    let logAreaCls = classNames logArea
    _ <- elAttr "div" ("class" =: logAreaCls <> testId "game-log") $ do
      -- Reverse to show oldest at top, newest at bottom (standard chat log)
      simpleList (fmap reverse logsDyn) renderLogEntry

    divS chatArea $ chatInputRequesting activeActor
    pure ()

chatInputRequesting
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m, ApiRequester t m)
  => Dynamic t (Maybe (Identified ActorId ActorState)) -> m ()
chatInputRequesting activeActor = do
  let classListCls = classNames classList
  rec input <-
        inputElement $
          def
            & initialAttributes
            .~ mconcat
              [ "placeholder" =: "Type a message..."
              , "class" =: classListCls
              , Map.mapKeys (AttributeName Nothing) (testId "chat-input")
              ]
            & inputElementConfig_setValue
            .~ ("" <$ success)

      let submit = keypress Enter input
      let send = current (value input) <@ submit

      -- Send Button
      let btnCls = classNames btnStyle
      (btn, _) <-
        elAttr'
          "button"
          ( "class" =: btnCls
              <> testId "chat-send"
          )
          $ text ">"

      let clickSend = current (value input) <@ domEvent Click btn

      let msgEvt = leftmost [send, clickSend]
      r <- requesting $ attachWith (\a t -> SendChat ((.id) <$> a) t) (current activeActor) msgEvt
      let (err, success) = fanEither r
  widgetHold_ blank $ text . tshow <$> err
  pure ()
  where
    classList =
      S.flex1
        . S.bgSlate900
        . S.border
        . S.borderSlate700
        . S.rounded
        . S.css "px-3" "padding-left" "0.75rem"
        . S.css "px-3" "padding-right" "0.75rem"
        . S.p1_5
        . S.textXs
        . S.textWhite
        . S.css "focus:outline-none" "outline" "none"
        . S.css "focus:border-indigo-500" "border-color" "#6366f1"

    btnStyle = S.bgIndigo600 . S.hover S.bgIndigo500 . S.textWhite . S.p1_5 . S.rounded

renderLogEntry :: (DomBuilder t m, PostBuild t m) => Dynamic t LogEntry -> m ()
renderLogEntry logDyn = dyn_ $ ffor logDyn $ \l -> case l.payload of
  LogChat c -> do
    let chatStyle =
          S.bgSlate800_50
            . S.rounded
            . S.p 2
            . S.css "animate-fade-in" "animation" "fadeIn 0.2s"
            . S.flex
            . S.gap 2
    let chatCls = classNames chatStyle
    elAttr
      "div"
      ( "class" =: chatCls
          <> testId "log-entry-chat"
      )
      $ do
        elS
          "div"
          (S.w 6 . S.h 6 . S.roundedFull . S.bgSlate700 . S.flex . S.itemsCenter . S.justifyCenter . S.shrink0)
          $ text "Bot"
        divS S.flex1 $ do
          elS
            "div"
            ( S.css "text-[10px]" "font-size" "10px"
                . S.fontBold
                . S.textSlate500
                . S.css "mb-0.5" "margin-bottom" "0.125rem"
            )
            $ text (renderSender l.sender)
          let msgCls = classNames (S.textSm . S.textSlate200)
          elAttr "div" ("class" =: msgCls <> testId "log-entry-message") $
            text c
  LogInfo c -> do
    let (bg, border) = (S.textSlate500, S.borderSlate800)
    divS (S.textXs . bg . S.css "italic" "font-style" "italic" . S.p 2 . S.borderB . border) $ text c
  LogError c -> do
    divS (S.textXs . S.textWhite . S.bgRed900_50 . S.fontBold . S.p 2 . S.borderB . S.borderRed800) $
      text c
  LogChallenge challenge _plannedAction -> do
    -- Red-themed container for attack/challenge (matching vtt-react)
    let challengeStyle =
          S.css "bg-red-950/30" "background-color" "rgb(69 10 10 / 0.3)"
            . S.border
            . S.css "border-red-900/50" "border-color" "rgb(127 29 29 / 0.5)"
            . S.rounded
            . S.p 3
            . S.mb 2
            . S.css "animate-fade-in" "animation" "fadeIn 0.2s"
    divS challengeStyle $ do
      -- Header
      divS (S.textXs . S.fontBold . S.textRed300 . S.flex . S.itemsCenter . S.gap 1) $
        text "Challenge Action"
      -- Attacker
      divS (S.textXs . S.textSlate400 . S.mt 1) $
        text $
          "By: " <> renderSender l.sender
      -- Power display with color icon
      divS
        ( S.flex
            . S.itemsCenter
            . S.gap 2
            . S.textSm
            . S.css "bg-black/40" "background-color" "rgb(0 0 0 / 0.4)"
            . S.rounded
            . S.p 1
            . S.mt 2
        )
        $ do
          elS "span" (S.fontBold . S.textRed400) $
            text $
              "Power: " <> tshow challenge.challengeStrength
          renderResourceType IconInline challenge.challengeColor Nothing
  LogDefense{} -> do
    -- Placeholder for Defense Logs (if rendered independently)
    let defenseStyle =
          S.css "bg-blue-950/30" "background-color" "rgb(23 37 84 / 0.3)"
            . S.border
            . S.css "border-blue-900/50" "border-color" "rgb(30 58 138 / 0.5)"
            . S.rounded
            . S.p 3
            . S.mb 2
    divS defenseStyle $ do
      divS (S.textXs . S.fontBold . S.textBlue300) $ text "Defense Action"

renderSender :: LogSender -> T.Text
renderSender SenderSystem = "System"
renderSender SenderGame = "Game"
renderSender SenderGM = "GM"
renderSender SenderEnvironment = "Environment"
renderSender (SenderActor _ name) = name
