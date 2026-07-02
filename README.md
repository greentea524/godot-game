# Platform Game

A 2D platformer built with Godot 4 (GL Compatibility renderer). Implements the
Jira project **PG**: player movement with coyote time, variable jump height and
a double jump, stompable patrolling enemies, spikes and fall hazards, coins,
checkpoints, six levels across two worlds, sound effects, parallax cloud
backgrounds, avatar selection, a pause menu, and full menu/game flow.

## Controls

| Action | Keys |
|---|---|
| Move | A / D or Left / Right |
| Jump | Space / W / Up (hold for higher jump, press again mid-air to double jump) |
| Pause | Escape (Resume / Restart / Quit to menu) |

## Project structure

```
assets/    sprites + sfx (generated placeholders) + tileset.tres
scenes/    reusable scenes: player, enemy, coin, spikes, flag, checkpoint, HUD, menus
scripts/   GDScript; scripts/levels/ holds the per-level layout scripts
levels/    the six playable level scenes (worlds 1 and 2)
```

Levels are grouped into worlds in `GameManager.WORLDS`; the HUD shows the
current level as world-stage (1-1 ... 2-3). World 2 levels reuse the same
tileset with color tints for a darker theme. The player's avatar (3 choices
on the main menu) persists for the session.

## How levels work

Levels are defined as ASCII layouts in `scripts/levels/level_*.gd` and built at
runtime by `scripts/level.gd` onto a `TileMapLayer`. Legend: `G` grass ground
(dirt auto-fills below), `D` dirt, `B` block/platform, `P` player start,
`C` coin, `E` enemy, `S` spikes, `K` checkpoint, `F` goal flag.

`scripts/game_manager.gd` is autoloaded and owns coins, lives, checkpoints,
and scene transitions. The HUD updates through its `coins_changed` /
`lives_changed` signals.

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

It prints PASS/FAIL per check and exits non-zero on failure.
