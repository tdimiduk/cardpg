---
name: scaffold_reflex
description: Create a new Reflex widget module following project best practices
---

# Skill: scaffold_reflex

This skill provides a standardized way to create new Reflex UI widgets in the `client-reflex` project. It ensures adherence to best practices like avoiding `promptly` functions and proper `Render` instance setup.

## Instructions

When creating a new UI component, follow these steps:

1.  **Determine Module Path**: Based on the component's purpose (e.g., `Frontend.Game.MyWidget`).
2.  **Create File**: Create the file at the corresponding path (e.g., `client-reflex/src/Frontend/Game/MyWidget.hs`).
3.  **Apply Template**: Use the following template, replacing `ModuleName` and `WidgetName` appropriately.

### Template

```haskell
{-# LANGUAGE FlexibleContexts #-}

module Frontend.Game.ModuleName
  ( WidgetNameConfig (..)
  , widgetName
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

-- Import Core types if needed
-- import Core.Game (Game)

data WidgetNameConfig t = WidgetNameConfig
  { initialState :: Dynamic t Int -- Example field
  }

widgetName
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => WidgetNameConfig t
  -> m (Event t ()) -- Return type (e.g., clicks, or generic Event t ())
widgetName config = do
  elClass "div" "widget-name-container" $ do
    text "New Widget"

    -- Example: Button that returns an event
    (e, _) <- elAttr' "button" ("class" =: "btn-primary") $ text "Click Me"
    return $ domEvent Click e
```

## Best Practices Checklist

- [ ] **LANGUAGE Pragmas**: Only add non-default extensions (e.g. `FlexibleContexts`).
- [ ] **Imports**: Import `Reflex.Dom.Core` and `Control.Monad.Fix`.
- [ ] **Config Pattern**: Use a `Config` record for inputs if there's more than one argument.
- [ ] **Record Fields**: Use `DuplicateRecordFields` style (no prefixes).
- [ ] **Constraint correctness**: Use `DomBuilder t m`, `PostBuild t m`, etc., instead of concrete monads.
- [ ] **No `Promptly`**: Do NOT use `attachPromptlyDyn` or similar. Use `attach` or `tag` with `current`.
- [ ] **`widgetHold`**: Use `widgetHold` for dynamic switching of content.
