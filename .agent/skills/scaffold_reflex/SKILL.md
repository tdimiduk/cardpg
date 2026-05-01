---
name: scaffold_reflex
description: Create a new Reflex widget module following project best practices
---

# Skill: scaffold_reflex

This skill provides a standardized way to create new Reflex UI widgets in the `client-reflex` project. It ensures adherence to best practices including the atomic CSS system and proper widget signatures.

## Instructions

When creating a new UI component, follow these steps:

1.  **Determine Module Path**: Based on the component's purpose (e.g., `Frontend.Game.MyWidget`).
2.  **Create File**: Create the file at the corresponding path (e.g., `client-reflex/src/Frontend/Game/MyWidget.hs`).
3.  **Apply Template**: Use the following template, replacing `ModuleName` and `WidgetName` appropriately.

### Template

```haskell
module Frontend.Game.ModuleName
  ( WidgetNameConfig (..)
  , widgetName
  ) where

import Control.Monad.Fix (MonadFix)
import Reflex.Dom.Core

-- Import styling system
import Frontend.Style.Common (Style, componentS, divS)
import Frontend.Style.DSL qualified as S

-- Import Core types if needed
-- import Core.State (ActorState)

data WidgetNameConfig t = WidgetNameConfig
  { initialState :: Dynamic t Int -- Example field
  }

-- | Style for the widget container
widgetContainer :: Style
widgetContainer = S.flexCol . S.gap2 . S.p4 . S.bgSlate800 . S.roundedXl

widgetName
  :: ( DomBuilder t m
     , PostBuild t m
     , MonadHold t m
     , MonadFix m
     )
  => WidgetNameConfig t
  -> m (Event t ()) -- Return type
widgetName config = componentS "widget-name" widgetContainer $ do
  divS (S.fontBold . S.textSlate200) $ text "New Widget"

  -- Example: Button that returns an event
  (e, _) <- elAttr' "button" ("class" =: "btn-primary") $ text "Click Me"
  return $ domEvent Click e
```

## Best Practices Checklist

- [ ] **Imports**: Import `Reflex.Dom.Core`, `Frontend.Style.Common`, and `Frontend.Style.DSL qualified as S`.
- [ ] **Styling**: Use `divS`, `elS`, or `componentS` with composed styles — **never** raw `elClass` with string class names.
- [ ] **Config Pattern**: Use a `Config` record for inputs if there's more than one argument.
- [ ] **Record Fields**: Use `DuplicateRecordFields` style (no prefixes).
- [ ] **Constraint correctness**: Use `DomBuilder t m`, `PostBuild t m`, etc., instead of concrete monads.
- [ ] **No `Promptly`**: Do NOT use `attachPromptlyDyn` or similar. Use `attach` or `tag` with `current`.
- [ ] **`widgetHold`**: Use `widgetHold` for dynamic switching of content.
- [ ] **Test IDs**: Use `componentS "descriptive-name"` for top-level widget containers.
- [ ] **Named styles**: Extract reusable style definitions (e.g., `widgetContainer :: Style`) rather than inlining long chains.
- [ ] **Module registration**: Add the new module to `exposed-modules` in `client-reflex.cabal`.
