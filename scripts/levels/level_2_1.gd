extends "res://scripts/level.gd"
## Level 2-1 (PG-32) — World 2 opener. New dusk theme via tints,
## platforms at varied heights, two enemies, and a 6-wide gap that
## teaches the double jump (with an optional stepping-stone path).


func _init() -> void:
	sky_color = Color(0.18, 0.16, 0.28)
	tile_tint = Color(0.72, 0.7, 0.95)
	cloud_tint = Color(0.62, 0.6, 0.78)
	# 80 columns. Ground segments 0-19, 24-47, 54-79 (gaps of 4 and 6).
	ground_decor = "forest"
	layout = "\n".join([
		".".repeat(35) + "CC" + ".".repeat(43),               # coins on high platform
		".".repeat(34) + "BBBB" + ".".repeat(42),             # high platform
		"",
		# coins over the low platforms and stepping stone
		".........." + "...CC....." + ".........." + "CC........" + ".........." + "CC........" + ".....CC..." + "..........",
		# low platforms; stone over the 6-wide double-jump gap
		".........." + "..BBBB...." + ".........B" + "BBB......." + ".........." + "BB........" + "....BBBB.." + "..........",
		"",
		# ground row: player, coins, enemies (E) behind a fence (B), flag (F)
		"..P.....CC" + "C........." + ".......B.." + "..E...CC.." + "E........." + "........CC" + "C........." + ".....F....",
		"G".repeat(20) + "...." + "G".repeat(24) + "......" + "G".repeat(26),
	])
