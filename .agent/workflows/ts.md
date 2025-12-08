---
description: Switch context to TypeScript/React frontend development
---

# Context: Frontend VTT

- **Directory**: `vtt-react`
- **Stack**: React, Vite, Tailwind CSS, Zod
- **Build**: `just dev` (local), `just build` (prod)
- **Quality**: `just lint-frontend` (lint), `just check-types` (typecheck), `just test` (test)
- **Codegen**:
  - **Types**: `just gen-types` (Generates `src/generated/types.ts` & `schemas.ts` from Haskell)
  - **Data**: `just card-data` (Generates `src/data/generated_cards.json`)
- **WARNING**: DO NOT manually edit `src/generated/*` or `src/data/generated_cards.json`. They are build artifacts.
