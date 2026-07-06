extends "res://scripts/level.gd"
## Level 3 — final challenge (PG-13). Spikes, more enemies, wider gaps
## with single-tile stepping stones, and a longer run to the flag.


func _init() -> void:
	# 96 columns. Ground segments 0-13, 18-29, 35-49, 54-69, 76-95.
	ground_decor = "grassland"
	layout = "\n".join([
		# coins over stepping stones and floating over the third gap
		".........." + ".....CC..." + ".........." + "..C......." + ".........." + ".CC......." + ".........." + "..CC......" + ".........." + "......",
		# stepping stones over the gaps
		".........." + ".....BB..." + ".........." + "..B......." + ".........." + ".........." + ".........." + "..BB......" + ".........." + "......",
		"",
		# ground row: spikes (S), enemies (E) behind block fences (B), checkpoint (K), flag (F)
		"..P......." + ".........." + "..SSS..C.." + "......K..C" + "B.E...E..." + "........SS" + "S.C.SS...." + ".........." + "B.E..CC.E." + "...F..",
		"G".repeat(14) + "...." + "G".repeat(12) + "....." + "G".repeat(15) + "...." + "G".repeat(16) + "......" + "G".repeat(20),
	])
