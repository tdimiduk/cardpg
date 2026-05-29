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
import Frontend.Game.Class
import Frontend.Game.PhaseDisplay (PhaseDisplayConfig (..), phaseDisplayWidget)
import Frontend.Render.Common (IconMode (..), renderResourceType)
import Frontend.Style.Common (Style, classNames, divS, elS, testId)
import Frontend.Style.DSL qualified as S
import Frontend.Style.Layout
import Frontend.Util

-- | Sidebar container (Right)
sidebarRightContainer :: Style
sidebarRightContainer =
  S.flexCol
    . S.w (S.Rem 20)
    . S.cls "obsidian-panel"
    . S.borderL
    . S.border S.Gray 10
    . S.hFull
    . S.z 20

-- | Sidebar header section
sidebarHeader :: Style
sidebarHeader =
  S.p S.S4
    . S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    . S.borderB
    . S.border S.Gray 10
    . S.shrink0

-- | Log Area
logArea :: Style
logArea =
  S.flex1
    . S.overflowYAuto
    . S.p S.S4
    . S.spaceY2
    . S.css "custom-scrollbar" "scrollbar-width" "thin"

-- | Chat Input Area
chatArea :: Style
chatArea =
  S.p S.S3
    . S.css "bg-stone-dark" "background-color" "var(--color-stone-dark)"
    . S.borderT
    . S.border S.Gray 10
    . S.shrink0
    . S.flex
    . S.gap S.S2

sidebarRightWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadGame t m
     )
  => Dynamic t (Maybe (Identified ActorId ActorState))
  -> m ()
sidebarRightWidget activeActor = do
  logsDyn <- askLogs
  phaseDyn <- askPhase
  readyDyn <- askReadyCount
  totalDyn <- askTotalCount
  let phaseConfig =
        PhaseDisplayConfig
          { phase = phaseDyn
          , readyCount = readyDyn
          , totalCount = totalDyn
          }
  divS sidebarRightContainer $ do
    -- Phase Display
    phaseDisplayWidget phaseConfig

    -- Header
    divS sidebarHeader $ do
      row $ do
        elS "h2" (S.textXs . S.fontBold . S.text S.Gray 5 . S.uppercase . S.trackingWider) $
          text "Game Log"
        spacer
        -- Count
        elS
          "div"
          ( S.fontSize 10
              . S.text S.Gray 6
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
  :: (DomBuilder t m, PostBuild t m, MonadFix m, MonadHold t m, MonadGame t m)
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
      r <- requestGame $ attachWith (\a t -> SendChat ((.id) <$> a) t) (current activeActor) msgEvt
      let (err, success) = fanEither r
  widgetHold_ blank $ text . tshow <$> err
  pure ()
  where
    classList =
      S.flex1
        . S.css "bg-stone-med" "background-color" "var(--color-stone-med)"
        . S.border1
        . S.border S.Gray 10
        . S.rounded
        . S.px S.S3
        . S.p S.S2
        . S.textXs
        . S.textWhite
        . S.css "focus:outline-none" "outline" "none"
        . S.pseudo "focus" (S.border S.Yellow 5)

    btnStyle =
      S.bg S.Yellow 5
        . S.hover (S.bg S.Yellow 4)
        . S.textBlack
        . S.p S.S2
        . S.rounded
        . S.fontBold
        . S.cls "fantasy-font"

renderLogEntry :: (DomBuilder t m, PostBuild t m) => Dynamic t LogEntry -> m ()
renderLogEntry logDyn = dyn_ $ ffor logDyn $ \l -> case l.payload of
  LogChat c -> do
    let chatStyle =
          S.bgAlpha S.Gray 10 50
            . S.rounded
            . S.p S.S2
            . S.css "animate-fade-in" "animation" "fadeIn 0.2s"
            . S.flex
            . S.gap S.S2
    let chatCls = classNames chatStyle
    elAttr
      "div"
      ( "class" =: chatCls
          <> testId "log-entry-chat"
      )
      $ do
        elS
          "div"
          ( S.w S.S6
              . S.h S.S6
              . S.roundedFull
              . S.bg S.Gray 9
              . S.flex
              . S.itemsCenter
              . S.justifyCenter
              . S.shrink0
          )
          $ text "Bot"
        divS S.flex1 $ do
          elS
            "div"
            ( S.fontSize 10
                . S.fontBold
                . S.text S.Gray 5
                . S.mb S.S0
            )
            $ text (renderSender l.sender)
          let msgCls = classNames (S.textSm . S.text S.Gray 2)
          elAttr "div" ("class" =: msgCls <> testId "log-entry-message") $
            text c
  LogInfo c -> do
    let (bg, bdr) = (S.text S.Gray 5, S.border S.Gray 10)
    divS (S.textXs . bg . S.italic . S.p S.S2 . S.borderB . bdr) $ text c
  LogError c -> do
    divS
      ( S.textXs
          . S.textWhite
          . S.bgAlpha S.Red 11 50
          . S.fontBold
          . S.p S.S2
          . S.borderB
          . S.border S.Red 10
      )
      $ text c
  LogChallenge challenge _plannedAction -> do
    -- Red-themed container for attack/challenge (matching vtt-react)
    let challengeStyle =
          S.bgAlpha S.Red 12 30
            . S.border1
            . S.borderAlpha S.Red 9 50
            . S.rounded
            . S.p S.S3
            . S.mb S.S2
            . S.css "animate-fade-in" "animation" "fadeIn 0.2s"
    divS challengeStyle $ do
      -- Header
      divS (S.textXs . S.fontBold . S.text S.Red 4 . S.flex . S.itemsCenter . S.gap S.S1) $
        text "Challenge Action"
      -- Attacker
      divS (S.textXs . S.text S.Gray 4 . S.mt S.S1) $
        text $
          "By: " <> renderSender l.sender
      -- Power display with color icon
      divS
        ( S.flex
            . S.itemsCenter
            . S.gap S.S2
            . S.textSm
            . S.bgAlpha S.Black 12 40
            . S.rounded
            . S.p S.S1
            . S.mt S.S2
        )
        $ do
          elS "span" (S.fontBold . S.text S.Red 5) $
            text $
              "Power: " <> tshow challenge.challengeStrength
          renderResourceType IconInline challenge.challengeColor Nothing
  LogDefense{} -> do
    -- Placeholder for Defense Logs (if rendered independently)
    let defenseStyle =
          S.bgAlpha S.Blue 12 30
            . S.border1
            . S.borderAlpha S.Blue 9 50
            . S.rounded
            . S.p S.S3
            . S.mb S.S2
    divS defenseStyle $ do
      divS (S.textXs . S.fontBold . S.text S.Blue 4) $ text "Defense Action"

renderSender :: LogSender -> T.Text
renderSender SenderSystem = "System"
renderSender SenderGame = "Game"
renderSender SenderGM = "GM"
renderSender SenderEnvironment = "Environment"
renderSender (SenderActor _ name) = name
