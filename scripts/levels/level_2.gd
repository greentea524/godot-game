extends "res://scripts/level.gd"
## Level 2 — enemies, gaps between platforms, more coins, and a
## mid-level checkpoint (PG-12). Block fences keep enemies away from
## the checkpoint and the gap landing zones.


func _init() -> void:
	# 80 columns. Ground segments 0-17, 21-37, 41-59, 63-79 (gaps between).
	layout = "\n".join([
		".".repeat(31) + "CC" + ".".repeat(47),                # bonus coins, high platform
		".".repeat(30) + "BBBB" + ".".repeat(46),              # high platform
		"",
		# coins over the low platforms
		".........." + "....CC...C" + ".........." + ".........." + ".....CC..." + ".........." + ".C........" + "..........",
		# low platforms (incl. spans over the gaps)
		".........." + "...BBBB.BB" + "B........." + ".........." + "....BBBB.." + ".........." + "BBB......." + "..........",
		"",
		# ground row: player, coins, enemies (E), checkpoint (K), fences (B), flag (F)
		"..P.....CC" + "C........." + "........E." + "...CCC...." + "..K...B..." + "E....CC..." + "......B.E." + "..C...F...",
		"G".repeat(18) + "..." + "G".repeat(17) + "..." + "G".repeat(19) + "..." + "G".repeat(17),
	])
