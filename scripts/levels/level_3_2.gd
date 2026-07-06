extends "res://scripts/level.gd"
## Level 3-2 (PG-53) — deeper cave. Wider lava (with a stepping stone),
## more bats, falling stalactites, and a mid-level checkpoint. Ported
## from the JS reference (levels.js LEVEL_3_2). 80 columns; ground
## segments 0-19, 24-45, 49-79 with lava pits 4 and 3 wide.


func _init() -> void:
	sky_color = Color(0.05, 0.03, 0.08)
	tile_tint = Color(0.46, 0.4, 0.56)
	decor = "cave"
	layout = "\n".join([
		".".repeat(34) + "CCC" + ".".repeat(43),
		".".repeat(33) + "BBBBB" + ".".repeat(42),
		".".repeat(30) + "T" + ".".repeat(24) + "T" + ".".repeat(10) + "T" + ".".repeat(13),
		".".repeat(21) + "CC" + ".".repeat(57),
		".".repeat(21) + "BB" + ".".repeat(57),
		".".repeat(14) + "V" + ".".repeat(30) + "V" + ".".repeat(34),
		"..P.....C....E......" + "...." + ".....C....K.....E....." + "..." + ".....C.......E........F........",
		"G".repeat(20) + "LLLL" + "G".repeat(22) + "LLL" + "G".repeat(31),
	])
