extends "res://scripts/level.gd"
## Level 4-1 (PG-54) — World 4 Space intro. Low gravity makes jumps
## floaty; alien enemies patrol the station floor; void gaps replace
## pits. Ported from the JS reference (levels.js LEVEL_4_1). 72 columns;
## ground segments 0-23, 28-49, 53-71 (4- and 3-wide voids).


func _init() -> void:
	sky_color = Color(0.02, 0.02, 0.06)
	tile_tint = Color(0.62, 0.64, 0.74)
	decor = "space"
	gravity_scale = 0.55
	layout = "\n".join([
		".".repeat(30) + "CCC" + ".".repeat(39),
		".".repeat(29) + "BBBBB" + ".".repeat(38),
		"",
		".".repeat(24) + "CC" + ".".repeat(46),
		".".repeat(24) + "BBB" + ".".repeat(23) + "BBB" + ".".repeat(19),
		"",
		"..P......C.....A........" + "...." + "....C......A........." + "..." + "...C.....A....F....",
		"G".repeat(24) + ".".repeat(4) + "G".repeat(22) + ".".repeat(3) + "G".repeat(19),
	])
