extends "res://scripts/level.gd"
## Level 1 — tutorial. Flat ground, two gentle platform steps, coins,
## a goal flag. No enemies, no hazards (PG-11).


func _init() -> void:
	layout = "\n".join([
		".".repeat(29) + "CCC" + ".".repeat(32),                       # coins on high platform
		".".repeat(28) + "BBBBB" + ".".repeat(31),                     # high platform
		"",
		".".repeat(23) + "CC" + ".".repeat(21) + "CC" + ".".repeat(16),# coins on low platforms
		".".repeat(22) + "BBBB" + ".".repeat(19) + "BBBB" + ".".repeat(15),
		"",
		"..P" + ".".repeat(8) + "C.C.C" + ".".repeat(21) + "C.C" + ".".repeat(14) + "CC" + ".".repeat(4) + "F" + ".".repeat(3),
		"G".repeat(64),
	])
