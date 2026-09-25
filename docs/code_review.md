# CardPG Codebase Architecture & Quality Review

**Date:** 2026-09-09  
**Scope:** Complete repository (`core`, `api`, `server`, `client`, `reflex-atomic-css`, `tools-hs`, `tools`, `tests`, `docs`)

---

## 1. Executive Summary

CardPG is an ambitious, full-stack Haskell system with clean macro-architecture:

- **`core` (`cardpg-core`)**: Pure game engine with deterministic state transitions via a custom `GameM` monad.
- **`api` (`cardpg-api`)**: Strongly typed GADT communication protocol (`ApiRequest`) using `reflex-gadt-api`.
- **`server` (`cardpg-server`)**: Real-time WebSocket game server backed by PostgreSQL/Beam and Gargoyle.
- **`client` (`cardpg-client`)**: Reflex-DOM Functional Reactive Programming (FRP) web client with real-time multiplayer state synchronization.
- **`reflex-atomic-css`**: Native Haskell-defined styling DSL generating minimal atomic CSS at compile time without Node/Tailwind dependencies.

While the separation of concerns and pure monadic modeling are excellent, there are critical gaps in **persistence (game actions are never saved to PostgreSQL during play)**, **runtime exception safety (`error`, `read`, partial list functions)**, **JSaddle performance bottlenecks in `MapBoard`**, and **disconnected card rule mechanics**.

---

## 2. Key Strengths & Architectural Highlights

### 2.1 Pure Core / Effectful Shell Separation

- [`Core.Logic.Monad`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Monad.hs) defines:
  ```haskell
  newtype GameM g a = GameM { runGameM :: RWST GameEnv [GameEvent] ActorState (State g) a }
  ```
