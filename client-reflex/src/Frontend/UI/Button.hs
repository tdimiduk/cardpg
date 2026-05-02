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

import Frontend.Style.Common (Style, classNames)
import Frontend.Style.DSL

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
  | -- | Transparent with border
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
  SizeSmall -> px2 . py1 . textXs
  SizeMedium -> px4 . py2 . textSm
  SizeLarge -> px6 . py3 . textBase

variantStyle :: ButtonVariant -> Style
variantStyle = \case
  VariantPrimary ->
    bgIndigo600
      . textWhite
      . shadowSm
      . hover bgIndigo500
  VariantSecondary ->
    bgSlate800
      . textSlate400
      . border
      . borderSlate700
      . hover bgSlate700
      . hover textSlate200
  VariantDestructive ->
    bgRed900_50
      . textRed200
      . border
      . borderRed800
  VariantGhost ->
    bgTransparent
      . textSlate400
  VariantOutline ->
    bgTransparent
      . textSlate200
      . border
      . borderSlate600

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
