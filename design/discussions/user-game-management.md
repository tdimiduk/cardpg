# User and Game Management Design

**Status:** Draft
**Date:** 2025-12-19

## Context
We are currently in early playtesting. The current system treats every connection as a new "Anonymous" client until they send a `Join` message. This "upgrade" logic complicates the state machine and has caused bugs. We want to move towards a system that supports:
1.  **Ease of Use:** Low friction for playtesters (ideally link-based or minimal setup).
2.  **Persistence:** Users should be able to reconnect and regain their state (Control of their Actor).
3.  **Ownership:** A concept of a "Player" who owns one or more "Actors" (PCs).
4.  **Campaign Play:** Persistent state across sessions.
5.  **GM-Optionality:** Support both GM-led and GM-less (AI-driven) flows.

## Current State Analysis
- **Backend:** `Connection.hs` initializes a `Client` with a random UUID. It listens for a `Join` message to potentially replace this ID with a stored one.
- **Frontend:** Stores `clientId` in `localStorage`. On connect, sends `Join` with this ID.
- **Issues:** The transition from "Connecting" (random ID) to "Joined" (restored ID) creates a race condition or complexity in the frontend state management (`useState` vs `useRef` for ID). If the `Join` message is delayed or lost, the user remains "Anonymous" and creates a "ghost" client on the server.

## Proposed Design (Phase 1: Stabilization & Simplicity)

### 1. Connection as Identity
Instead of "Connect then Join", we should treat the **Handshake** or the very first message as the authoritative identity claim.
*   **Protocol Change:** The WebSocket connection URL could include the `clientId` if known (e.g., `ws://host/api?clientId=...`).
*   **Server Logic:** If `clientId` is provided in query params, immediately attempt to look up or reserve that ID. If not, generate a new one *and return it immediately*.
*   **Simplification:** Remove the "Anonymous" state. A client is always identified. If they are new, they are a "New User".

### 2. Player vs. Actor
Currently, the frontend allows selecting an `activeActorId`. We should formalize this on the backend.
*   **Player:** A `Client` connected to the server.
*   **Actor (PC):** An entity in the `GameState`.
*   **Ownership:** The `GameState` should track `Map ActorId (Maybe ClientId)`.
    *   **Unclaimed:** Available for any user to "Grab" (or for AI).
    *   **Claimed:** Only the owner `ClientId` can issue `Command`s for this Actor.
    *   **GM Override:** A GM role (special `ClientId` or flag) can command any Actor.

**User Story:**
> Alice opens the game. She has no ID. Server assigns `User-123`.
> Alice sees a list of "Available Characters". She picks "Valeros".
> Server updates `Ownership`: Valeros -> `User-123`.
> Alice refreshes. Browser sends `User-123`. Server recognizes her.
> Server knows `User-123` owns Valeros. UI automatically selects Valeros.

### 3. Session & Campaign (Future)
To support Campaign play, we need a scope larger than `GameState`.
*   **Campaign:** A persistent database record containing "World State" and "Party State".
*   **Session:** An active instance of a Campaign.
*   **Invite Links:** `cardpg.app/join/campaign-abc-xyz`.
    *   New user clicks link -> Generated ID -> Added to Campaign "Allow List".

## Implementation Plan

### Step 1: Fix Connection Flow (Immediate)
*   **Objective:** Eliminate "Anonymous" ghosts and potential race conditions.
*   **Change:**
    *   Modify `WebSocketContext` to send `clientId` in the query string or as the *immediate* first packet before anything else.
    *   Server `Connection.hs`: Do not start the main loop until Identity is established.
    *   Persist `clientId` strictly in `localStorage`.

### Step 2: Basic Ownership (Next)
*   **Objective:** Prevent players from moving each other's tokens accidentaly.
*   **Change:**
    *   Add `ownerId :: Maybe UUID` to `ActorState` (or a separate lookup in `GameState`).
    *   Add `ClaimActor` command.
    *   Validate `Command`s against ownership in `Dispatch.hs`.

### Step 3: GM / Spectator Modes (Later)
*   Add a "Spectator" flag to clients who don't want to play but want to watch.
*   Add a "GM" flag for the host.

## Open Questions for Discussion
- **Game Master:** How do we designate the GM? First person to join? A specific admin password/token?
- **AI Actors:** Do we treat AI as a "Bot Client" or just server-side logic? (Likely server-side logic triggered by game phases).
- **Multiple Characters:** Can one player own multiple actors? (Design above supports this: One Player -> Many Actors).

