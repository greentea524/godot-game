extends "res://scripts/level.gd"
## Level 2-2 (PG-33) — World 2 mid-stage. More enemies, spikes,
## tighter jumps including a 7-wide and an 8-wide gap that reward the
## double jump, and a mid-level checkpoint.


func _init() -> void:
	sky_color = Color(0.18, 0.16, 0.28)
	tile_tint = Color(0.72, 0.7, 0.95)
	cloud_tint = Color(0.62, 0.6, 0.78)
	# 90 columns. Ground segments 0-13, 21-39, 45-64, 73-89
	# (gaps of 7, 5 and 8).
	layout = "\n".join([
		".".repeat(30) + "...CC....." + ".".repeat(50),       # coins on high platform
		".".repeat(30) + "..BBBB...." + ".".repeat(50),       # high platform
		"",
		# coins over stones and platforms
		".........." + ".......C.." + ".........." + ".CC......." + ".........." + "......CC.." + ".......CC." + ".........." + "..........",
		# single stone over gap 1, platforms, stones over gap 3
		".........." + ".......B.." + ".........." + "BBBB......" + ".........." + ".....BBBB." + ".......BB." + ".........." + "..........",
		"",
		# ground row: spikes (S), enemies (E) behind fences (B),
		# checkpoint (K), coins, flag (F)
		"..P......." + ".........." + ".....SSS.B" + "...E...E.." + "......K..B" + "....E....E" + "..CC......" + "......SS.." + "B.E...F...",
		"G".repeat(14) + ".".repeat(7) + "G".repeat(19) + ".".repeat(5) + "G".repeat(20) + ".".repeat(8) + "G".repeat(17),
	])
