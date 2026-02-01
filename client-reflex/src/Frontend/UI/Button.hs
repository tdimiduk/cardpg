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

import Frontend.Style.Common

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
  deriving (Eq, Show)

-- | Size presets
data ButtonSize
  = -- | Compact text/padding
    SizeSmall
  | -- | Standard size
    SizeMedium
  | -- | Prominent/Large touch target
    SizeLarge
  deriving (Eq, Show)

-- | Configuration for the button widget
data ButtonConfig t = ButtonConfig
  { variant :: Dynamic t ButtonVariant
  , size :: Dynamic t ButtonSize
  , disabled :: Dynamic t Bool
  , fullWidth :: Bool
  , testId :: Maybe T.Text
  -- ^ Optional test ID for automation
  , classes :: [CssClass]
  -- ^ Additional custom classes
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
      , classes = []
      , attributes = constDyn mempty
      }

-- | A unified button widget
button
  :: (DomBuilder t m, PostBuild t m)
  => ButtonConfig t
  -> m ()
  -- ^ Label content
  -> m (Event t ())
button cfg label = do
  -- Base classes shared by all buttons
  let baseClasses =
        [ flex
        , itemsCenter
        , justifyCenter
        , rounded
        , fontBold
        , "transition-colors"
        , "duration-200"
        , "select-none"
        ]

  -- Width handling
  let widthClass = (["w-full" | cfg.fullWidth])

  -- Size classes
  let sizeClasses = ffor cfg.size $ \case
        SizeSmall -> ["px-2", "py-1", textXs]
        SizeMedium -> ["px-4", "py-2", textSm]
        SizeLarge -> ["px-6", "py-3", "text-base"]

  -- Variant classes (color schemes)
  let variantClasses = ffor cfg.variant $ \case
        VariantPrimary ->
          [ "bg-indigo-600"
          , "text-white"
          , "hover:bg-indigo-500"
          , "active:bg-indigo-700"
          , "shadow-sm"
          ]
        VariantSecondary ->
          [ "bg-slate-800"
          , "text-slate-200"
          , "border"
          , "border-slate-600"
          , "hover:bg-slate-700"
          , "active:bg-slate-600"
          ]
        VariantDestructive ->
          [ "bg-red-900/50"
          , "text-red-200"
          , "border"
          , "border-red-800"
          , "hover:bg-red-800/50"
          , "hover:text-red-100"
          ]
        VariantGhost ->
          [ "bg-transparent"
          , "text-slate-400"
          , "hover:bg-slate-800/50"
          , "hover:text-slate-200"
          ]
        VariantOutline ->
          [ "bg-transparent"
          , "text-slate-200"
          , "border"
          , "border-slate-600"
          , "hover:border-slate-500"
          , "hover:text-white"
          ]

  -- Disabled state styling
  let disabledClasses =
        [ "opacity-50"
        , "cursor-not-allowed"
        , "hover:bg-none" -- Reset hover effects if possible (imperfect in tailwind without group-hover logic, but opacity helps)
        ]

  let dynClasses = do
        sz <- sizeClasses
        var <- variantClasses
        dis <- cfg.disabled
        let interaction = if dis then disabledClasses else [cursorPointer]

        pure $
          baseClasses
            <> widthClass
            <> cfg.classes
            <> var
            <> interaction
            <> sz

  let attrs = ffor3 dynClasses cfg.disabled cfg.attributes $ \cls dis attrs' ->
        "class" =: classes cls
          <> mkDisabledAttr dis
          <> maybe mempty testId cfg.testId
          <> attrs'

  (e, _) <- elDynAttr' "button" attrs label

  -- Gate the click event by the disabled state
  return $ gate (not <$> current cfg.disabled) (domEvent Click e)

mkDisabledAttr :: Bool -> Map.Map T.Text T.Text
mkDisabledAttr True = "disabled" =: "true"
mkDisabledAttr False = mempty
