---
description: Switch context to TypeScript/React frontend development
---

# Context: Frontend VTT

- **Directory**: `vtt-react`
- **Stack**: React, Vite, Tailwind CSS, Zod
- **Build**: `npm run dev` (local), `npm run build` (prod)
- **Testing**: `npm test`
- **Codegen**:
  - **Types**: `npm run gen:types` (Generates `src/generated/types.ts` & `schemas.ts` from Haskell)
  - **Data**: Run `uv run run_pipeline.py` in `../tools/` (Generates `src/data/generated_cards.json`)
- **WARNING**: DO NOT manually edit `src/generated/*` or `src/data/generated_cards.json`. They are build artifacts.
