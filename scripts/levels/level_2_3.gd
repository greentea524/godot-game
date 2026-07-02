extends "res://scripts/level.gd"
## Level 2-3 (PG-34) — World 2 finale and the hardest level: longest
## run, three spike fields, five enemies, four gaps with tight
## stepping-stone chains or double jumps, and two checkpoints.
## Completing it triggers the You Win screen (it is the last level in
## GameManager.WORLDS).


func _init() -> void:
	sky_color = Color(0.13, 0.11, 0.2)
	tile_tint = Color(0.68, 0.65, 0.9)
	cloud_tint = Color(0.55, 0.52, 0.7)
	# 112 columns. Ground segments 0-11, 20-33, 40-55, 64-79, 87-111
	# (gaps of 8, 6, 8 and 7).
	layout = "\n".join([
		".".repeat(21) + "CC" + ".".repeat(89),               # bonus coins, high platform
		".".repeat(20) + "BBBB" + ".".repeat(88),             # high platform
		"",
		# coins over the stepping stones and platforms
		".........." + "....C..C.." + ".........." + "......CC.." + ".........." + ".........C" + "C....CC..." + ".........." + "..CC......" + ".........." + ".........." + "..",
		# stepping stones over each gap + mid platforms
		".........." + "....BB.BB." + ".........." + "......BB.." + ".........." + ".........B" + "B....BBB.." + ".........." + "..BB......" + ".........." + ".........." + "..",
		"",
		# ground row: player, spikes (S), checkpoints (K), enemies (E)
		# behind fences (B), flag (F) guarded by the last enemies
		"..P......." + ".........." + "....SSSS.." + ".........." + ".K..B..E.." + ".E........" + "........SS" + "S..B.E...." + "........K." + "..SSS..B.." + ".E....E.F." + "..",
		"G".repeat(12) + ".".repeat(8) + "G".repeat(14) + ".".repeat(6) + "G".repeat(16) + ".".repeat(8) + "G".repeat(16) + ".".repeat(7) + "G".repeat(25),
	])
