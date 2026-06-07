{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.Game.MapBoard
  ( mapBoardWidget
  ) where

import Control.Monad (forM_, when)
import Control.Monad.Fix (MonadFix)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.List.NonEmpty (NonEmpty)
import Data.Map.Strict qualified as Map
import Data.Maybe (isJust)
import Data.Text (Text)
import Data.Text qualified as T
import Language.Javascript.JSaddle
  ( JSM
  , JSVal
  , MonadJSM
  , call
  , eval
  , fun
  , liftJSM
  , valIsNull
  , valIsUndefined
  , valToBool
  , valToNumber
  , (!)
  , (#)
  )
import Reflex.Dom.Core
import Unsafe.Coerce (unsafeCoerce)

import Api.Request qualified as Req
import Api.Types (Phase (..))
import Core.Card
import Core.NonEmptyText (getRawText)
import Core.Primitives (ActorId)
import Core.State
import Frontend.Game.Class
import Frontend.Icons (iconCheck, iconClose, iconNote, iconSkull, iconSword, iconUser)
import Frontend.Style.Common (Style, classNames, componentS, divS)
import Frontend.Style.DSL qualified as S
import Frontend.Svg (svgEl)

-- | Named Style for the scrollable outer board container
mapBoardContainer :: Style
mapBoardContainer =
  S.relative
    . S.flex1
    . S.css "min-w-0" "min-width" "0"
    . S.css "min-h-0" "min-height" "0"
    . S.css "bg-board-outer" "background-color" "#0f172a" -- Slate-900
    . S.css "overflow-auto" "overflow" "auto"
    . S.css "cursor-crosshair" "cursor" "crosshair"
    . S.css "select-none" "user-select" "none"

-- | Named Style for the absolute-positioned grid cells container
gridContainer :: Style
gridContainer =
  S.relative
    . S.css "min-w-2000px" "min-width" "2000px"
    . S.css "min-h-2000px" "min-height" "2000px"
    . S.css "bg-board-grid" "background-color" "#1e293b" -- Slate-800
    . S.css "bg-size-40" "background-size" "40px 40px"
    . S.css
      "bg-img-grid"
      "background-image"
      "linear-gradient(to right, rgba(255,255,255,0.05) 1px, transparent 1px), linear-gradient(to bottom, rgba(255,255,255,0.05) 1px, transparent 1px)"

-- | Active highlighted ring style
activeRingStyle :: Style
activeRingStyle =
  S.absolute
    . S.css "top-neg-4" "top" "-4px"
    . S.css "bottom-neg-4" "bottom" "-4px"
    . S.css "left-neg-4" "left" "-4px"
    . S.css "right-neg-4" "right" "-4px"
    . S.roundedFull
    . S.css "border-ring-active" "border" "2px dashed #facc15" -- Yellow-400
    . S.pointerEventsNone
    . S.z 0
    . S.css "animate-spin-slow" "animation" "spin 8s linear infinite"

-- | Defeated highlighted static ring style
defeatedRingStyle :: Style
defeatedRingStyle =
  S.absolute
    . S.css "top-neg-4" "top" "-4px"
    . S.css "bottom-neg-4" "bottom" "-4px"
    . S.css "left-neg-4" "left" "-4px"
    . S.css "right-neg-4" "right" "-4px"
    . S.roundedFull
    . S.css "border-ring-defeated" "border" "2px dashed #7f1d1d" -- Red-900
    . S.pointerEventsNone
    . S.z 0

-- | Check if an actor is defeated by inspecting tableState consequences for "Taken Out"
isActorDefeated :: ActorState -> Bool
isActorDefeated actor =
  any (\c -> getRawText c.content.name == "Taken Out") actor.tableState.consequences

-- | Represents a click event on the map board.
data BoardClick
  = TokenClick
  | GridClick !Int !Int
  | OutOfBoundsClick
  deriving (Show, Eq)

-- | Type-safe helper to compute grid coordinates clicked on the board.
getBoardClick :: (MonadJSM m) => JSVal -> m BoardClick
getBoardClick ev = liftJSM $ do
  let jsLines =
        [ "(function(ev) {"
        , "  try {"
        , "    var target = ev.target;"
        , "    if (!target) return null;"
        , "    var closestEl = target.closest('.cursor-pointer');"
        , "    if (closestEl) return { isToken: true };"
        , "    var currentTarget = ev.currentTarget;"
        , "    if (!currentTarget) return null;"
        , "    var rect = currentTarget.getBoundingClientRect();"
        , "    var x = ev.clientX - rect.left;"
        , "    var y = ev.clientY - rect.top;"
        , "    if (x < 0 || y < 0) return null;"
        , "    return {"
        , "      isToken: false,"
        , "      gridX: Math.floor(x / 40),"
        , "      gridY: Math.floor(y / 40)"
        , "    };"
        , "  } catch (e) {"
        , "    return null;"
        , "  }"
        , "})"
        ]
  jsFunc <- eval (T.unlines jsLines)
  res <- call jsFunc jsFunc [ev]
  isNull <- valIsNull res
  isUndef <- valIsUndefined res
  if isNull || isUndef
    then return OutOfBoundsClick
    else do
      isTokenVal <- res ! ("isToken" :: Text)
      isToken <- valToBool isTokenVal
      if isToken
        then return TokenClick
        else do
          gx <- valToNumber =<< res ! ("gridX" :: Text)
          gy <- valToNumber =<< res ! ("gridY" :: Text)
          return $ GridClick (floor gx) (floor gy)

-- | Configuration for rendering a token circle.
data TokenCircleConfig = TokenCircleConfig
  { isGhost :: Bool
  , isSelected :: Bool
  , handSize :: Int
  }

-- | Token renderer widget
renderTokenCircle
  :: (DomBuilder t m, PostBuild t m, MonadHold t m, MonadFix m)
  => Dynamic t ActorState
  -> Dynamic t TokenCircleConfig
  -> m ()
renderTokenCircle actorDyn configDyn = do
  let isDefeatedDyn = ffor2 actorDyn configDyn $ \actor config ->
        isActorDefeated actor && not config.isGhost

      isSelectedActiveRingDyn = ffor2 actorDyn configDyn $ \actor config ->
        config.isSelected && not (isActorDefeated actor) && not config.isGhost

      isSelectedDefeatedRingDyn = ffor2 actorDyn configDyn $ \actor config ->
        config.isSelected && isActorDefeated actor && not config.isGhost

  -- Active and Defeated Highlight Rings
  dyn_ $ ffor isSelectedActiveRingDyn $ \case
    True -> divS activeRingStyle blank
    False -> blank

  dyn_ $ ffor isSelectedDefeatedRingDyn $ \case
    True -> divS defeatedRingStyle blank
    False -> blank

  -- Inner Circle Background styling
  let bgClsDyn = ffor2 actorDyn configDyn $ \actor config ->
        let isDefeated = isActorDefeated actor && not config.isGhost
            isSelected = config.isSelected && not config.isGhost
         in if isDefeated
              then
                S.css "bg-token-defeated" "background-color" "#0f172a"
                  . S.css "border-token-defeated" "border-color" "#475569"
              else
                if isSelected
                  then
                    S.css "bg-token-active" "background-color" "#1e293b"
                      . S.css "border-token-active" "border-color" "#facc15"
                      . S.css "shadow-token-active" "box-shadow" "0 0 15px rgba(250,204,21,0.5)"
                      . S.scale105
                  else
                    S.css "bg-token-default" "background-color" "#1e293b"
                      . S.css "border-token-default" "border-color" "rgba(255,255,255,0.2)"
                      . S.hover (S.css "border-token-hover" "border-color" "rgba(255,255,255,0.5)")

      circleStyleDyn = ffor bgClsDyn $ \bgCls ->
        S.wFull
          . S.hFull
          . S.roundedFull
          . S.overflowHidden
          . S.relative
          . S.border2
          . S.css "transition-token" "transition" "all 0.2s ease-out"
          . bgCls

  elDynAttr
    "div"
    (ffor circleStyleDyn $ \s -> "class" =: classNames s <> "data-testid" =: "token-circle")
    $ do
      -- Icon type mapping
      let iconWidgetDyn = ffor actorDyn $ \actor ->
            case T.toLower actor.actorType of
              "monster" -> iconSkull
              "npc" -> iconUser
              "character" -> iconSword
              "pc" -> iconSword
              _ -> iconUser

      divS
        ( S.css "w-pct-50" "width" "50%"
            . S.css "h-pct-50" "height" "50%"
            . S.css "m-auto" "margin" "auto"
            . S.css "mt-pct-25" "margin-top" "25%"
            . S.css "text-white-pure" "color" "#ffffff"
            . S.opacity 0.8
        )
        $ do
          dyn_ iconWidgetDyn

      -- Defeated standard Red Overlay Cross
      dyn_ $ ffor isDefeatedDyn $ \case
        True ->
          divS
            ( S.absolute
                . S.inset0
                . S.flex
                . S.itemsCenter
                . S.justifyCenter
                . S.css "bg-black-overlay" "background-color" "rgba(0,0,0,0.5)"
                . S.css "backdrop-blur-4px" "backdrop-filter" "blur(4px)"
            )
            $ divS
              ( S.css "w-20px" "width" "20px"
                  . S.css "h-20px" "height" "20px"
                  . S.css "text-red-icon" "color" "#ef4444"
              )
              iconClose
        False -> blank

  -- Status Indicators (absolute positioned outside circle boundaries)
  let showStatusDyn = ffor2 actorDyn configDyn $ \actor config ->
        not (isActorDefeated actor) && not config.isGhost

      hasPlanDyn = ffor actorDyn $ \actor ->
        isJust actor.plannedMove

      handSizeDyn = (.handSize) <$> configDyn

  dyn_ $ ffor2 showStatusDyn hasPlanDyn $ \showStatus hasPlan ->
    when (showStatus && hasPlan) $
      divS
        ( S.absolute
            . S.css "top-neg-4" "top" "-4px"
            . S.css "right-neg-4" "right" "-4px"
            . S.z 30
            . S.css "bg-green-checkmark" "background-color" "#22c55e" -- Green-500
            . S.css "text-white-pure" "color" "#ffffff"
            . S.roundedFull
            . S.css "p-2px" "padding" "2px"
            . S.css "border-checkmark" "border" "1px solid #0f172a"
            . S.css "w-18px" "width" "18px"
            . S.css "h-18px" "height" "18px"
            . S.css "animate-bounce-slow" "animation" "bounce 1s infinite"
        )
        iconCheck

  dyn_ $ ffor2 showStatusDyn handSizeDyn $ \showStatus handSize ->
    when showStatus
      $ divS
        ( S.absolute
            . S.css "bottom-neg-4" "bottom" "-4px"
            . S.css "right-neg-4" "right" "-4px"
            . S.z 30
            . S.flex
            . S.itemsCenter
            . S.justifyCenter
            . S.css "bg-token-badge" "background-color" "#1e293b"
            . S.css "border-token-badge" "border" "1px solid #475569"
            . S.css "rounded-4px" "border-radius" "4px"
            . S.css "shadow-token-badge" "box-shadow" "0 1px 2px rgba(0,0,0,0.5)"
            . S.py S.S1
            . S.px S.S2
            . S.css "min-w-20px" "min-width" "20px"
            . S.css "h-16px" "height" "16px"
        )
      $ do
        divS
          ( S.css "w-10px" "width" "10px"
              . S.css "h-10px" "height" "10px"
              . S.css "text-badge-icon" "color" "#94a3b8"
              . S.css "mr-2px" "margin-right" "2px"
          )
          iconNote
        elAttr
          "span"
          ( "style"
              =: "font-size: 10px; font-weight: bold; color: #ffffff; line-height: 1; font-family: sans-serif;"
          )
          $ text (T.pack (show handSize))

-- | Renders the SVG layer containing dashed path lines and circular endpoints
renderStaticSvg :: (DomBuilder t m, PostBuild t m) => Dynamic t (Map.Map ActorId ActorState) -> m ()
renderStaticSvg actorsMapDyn = do
  let svgAttrs =
        "class" =: "absolute inset-0 w-full h-full pointer-events-none z-20"
          <> "style"
            =: "position: absolute; left: 0; top: 0; width: 100%; height: 100%; pointer-events: none; z-index: 20; overflow: visible;"
  svgEl "svg" svgAttrs $ do
    dyn_ $ ffor actorsMapDyn $ \actors -> do
      forM_ (Map.toList actors) $ \(_, actor) -> do
        case actor.plannedMove of
          Nothing -> return ()
          Just (targetX, targetY) -> do
            when (targetX /= actor.spatial.posX || targetY /= actor.spatial.posY) $ do
              let startX = actor.spatial.posX * 40 + 20
                  startY = actor.spatial.posY * 40 + 20
                  endX = targetX * 40 + 20
                  endY = targetY * 40 + 20
                  color = "#e2e8f0"
              svgEl "g" Map.empty $ do
                svgEl
                  "line"
                  ( "x1" =: T.pack (show startX)
                      <> "y1" =: T.pack (show startY)
                      <> "x2" =: T.pack (show endX)
                      <> "y2" =: T.pack (show endY)
                      <> "stroke" =: color
                      <> "stroke-width" =: "2"
                      <> "stroke-dasharray" =: "5,5"
                      <> "opacity" =: "0.6"
                  )
                  blank
                svgEl
                  "circle"
                  ( "cx" =: T.pack (show endX)
                      <> "cy" =: T.pack (show endY)
                      <> "r" =: "4"
                      <> "fill" =: color
                  )
                  blank

-- | Map VTT Battlemap board widget
mapBoardWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadIO m
     , Prerender t m
     , MonadGame t m
     , MonadGame t (Client m)
     )
  => Dynamic t (Maybe ActorId) -- Selected Actor
  -> m (Event t (Maybe ActorId)) -- Selection click change
mapBoardWidget selectedActorId = componentS "map-board-container" mapBoardContainer $ do
  actorsMapDyn <- askActors
  phaseDyn <- askPhase

  let serverSide = do
        elAttr "div" ("class" =: classNames gridContainer <> "data-testid" =: "map-grid") $ do
          renderStaticSvg actorsMapDyn
          _ <- listWithKey actorsMapDyn $ \actorId actorDyn -> do
            let spatialDyn = (.spatial) <$> actorDyn
                isDefeatedDyn = isActorDefeated <$> actorDyn
                isSelectedDyn = ffor2 selectedActorId actorDyn $ \mSelId _ ->
                  mSelId == Just actorId
            let tokenAttrsDyn = (,,,) <$> spatialDyn <*> isSelectedDyn <*> isDefeatedDyn <*> actorDyn
                divAttrsDyn = ffor tokenAttrsDyn $ \(spatial, isSelected, isDefeated, actor) ->
                  let x = spatial.posX * 40
                      y = spatial.posY * 40
                      sz = spatial.size * 40
                      zIndexStr = if isSelected then "50" else "10"
                      styleStr =
                        "position: absolute; left: "
                          <> T.pack (show x)
                          <> "px; top: "
                          <> T.pack (show y)
                          <> "px; width: "
                          <> T.pack (show sz)
                          <> "px; height: "
                          <> T.pack (show sz)
                          <> "px; transition: all 0.2s ease-out; z-index: "
                          <> zIndexStr
                          <> ";"
                      baseCls = "group flex items-center justify-center relative"
                      clsStr = if isDefeated then baseCls <> " grayscale opacity-70" else baseCls
                   in "style" =: styleStr
                        <> "class" =: clsStr
                        <> "title" =: (actor.name <> if isDefeated then " (Defeated)" else "")

            _ <- elDynAttr "div" divAttrsDyn $ do
              let tokenConfigDyn = constDyn (TokenCircleConfig False False 0)
              renderTokenCircle actorDyn tokenConfigDyn
            return ()
          return ()
        return never

      clientSide = do
        renderInteractiveBoard selectedActorId actorsMapDyn phaseDyn

  evDyn <- prerender serverSide clientSide
  return $ switch (current evDyn)

-- | Renders the fully interactive board with JSM events and dispatch triggers
renderInteractiveBoard
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     , MonadIO m
     , MonadGame t m
     , PerformEvent t m
     , TriggerEvent t m
     , MonadJSM (Performable m)
     )
  => Dynamic t (Maybe ActorId)
  -> Dynamic t (Map.Map ActorId ActorState)
  -> Dynamic t Phase
  -> m (Event t (Maybe ActorId))
