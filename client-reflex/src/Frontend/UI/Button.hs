{-# LANGUAGE OverloadedStrings #-}

module Frontend.UI.Button
  ( -- * Types
    ButtonVariant (..)
  , ButtonSize (..)
  , ButtonConfig (..)

    -- * Widget
  , button
  ) where

import Data.Default (Default (..))
import Data.Map qualified as Map
import Data.Text qualified as T

import Reflex.Dom.Core hiding (button)

import Frontend.Style.Common (classNames)
import Frontend.Style.DSL
import Frontend.Style.DSL qualified as S

-- | Visual variants for the button
data ButtonVariant
  = -- | Main action (Indigo)
    VariantPrimary
  | -- | Alternative action (Gray/Slate)
    VariantSecondary
  | -- | Dangerous/Negative (Red)
    VariantDestructive
  | -- | Minimalist, hover effect only
    VariantGhost
  | -- | Transparent with S.border1
    VariantOutline
  deriving (Eq, Show, Enum, Bounded)

-- | Size presets
data ButtonSize
  = -- | Compact text/padding
    SizeSmall
  | -- | Standard size
    SizeMedium
  | -- | Prominent/Large touch target
    SizeLarge
  deriving (Eq, Show, Enum, Bounded)

-- | Configuration for the button widget
data ButtonConfig t = ButtonConfig
  { variant :: Dynamic t ButtonVariant
  , size :: Dynamic t ButtonSize
  , disabled :: Dynamic t Bool
  , fullWidth :: Bool
  , testId :: Maybe T.Text
  -- ^ Optional test ID for automation
  , extraStyle :: Style
  -- ^ Additional custom styles
  , attributes :: Dynamic t (Map.Map T.Text T.Text)
  -- ^ Arbitrary HTML attributes
  }

instance (Reflex t) => Default (ButtonConfig t) where
  def =
    ButtonConfig
      { variant = constDyn VariantPrimary
      , size = constDyn SizeMedium
      , disabled = constDyn False
      , fullWidth = False
      , testId = Nothing
      , extraStyle = id
      , attributes = constDyn mempty
      }

sizeStyle :: ButtonSize -> Style
sizeStyle = \case
  SizeSmall -> px S2 . py S1 . textXs
  SizeMedium -> px S4 . py S2 . textSm
  SizeLarge -> px S6 . py S3 . textBase

variantStyle :: ButtonVariant -> Style
variantStyle = \case
  VariantPrimary ->
    S.bg S.Indigo 8
      . textWhite
      . shadowSm
      . hover (S.bg S.Indigo 7)
  VariantSecondary ->
    S.bg S.Gray 10
      . S.text S.Gray 4
      . S.border1
      . S.border S.Gray 9
      . hover (S.bg S.Gray 9)
      . hover (S.text S.Gray 2)
  VariantDestructive ->
    S.bgAlpha S.Red 11 50
      . S.text S.Red 3
      . S.border1
      . S.border S.Red 10
  VariantGhost ->
    bgTransparent
      . S.text S.Gray 4
  VariantOutline ->
    bgTransparent
      . S.text S.Gray 2
      . S.border1
      . S.border S.Gray 8

-- | Base styles shared by all buttons
baseStyle :: Style
baseStyle =
  flex
    . itemsCenter
    . justifyCenter
    . rounded
    . fontBold
    . transitionColors
    . duration200
    . selectNone

-- | Disabled state styling
disabledStyle :: Style
disabledStyle = opacity50 . cursorNotAllowed

-- | A unified button widget
button
  :: (DomBuilder t m, PostBuild t m)
  => ButtonConfig t
  -> m ()
  -- ^ Label content
  -> m (Event t ())
button cfg label = do
  -- Width handling
  let widthStyle = if cfg.fullWidth then wFull else id

  let dynClassText = do
        sz <- ffor cfg.size sizeStyle
        var <- ffor cfg.variant variantStyle
        dis <- cfg.disabled
        let interaction = if dis then disabledStyle else cursorPointer
        let fullStyle = baseStyle . widthStyle . cfg.extraStyle . var . interaction . sz
        pure $ classNames fullStyle

  let attrs = ffor3 dynClassText cfg.disabled cfg.attributes $ \clsText dis attrs' ->
        "class" =: clsText
          <> mkDisabledAttr dis
          <> maybe mempty testIdAttr cfg.testId
          <> attrs'

  (e, _) <- elDynAttr' "button" attrs label

  -- Gate the click event by the disabled state
  return $ gate (not <$> current cfg.disabled) (domEvent Click e)

testIdAttr :: T.Text -> Map.Map T.Text T.Text
testIdAttr = ("data-testid" =:)

mkDisabledAttr :: Bool -> Map.Map T.Text T.Text
mkDisabledAttr True = "disabled" =: "true"
mkDisabledAttr False = mempty
