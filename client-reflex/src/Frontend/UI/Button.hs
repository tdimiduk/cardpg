{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Frontend.UI.Button
  ( -- * Types
    ButtonVariant (..)
  , ButtonSize (..)
  , ButtonConfig (..)

    -- * Widget
  , button
  ) where

import Data.Default (Default (..))

import Reflex.Dom.Core hiding (button)

import Frontend.Style

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
  { _buttonConfig_variant :: Dynamic t ButtonVariant
  , _buttonConfig_size :: Dynamic t ButtonSize
  , _buttonConfig_disabled :: Dynamic t Bool
  , _buttonConfig_fullWidth :: Bool
  , _buttonConfig_classes :: [CssClass]
  -- ^ Additional custom classes
  }

instance (Reflex t) => Default (ButtonConfig t) where
  def =
    ButtonConfig
      { _buttonConfig_variant = constDyn VariantPrimary
      , _buttonConfig_size = constDyn SizeMedium
      , _buttonConfig_disabled = constDyn False
      , _buttonConfig_fullWidth = False
      , _buttonConfig_classes = []
      }

-- | A unified button widget
button
  :: (DomBuilder t m, PostBuild t m)
  => ButtonConfig t
  -> m ()
  -- ^ Label content
  -> m (Event t ())
button ButtonConfig{..} label = do
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
  let widthClass = (["w-full" | _buttonConfig_fullWidth])

  -- Size classes
  let sizeClasses = ffor _buttonConfig_size $ \case
        SizeSmall -> ["px-2", "py-1", textXs]
        SizeMedium -> ["px-4", "py-2", textSm]
        SizeLarge -> ["px-6", "py-3", "text-base"]

  -- Variant classes (color schemes)
  let variantClasses = ffor _buttonConfig_variant $ \case
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

  -- Combine all dynamic classes
  let dynClasses = do
        sz <- sizeClasses
        var <- variantClasses
        dis <- _buttonConfig_disabled
        let interaction = if dis then disabledClasses else [cursorPointer]

        return $
          baseClasses
            <> widthClass
            <> _buttonConfig_classes
            <> var
            <> interaction
            <> sz

  -- We use 'button' element.
  -- Note: Reflex 'button' helper is simple, but 'elDynAttr'' gives us more control.
  let attrs = ffor ((,) <$> dynClasses <*> _buttonConfig_disabled) $ \(cls, dis) ->
        "class" =: classes cls
          <> if dis then "disabled" =: "true" else mempty

  (e, _) <- elDynAttr' "button" attrs label

  -- Gate the click event by the disabled state
  return $ gate (not <$> current _buttonConfig_disabled) (domEvent Click e)