renderInteractiveBoard selectedActorId actorsMapDyn phaseDyn = do
  (eGrid, tokenClicksMapDyn) <- elAttr' "div" ("class" =: classNames gridContainer <> "data-testid" =: "map-grid") $ do
    -- 1. SVG planned paths layer
    renderStaticSvg actorsMapDyn

    -- 2. Render standard and ghost tokens inside the grid container
    listWithKey actorsMapDyn $ \actorId actorDyn -> do
      let plannedMoveDyn = (.plannedMove) <$> actorDyn
          spatialDyn = (.spatial) <$> actorDyn
          isDefeatedDyn = isActorDefeated <$> actorDyn
          isSelectedDyn = ffor2 selectedActorId actorDyn $ \mSelId _ ->
            mSelId == Just actorId

      -- 2a. Ghost Token (Planned move preview)
      let ghostAttrsDyn = ffor3 spatialDyn plannedMoveDyn actorDyn $ \spatial plan actor ->
            case plan of
              Nothing ->
                "style" =: "display: none;"
              Just (planX, planY) ->
                if planX /= spatial.posX || planY /= spatial.posY
                  then
                    let x = planX * 40
                        y = planY * 40
                        sz = spatial.size * 40
                        ghostStyle =
                          "position: absolute; left: "
                            <> T.pack (show x)
                            <> "px; top: "
                            <> T.pack (show y)
                            <> "px; width: "
                            <> T.pack (show sz)
                            <> "px; height: "
                            <> T.pack (show sz)
                            <> "px; z-index: 40;"
                     in "style" =: ghostStyle
                          <> "class" =: "group flex items-center justify-center relative cursor-pointer opacity-50 grayscale"
                          <> "title" =: (actor.name <> " (Planned Location)")
                  else
                    "style" =: "display: none;"

      (eGhost, _) <- elDynAttr' "div" ghostAttrsDyn $ do
        let ghostConfigDyn = constDyn (TokenCircleConfig True False 0)
        renderTokenCircle actorDyn ghostConfigDyn

      let clickGhostEv = domEvent Click eGhost
          cancelReq = Req.CancelPlan actorId <$ clickGhostEv
      _ <- requestGame cancelReq

      -- 2b. Standard Token
      let handSizeDyn = ffor2 phaseDyn actorDyn $ \phase actor ->
            let handSize = length (actor.coreState.hand :: [CardInstance CoreCard])
                planned = actor.coreState.planned
                plannedCount = case planned of
                  Nothing -> 0
                  Just p -> case p of
                    PStandard (ActionStack _ res) -> 1 + length (res :: [CardInstance CoreCard])
                    PNarrative (NarrativeStack cs _) -> length (cs :: NonEmpty (CardInstance CoreCard))
                    PPass -> 0
             in if phase == Planning then handSize + plannedCount else handSize

      let tokenAttrsDyn = (,,,) <$> spatialDyn <*> isSelectedDyn <*> isDefeatedDyn <*> actorDyn
          divAttrsDyn = ffor tokenAttrsDyn $ \(spatial, isSelected, isDefeated, actor) ->
            let x = spatial.posX * 40
                y = spatial.posY * 40
                sz = spatial.size * 40
                zIndexStr = if isSelected then "50" else "10"
                styleStr =
                  "position: absolute; left: "
                    <> T.pack (show x)
                    <> "px; top: "
                    <> T.pack (show y)
                    <> "px; width: "
                    <> T.pack (show sz)
                    <> "px; height: "
                    <> T.pack (show sz)
                    <> "px; transition: all 0.2s ease-out; z-index: "
                    <> zIndexStr
                    <> ";"
                baseCls = "group flex items-center justify-center relative cursor-pointer"
                clsStr = if isDefeated then baseCls <> " grayscale opacity-70" else baseCls
             in "style" =: styleStr
                  <> "class" =: clsStr
                  <> "title" =: (actor.name <> if isDefeated then " (Defeated)" else "")

      (eToken, _) <- elDynAttr' "div" divAttrsDyn $ do
        let tokenConfigDyn = TokenCircleConfig False <$> isSelectedDyn <*> handSizeDyn
        renderTokenCircle actorDyn tokenConfigDyn

      let clickEv = domEvent Click eToken
          actorSelectedEv = actorId <$ clickEv

      return actorSelectedEv

  -- 3. Click Empty space coordinates tracker on grid container
  postBuildEv <- getPostBuild
  let rawGridVal = unsafeCoerce (_element_raw eGrid) :: JSVal
  (coordsEv, triggerCoords) <- newTriggerEvent
  performEvent_ $ ffor postBuildEv $ \_ -> liftJSM $ do
    let cb :: JSVal -> JSVal -> [JSVal] -> JSM ()
        cb _ _ [ev] = do
          click <- getBoardClick ev
          liftIO $ triggerCoords click
        cb _ _ _ = return ()
        cbFunc = fun cb
    _ <- rawGridVal # ("addEventListener" :: Text) $ ("click" :: Text, cbFunc)
    return ()

  -- PlanMove dispatching (when actor is selected and you click a coordinate during Planning phase)
  let movePlanReq =
        attachWithMaybe
          ( \(mId, phase) click ->
              case click of
                GridClick gx gy | phase == Planning -> fmap (\aid -> Req.PlanMove aid gx gy) mId
                _ -> Nothing
          )
          (current ((,) <$> selectedActorId <*> phaseDyn))
          coordsEv
  _ <- requestGame movePlanReq

  -- Select grid coordinate click deselects active selection *only* if NOT in Planning phase
  let selectGridEv =
        attachWithMaybe
          ( \(mId, phase) click ->
              case click of
                GridClick _ _ | isJust mId && phase /= Planning -> Just Nothing
                _ -> Nothing
          )
          (current ((,) <$> selectedActorId <*> phaseDyn))
          coordsEv

  let selectActorEv = switchDyn (leftmost . Map.elems <$> tokenClicksMapDyn)

  return $ leftmost [selectGridEv, fmap Just selectActorEv]
