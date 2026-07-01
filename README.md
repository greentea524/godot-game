# Platform Game

A 2D platformer built with Godot 4 (GL Compatibility renderer). Implements the
Jira project **PG**: player movement with coyote time and variable jump height,
stompable patrolling enemies, spikes and fall hazards, coins, checkpoints,
three levels, and full menu/game flow.

## Controls

| Action | Keys |
|---|---|
| Move | A / D or Left / Right |
| Jump | Space / W / Up (hold for higher jump) |

## Project structure

```
assets/    sprites (generated placeholder pixel art) + tileset.tres
scenes/    reusable scenes: player, enemy, coin, spikes, flag, checkpoint, HUD, menus
scripts/   GDScript; scripts/levels/ holds the per-level layout scripts
levels/    the three playable level scenes
```

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
