# Platform Game

A 2D platformer built with Godot 4 (GL Compatibility renderer). Implements the
Jira project **PG**: player movement with coyote time, variable jump height and
a double jump, stompable patrolling enemies, spikes and fall hazards, coins,
checkpoints, twelve levels across four worlds, World 3 cave hazards (lava, bats,
falling stalactites, crumbling platforms), World 4 space mechanics (low gravity,
alien enemies, falling meteors, drifting carry platforms), sound effects,
parallax backgrounds, avatar selection, a pause menu, and full menu/game flow.

## Controls

| Action | Keys |
|---|---|
| Move | A / D or Left / Right |
| Jump | Space / W / Up (hold for higher jump, press again mid-air to double jump) |
| Pause | Escape (Resume / Restart / Quit to menu) |

## Project structure

```
assets/    sprites + sfx (generated placeholders) + tileset.tres
scenes/    reusable scenes: player, enemy, bat, alien, coin, spikes, lava,
           stalactite, crumbling, meteor, moving_platform, flag, checkpoint,
           HUD, menus
scripts/   GDScript; scripts/levels/ holds the per-level layout scripts
levels/    the twelve playable level scenes (worlds 1-4)
```

Levels are grouped into worlds in `GameManager.WORLDS`; the HUD shows the
current level as world-stage (1-1 ... 4-3). Worlds reuse the same tileset with
color tints and swap the sky backdrop (`decor`: clouds / crystal cave / space
starfield). World 4 runs at `gravity_scale` 0.55 for floaty jumps and spawns a
meteor shower on its later stages. Worlds 1 and 2 scatter purely-decorative
ground scenery (`ground_decor`: grassland / forest) behind the tilemap via
`scripts/ground_decor.gd`, placed deterministically over solid ground. The
player's avatar (3 choices on the main menu) persists for the session.

## How levels work

Levels are defined as ASCII layouts in `scripts/levels/level_*.gd` and built at
runtime by `scripts/level.gd` onto a `TileMapLayer`. Legend: `G` grass ground
(dirt auto-fills below), `D` dirt, `B` block/platform, `L` lava, `V` bat,
`T` stalactite, `X` crumbling platform, `A` alien, `M` moving platform,
`P` player start,
`C` coin, `E` enemy, `S` spikes, `K` checkpoint, `F` goal flag.

`scripts/game_manager.gd` is autoloaded and owns coins, lives, checkpoints,
and scene transitions. The HUD updates through its `coins_changed` /
`lives_changed` signals.

## Multiplayer (LAN ghost-race)

An optional LAN ghost-race, reachable from the main menu's **Multiplayer**
button (`scripts/net.gd`, autoloaded as `Net`). One player hosts an ENet
server; others join by IP. Every client runs its own full local simulation and
broadcasts its state at 15 Hz — remote players appear as **ghosts** (interpolated
~100 ms in the past, extrapolated on packet gaps; see `scripts/ghost_interp.gd`,
ported from the JS platformer's `ghosts.js`). Ghosts have no collision, so
single-player behaviour is unchanged and everything runs only when `Net.active`.
QR-code join is out of scope here (tracked separately). The host's IP is shown on
its lobby screen; joiners type it in.

## Running

Open the project in Godot 4.x and press F5, or:

```
godot --path . 
```

## Tests

A headless gameplay regression test covers coin pickup, the stomp
mechanic, and spike death:

```
godot --headless --path . res://tests/gameplay_test.tscn
```

It prints PASS/FAIL per check and exits non-zero on failure (48 checks,
including the ported ghost-interpolation math).

Networking needs two processes, so it has its own smoke test — run a host and a
client, each writes a one-line result to `user://net_<role>.txt`:

```
godot --headless --path . res://tests/net_smoke.tscn -- host
godot --headless --path . res://tests/net_smoke.tscn -- client
```

Expected: host `peers=2 got_snapshot=true`, client `connected=true max_roster=2`.