- Core logic is 100% pure, deterministic, and free of `IO`.
- Every state transition produces discrete [`GameEvent`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/State.hs#L198-L222) values (`CardDrawn`, `ActionPlanned`, `DefenseEnded`, etc.) via `tell`. This allows complete auditing and headless unit testing without mocks.

### 2.2 Type-Safe Network Protocol

- Client-server requests are modeled as a GADT [`Api.Request.ApiRequest`](file:///home/tdimiduk/cardpg/cardpg/api/src/Api/Request.hs#L18-L45). Each request constructor statically determines its return type (e.g. `Join :: Text -> ApiRequest (Either Text UUID)`).
- Role-based permissions are enforced at the server boundary in [`Server.ReflexConnection.checkPermission`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/ReflexConnection.hs#L220-L254), restricting players to their claimed actor while giving GMs full administrative privileges.

### 2.3 Expressive Card Rule & Rich Text DSLs

- [`Core.Rules`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules.hs) provides a typed AST for tabletop rules (`RuleGeneral`, `RuleTask`, `RuleTrigger`, `RuleOngoing`, `RulePassive`, `RuleNarrative`).
- [`Core.DSL`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/DSL.hs) and [`Core.RichText`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/RichText.hs) provide round-tripping text parsers and layout generators, ensuring authored markdown/YAML rules serialize cleanly and render safely.
- Boundary stripping, non-empty invariants (`NonEmptyText`), and adjacent text run merging prevent rendering deformities.

### 2.4 Compile-Time Atomic Styling (`reflex-atomic-css`)

- Replaces external Tailwind CSS with a native Haskell styling DSL ([`reflex-atomic-css`](file:///home/tdimiduk/cardpg/cardpg/reflex-atomic-css)).
- Eliminates heavy Node.js tooling during Haskell compilation.
- Leverages [Open Props](https://open-props.style/) custom properties for unified tokens (colors, sizing, shadows, transitions).

### 2.5 Multi-Tiered Verification

- **Core Unit & Property Tests**: QuickCheck instances ([`ArbitraryInstances.hs`](file:///home/tdimiduk/cardpg/cardpg/core/tests/ArbitraryInstances.hs)) and Tasty suites for parsing and state resolution.
- **FRP Widget Tests**: Headless testing of FRP widget logic using `reflex-test-host` ([`PlanningTest.hs`](file:///home/tdimiduk/cardpg/cardpg/client/tests/PlanningTest.hs)).
- **E2E Browser Tests**: Playwright integration testing scenarios, UI staging, movement, and chat ([`tests/e2e/game.spec.ts`](file:///home/tdimiduk/cardpg/cardpg/tests/e2e/game.spec.ts)).
- **Dev Workflow**: Automated hot-reloads and process supervision via `process-compose` and [`scripts/Watch.hs`](file:///home/tdimiduk/cardpg/cardpg/scripts/Watch.hs).

---

## 3. Findings & Technical Debt

### 🔴 High Severity

| ID      | Issue                                                         | Location                                                                                                                                                                                                                                                                                 | Impact                                                                                                                                                          |
| ------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **H-1** | **Gameplay State Is Never Persisted to DB**                   | [`Server.Session`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Session.hs#L61), [`Server.ReflexConnection`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/ReflexConnection.hs), [`Server.Dispatch`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Dispatch.hs) | `saveGame` is only called once at server boot. Moves, card plays, and phase changes only live in RAM. Server crash or restart wipes all player progress.        |
| **H-2** | **Runtime `error` Calls in Dispatch & Planning**              | [`Server.Dispatch:106`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Dispatch.hs#L106-L107), [`Planning.hs:232`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Planning.hs#L232)                                                                                      | `processCommand` throws `error` if `Join` or `SaveCustomCard` reach it; `endDefense` uses `fromMaybe (error ...)`. An unhandled error kills the server process. |
| **H-3** | **Unsafe `read` on External Environment Inputs**              | [`Server.Config:43,70`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Config.hs#L43), [`Frontend.Devel:61`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Devel.hs#L61)                                                                                                | Violates Coding Standards §1.2. Invalid `PORT`, `CARDPG_SEED`, or `JSADDLE_WARP_PORT` crashes the application at startup with uncatchable parse exceptions.     |
| **H-4** | **Spurious `ActionPlanned` Event Emitted on Status Addition** | [`Core.Logic.Status:55`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Status.hs#L55)                                                                                                                                                                                          | `addStatus` unconditionally emits `tell [ActionPlanned (PStandard (ActionStack card []))]` even when adding cards to deck or discard, polluting the event log.  |
| **H-5** | **Non-Atomic DB Upsert (TOCTOU Race Condition)**              | [`Server.DB:114-135`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/DB.hs#L114-L135), [`Server.DB:168-194`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/DB.hs#L168-L194)                                                                                               | `saveGame` and `saveCustomCard` do a `SELECT` followed by `INSERT` or `UPDATE` outside a transaction, risking race conditions under concurrent client requests. |

---

### 🟡 Medium Severity

| ID      | Issue                                            | Location                                                                                                                                                                                            | Impact                                                                                                                                                                |
| ------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **M-1** | **`eval` on Every Mouse Click in MapBoard**      | [`Frontend.Game.MapBoard:115-140`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Game/MapBoard.hs#L115-L140)                                                                              | Every click evaluates multi-line JS string via `eval (T.unlines jsLines)`. In dev mode (`jsaddle-warp`), this causes round-trip WebSocket latency on every click.     |
| **M-2** | **`unsafeCoerce` on DOM Raw Element**            | [`Frontend.Game.MapBoard:656,882`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Game/MapBoard.hs#L656)                                                                                   | Bypasses type safety to extract `JSVal` and bind DOM listeners manually instead of using idiomatic Reflex `domEvent Click`.                                           |
| **M-3** | **Rules AST Is Not Executed by Engine**          | [`Core.Card:51`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Card.hs#L51), [`Core.Logic.Combat:49`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Combat.hs#L49)                    | `CoreCard.rules` AST (`RuleTask`, `RuleTrigger`, `RuleOngoing`, `RulePassive`) is only rendered visually. Combat engine only evaluates hardcoded `attack` records.    |
| **M-4** | **Stringly-Typed Enums Violating Standard §1.1** | [`Core.State:179,215,220`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/State.hs#L179)                                                                                                         | `actorType` is `Text` ("PC", "Monster", "NPC") instead of a sum type `ActorType`. `StatusRemoved` uses `Text` for location. `ConsequenceRemoved` uses stringified ID. |
| **M-5** | **Untyped JSON Value in API Boundary**           | [`Api.Request:44`](file:///home/tdimiduk/cardpg/cardpg/api/src/Api/Request.hs#L44), [`Server.ReflexConnection:291`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/ReflexConnection.hs#L291) | `SaveCustomCard` transmits raw `Aeson.Value` instead of `CustomCard`, bypassing compile-time serialization safety at the API boundary.                                |
| **M-6** | **Stale Author Attribute on Custom Card Save**   | [`Server.ReflexConnection:294`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/ReflexConnection.hs#L294)                                                                                     | Uses the initial `client.clientName` from socket connection rather than the current name from `ServerState.clients`.                                                  |

---

### 🟢 Low Severity / Code Hygiene

| ID      | Issue                                             | Location                                                                                                                                                                                                                                                                          | Impact                                                                                                                                         |
| ------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **L-1** | **Partial Functions (`head`, `!!`) in Logic/App** | [`Frontend.App:372`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/App.hs#L372), [`Core.Logic.Status:117`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Status.hs#L117), [`tools-hs:211-219`](file:///home/tdimiduk/cardpg/cardpg/tools-hs/src/Main.hs#L211) | `head (Map.elems matches)`, `candidates !! idx`, and `cells !! 1..9` in `tools-hs` can crash if collections are empty or tables are malformed. |
| **L-2** | **Monolithic Module `MapBoard.hs` (920 lines)**   | [`Frontend.Game.MapBoard`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Game/MapBoard.hs)                                                                                                                                                                              | Combines grid rendering, rank-based arena, ghost tokens, turn indicators, and JSaddle bindings in a single massive file.                       |
| **L-3** | **Unlawful `Eq` Instance for `WsMessage`**        | [`Api.Reflex:78-81`](file:///home/tdimiduk/cardpg/cardpg/api/src/Api/Reflex.hs#L78-L81)                                                                                                                                                                                           | `(WsMsgResponse _) == (WsMsgResponse _) = False` violates reflexivity (`x == x`).                                                              |
| **L-4** | **Dummy `undefined` in Test Records**             | [`Core/LogicTest.hs:39,96,261,277`](file:///home/tdimiduk/cardpg/cardpg/core/tests/Core/LogicTest.hs#L39)                                                                                                                                                                         | `fatigueCardTemplate = undefined` causes crashes if tests evaluate fatigue logic.                                                              |

---

## 4. Prioritized Action Plan & Deep Dive Targets

### Phase 1: Total & Safe Haskell (Partial Functions & Safety)

1. Replace `read` with `readMaybe` in [`Server.Config`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Config.hs) and [`Frontend.Devel`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Devel.hs).
2. Eliminate `error` in [`Server.Dispatch`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/Dispatch.hs) and [`Core.Logic.Planning.endDefense`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Planning.hs#L232).
3. Replace partial `head` in [`Frontend.App:372`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/App.hs#L372) with `listToMaybe`.
4. Replace partial `!!` in [`tools-hs`](file:///home/tdimiduk/cardpg/cardpg/tools-hs/src/Main.hs) and safe index lookup in [`Status.hs`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Status.hs).
5. Fix spurious `ActionPlanned` event in [`Core.Logic.Status.addStatus`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic/Status.hs#L55).

### Phase 2: Game State Persistence Architecture

1. Introduce state persistence in [`Server.ReflexConnection`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/ReflexConnection.hs) on round conclusion and command commits.
2. Upgrade Beam queries in [`Server.DB`](file:///home/tdimiduk/cardpg/cardpg/server/src/Server/DB.hs) to PostgreSQL `ON CONFLICT DO UPDATE`.
3. Add automated persistence recovery integration tests.

### Phase 3: Frontend MapBoard & JSaddle Optimization

1. Remove `eval (T.unlines jsLines)` in [`Frontend.Game.MapBoard`](file:///home/tdimiduk/cardpg/cardpg/client/src/Frontend/Game/MapBoard.hs) by calculating click coordinates using standard Reflex mouse events or evaluating the script once on page load.
2. Replace `unsafeCoerce` with safe Reflex event hooks (`domEvent Click`).
3. Split `MapBoard.hs` into `MapBoard.Grid`, `MapBoard.Rank`, and `MapBoard.Token`.

### Phase 4: Rules Engine Execution

1. Connect the parsed rule AST (`RuleTask`, `RuleTrigger`, `RuleOngoing`, `RulePassive`) in [`Core.Rules`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Rules.hs) into [`Core.Logic`](file:///home/tdimiduk/cardpg/cardpg/core/src/Core/Logic).
2. Allow equipment, traits, and consequences to apply passive modifiers to attack strength, defense, and resilience dynamically.
