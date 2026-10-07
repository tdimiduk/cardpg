# Implementation Plan - Full Deck Migration to Master Card Database

This plan covers the migration of the remaining 34 actor decks (7 Player Characters, 27 Monsters) to reference syntax using the Master Card Database (`data/cards/master/`), following the successful completion of the foundations and pilot actors in `docs/notes/master-card-database-plan.md`.

---

## Current Status & Scope

- **Already Converted Pilots (5 actors)**:
  - PCs: `shield-fighter.yaml`, `squire.yaml`
  - Monsters: `bread_wolf.yaml`, `troglodyte.yaml`, `infernal_troglodyte.yaml`
- **Master Database Catalog (`data/cards/master/`)**:
  - Contains 388 deduplicated cards across `core.yaml`, `martial.yaml`, `arcane.yaml`, `monsters/beasts.yaml`, `monsters/humanoids.yaml`.
- **Remaining Target Actors (34 actors)**:
  - **7 Player Characters** (`data/cards/pc/`)
  - **27 Monsters** (`data/cards/monsters/`)

All 34 remaining files have been dry-run tested with `manage-cards rewrite` and confirmed to convert 100% cleanly (24–27 cards converted to references per file, 0 retained inline, 0 dangling IDs).

---

## Migration Plan

### Batch 1: Player Character Decks (7 Actors)

Convert remaining PC decks in `data/cards/pc/`:

- `berserker.yaml` (martial)
- `culorn.yaml` (martial/nature)
- `marina.yaml` (martial/skill)
- `stary.yaml` (hybrid)
- `swashbuckler.yaml` (martial finesse)
- `vallhach.yaml` (starter scenario hero)
- `wizard.yaml` (arcane spells)

**Command:**

```bash
for pc in berserker culorn marina stary swashbuckler vallhach wizard; do
  cabal run tools-hs:exe:manage-cards -- rewrite --catalog data/cards/master --actor data/cards/pc/${pc}.yaml
done
```

**Verification:**

- `cabal test core:test:core-test` (roundtrip test)
- `cabal test tools-hs:test:tools-hs-test` (integrity check)

---

### Batch 2: Natural Beasts & Animal Monsters (10 Actors)

Convert animal/beast monster decks in `data/cards/monsters/`:

- `ant_queen.yaml` & `ant_soldier.yaml`
- `basilisk.yaml`
- `bear.yaml`
- `cave_bat.yaml`
- `ice_screamer.yaml`
- `spark_dragon.yaml`
- `wasp_queen.yaml` & `wasp_soldier.yaml`
- `wolf.yaml` (starter scenario opponent)

**Command:**

```bash
for m in ant_queen ant_soldier basilisk bear cave_bat ice_screamer spark_dragon wasp_queen wasp_soldier wolf; do
  cabal run tools-hs:exe:manage-cards -- rewrite --catalog data/cards/master --actor data/cards/monsters/${m}.yaml
done
```

**Verification:**

- `cabal test core:test:core-test`
- `cabal test server:test:server-test` (starter scenario with converted `vallhach` and `wolf`)

---

### Batch 3: Sentient & Constructed Monsters (17 Actors)

Convert remaining humanoids, undead, constructs, and elemental monster decks in `data/cards/monsters/`:

- `cake_slicer.yaml`
- `crystal_shard.yaml`
- `evil_chef.yaml`
- `gazinia.yaml`
- `gingerbread_knight.yaml` & `gingerbread_soldier.yaml`
- `goblin.yaml`
- `lizard_warrior.yaml`
- `minotaur.yaml`
- `rainbow_incarnate.yaml`
- `sky_zombie.yaml` & `zombie.yaml`
- `stone_spirit.yaml`, `water_spirit.yaml`, `wind_spirit.yaml`
- `troll.yaml`
- `weakness_warrior.yaml`

**Command:**

```bash
cabal run tools-hs:exe:manage-cards -- rewrite --all --catalog data/cards/master
```

---

### Batch 4: Cleanup & Comprehensive Verification

1. **Remove Stale Reformatted Artifacts**:
   - Clean up any untracked or stale `*.yaml.reformatted` files created during prior roundtrip debugging:
     ```bash
     rm -f data/cards/pc/*.yaml.reformatted data/cards/monsters/*.yaml.reformatted
     ```

2. **Automated Test Suite**:

   ```bash
   cabal test all
   ```

   - `core-test`: verifies all 39 actor files roundtrip byte-for-byte.
   - `tools-hs-test`: verifies zero dangling references across all 39 actors against master catalog.
   - `server-test`: verifies scenario and actor loading with master cards.
   - `client-test`: verifies client frontend logic.

3. **Static Deck Generation Audit**:
   - Spot-check static deck rendering for converted PC and monster decks:
     ```bash
     cabal run client:exe:cardpg-static -- deck data/cards/pc/wizard.yaml --no-snapshot
     cabal run client:exe:cardpg-static -- deck data/cards/monsters/wolf.yaml --no-snapshot
     ```

4. **Linting**:
   ```bash
   ./scripts/lint
   ```
