extends "res://scripts/level.gd"
## Level 3-3 (PG-53) — Underworld finale. Lava everywhere, a swarm of
## bats, stalactites, and a crumbling-platform bridge over a wide lava
## pit; two checkpoints. Ported from the JS reference (levels.js
## LEVEL_3_3). 96 columns; ground segments 0-15, 19-34, 40-59, 63-95
## with lava 3/5/3 wide (the 5-wide pit crossed by crumbling platforms).


func _init() -> void:
	sky_color = Color(0.03, 0.02, 0.05)
	tile_tint = Color(0.5, 0.36, 0.42)
	decor = "cave"
	layout = "\n".join([
		".".repeat(44) + "CCC" + ".".repeat(49),
		".".repeat(43) + "BBBBB" + ".".repeat(48),
		".".repeat(24) + "T" + ".".repeat(21) + "T" + ".".repeat(23) + "T" + ".".repeat(14) + "T" + ".".repeat(10),
		".".repeat(20) + "CC" + ".".repeat(74),
		".".repeat(20) + "BB" + ".".repeat(74),
		".".repeat(35) + "XXXXX" + ".".repeat(8) + "V" + ".".repeat(20) + "V" + ".".repeat(26),
		"..P....C....E..." + "..." + "...K....C....E.." + "....." + ".....C......E......." + "..." + "....K.....C.......E......F.......",
		"G".repeat(16) + "LLL" + "G".repeat(16) + "LLLLL" + "G".repeat(20) + "LLL" + "G".repeat(33),
	])
