{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module Frontend.UI.Scaler (scalable) where

import Control.Monad (void)
import Data.Text (Text)
import Data.Text qualified as T
import Reflex.Dom.Core

-- | Wraps content in a responsive "scaler" container.
--
-- The container has a fixed aspect ratio (based on the provided mm dimensions)
-- and width: 100%. The content is rendered at its *canonical* size (in mm) absolute
-- positioned inside, and then scaled (via CSS transform) to fit the container.
--
-- This scaling happens entirely in JS via ResizeObserver to avoid layout thrashing.
scalable ::
  (DomBuilder t m) =>
  -- | Width in mm
  Double ->
  -- | Height in mm
  Double ->
  -- | Content to scale
  m a ->
  m a
scalable wMm hMm content = do
  let wVal = T.pack (show wMm) <> "mm"
      hVal = T.pack (show hMm) <> "mm"
      aspect = T.pack (show wMm) <> " / " <> T.pack (show hMm)

      containerStyle = "width: 100%; position: relative; aspect-ratio: " <> aspect <> ";"
      contentStyle =
        "position: absolute; top: 0; left: 0; width: "
          <> wVal
          <> "; height: "
          <> hVal
          <> "; transform-origin: top left;"

  (containerEl, result) <- elAttr'
    "div"
    ( "style" =: containerStyle
        <> "class" =: "scaler-container"
        <> "data-native-w" =: T.pack (show wMm)
    )
    $ do
      elAttr "div" ("style" =: contentStyle <> "class" =: "scaler-target") content

  return result
