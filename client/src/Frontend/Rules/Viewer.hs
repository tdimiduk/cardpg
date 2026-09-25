{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecursiveDo #-}

-- |
-- Module: Frontend.Rules.Viewer
-- Description: In-App Rules & Keyword Glossary Viewer modal with tab navigation.
module Frontend.Rules.Viewer
  ( RulesTab (..)
  , rulesViewerWidget
  , rulesViewerWidgetWithInitialTab
  , rulesViewerModal
  , rulesViewerModalWithTab
  ) where

import Control.Monad (forM, void)
import Control.Monad.Fix (MonadFix)
import Data.Text (Text)
import Reflex.Dom.Core hiding (button)

import Frontend.Icons (iconClose)
import Frontend.Render.Pandoc (RenderEnv (..), RenderMode (..), renderPandoc)
import Frontend.Rules.Data
  ( RulesTab (..)
  , allRulesTabs
  , embeddedGlossary
  , lookupDoc
  , rulesTabTitle
  )
import Frontend.Style.Common (classNames, divS)
import Frontend.Style.DSL qualified as S
import Frontend.UI.Button (ButtonConfig (..), ButtonSize (..), ButtonVariant (..), button)

-- | Overlay modal / slide-out drawer rendering the rules viewer.
-- Returns an Event firing when the user dismisses the modal (close button, backdrop, or ESC).
rulesViewerWidget
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => Event t ()
  -> m (Event t ())
rulesViewerWidget = rulesViewerWidgetWithInitialTab TabCoreRules

-- | Rules viewer modal with a specified initial active tab.
rulesViewerWidgetWithInitialTab
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => RulesTab
  -> Event t ()
  -> m (Event t ())
rulesViewerWidgetWithInitialTab initialTab externalClose = do
  let overlayStyle =
        S.fixed
          <> S.inset0
          <> S.z 50
          <> S.flex
          <> S.itemsCenter
          <> S.justifyCenter
          <> S.p S.S4

      backdropStyle =
        S.absolute
          <> S.inset0
          <> S.bgAlpha S.Black 12 75
          <> S.backdropBlurMd

      panelStyle =
        S.cls "obsidian-panel"
          <> S.bgStoneDark
          <> S.border1
          <> S.borderGoldMuted
          <> S.roundedXl
          <> S.shadow2Xl
          <> S.wFull
          <> S.maxW4Xl
          <> S.h (S.Vh 85)
          <> S.flexCol
          <> S.overflowHidden
          <> S.relative
          <> S.z 10

  divS overlayStyle $ do
    -- Backdrop (clicking it triggers dismissal)
    (backdropEl, _) <-
      elAttr'
        "div"
        ( "class" =: classNames backdropStyle
            <> "data-testid" =: "rules-backdrop"
        )
        blank

    -- Main modal window panel
    (modalEl, closeEvt) <-
      elAttr'
        "div"
        ( "class" =: classNames panelStyle
            <> "tabindex" =: "0"
            <> "data-testid" =: "rules-viewer-modal"
        )
        $ do
          -- Header / Tab bar
          rec activeTabDyn <- holdDyn initialTab tabSwitchEvt
              (tabSwitchEvt, closeBtnClick) <-
                divS
                  ( S.px S.S6
                      <> S.py S.S3
                      <> S.borderB
                      <> S.borderGoldMuted
                      <> S.bgStoneDark
                      <> S.flex
                      <> S.justifyBetween
                      <> S.itemsCenter
                      <> S.shrink0
                  )
                  $ do
                    -- Tab navigation
                    tabClicks <- divS (S.flex <> S.gap S.S6 <> S.itemsCenter) $ do
                      forM allRulesTabs $ \tab -> do
                        let isCurrentTabDyn = (== tab) <$> activeTabDyn
                            tabStyleDyn = ffor isCurrentTabDyn $ \isActive ->
                              S.fontCinzel
                                <> S.cursorPointer
                                <> S.pb S.S1
                                <> S.borderB2
                                <> ( if isActive
                                       then S.textGoldBright <> S.borderGoldBright <> S.fontBold
                                       else S.text S.Gray 4 <> S.borderTransparent <> S.hover S.textGoldBright
                                   )
                        (tabEl, _) <-
                          elDynAttr'
                            "button"
                            ( ffor tabStyleDyn $ \st ->
                                "class" =: classNames st
                                  <> "data-testid" =: ("tab-" <> tabTestId tab)
                                  <> "type" =: "button"
                            )
                            (text (rulesTabTitle tab))
                        pure (tab <$ domEvent Click tabEl)

                    -- Close button
                    closeBtn <-
                      button
                        def
                          { variant = VariantGhost
                          , size = SizeSmall
                          , extraStyle = S.text S.Gray 4 <> S.hover S.textGoldBright <> S.p S.S1
                          , attributes = "data-testid" =: "close-rules-viewer"
                          }
                        $ divS (S.w S.S5 <> S.h S.S5) iconClose

                    pure (leftmost tabClicks, closeBtn)

          -- Scrollable content container
          divS
            ( S.flex1
                <> S.overflowYAuto
                <> S.wFull
                <> S.p S.S6
                <> S.cls "rules-content"
            )
            $ do
              divS (S.maxW4Xl <> S.mxAuto) $ do
                let env = RenderEnv{glossary = embeddedGlossary, renderMode = RenderInteractive}
                dyn_ $ ffor activeTabDyn $ \tab -> do
                  let docAst = lookupDoc tab
                  renderPandoc env docAst

          pure closeBtnClick

    let escEvt = void (ffilter (== 27) (domEvent Keydown modalEl))
        backdropClick = domEvent Click backdropEl
    pure (leftmost [closeEvt, escEvt, backdropClick, externalClose])

-- | Test ID helper for tab buttons.
tabTestId :: RulesTab -> Text
tabTestId TabCoreRules = "core-rules"
tabTestId TabGlossary = "glossary"
tabTestId TabColors = "colors"

-- | Self-contained modal wrapper that mounts and unmounts the viewer.
rulesViewerModal
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => Event t ()
  -> m ()
rulesViewerModal openEvt = rulesViewerModalWithTab (Just TabCoreRules <$ openEvt)

-- | Self-contained modal wrapper opening to a specific tab if requested.
rulesViewerModalWithTab
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => Event t (Maybe RulesTab)
  -> m ()
rulesViewerModalWithTab openTabEvt = mdo
  let closeReq = switchDyn closeEvtDyn
      viewStateEvt = leftmost [openTabEvt, Nothing <$ closeReq]
  closeEvtDyn <- widgetHold (pure never) $ ffor viewStateEvt $ \case
    Nothing -> pure never
    Just tab -> rulesViewerWidgetWithInitialTab tab never
  pure ()
