extends "res://scripts/level.gd"
## Level 3-1 (PG-53) — World 3 Underworld/Cave intro. Dark cave theme,
## lava pools to jump, walker enemies and patrolling bats. Ported from
## the JS reference (levels.js LEVEL_3_1). 64 columns; ground segments
## 0-15, 19-38, 42-63 with two 3-wide lava pits.


func _init() -> void:
	sky_color = Color(0.05, 0.03, 0.08)
	tile_tint = Color(0.46, 0.4, 0.56)
	decor = "cave"
	layout = "\n".join([
		".".repeat(28) + "CCC" + ".".repeat(33),
		".".repeat(27) + "BBBBB" + ".".repeat(32),
		"",
		".".repeat(22) + "CC" + ".".repeat(18) + "CC" + ".".repeat(20),
		".".repeat(21) + "BBBB" + ".".repeat(16) + "BBBB" + ".".repeat(19),
		".".repeat(10) + "V" + ".".repeat(25) + "V" + ".".repeat(27),
		"..P....C...E...." + "..." + ".....C....E......C.." + "..." + "....C.......C....F....",
		"G".repeat(16) + "LLL" + "G".repeat(20) + "LLL" + "G".repeat(22),
	])
