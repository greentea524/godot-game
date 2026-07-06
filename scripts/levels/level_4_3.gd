extends "res://scripts/level.gd"
## Level 4-3 (PG-54) — ultimate finale. Every Space mechanic together:
## low gravity, drifting asteroid platforms, meteors, and aliens across
## a long run with two checkpoints. Last level, so the goal triggers the
## You-Win screen. Ported from the JS reference (levels.js LEVEL_4_3),
## with the static bridge platforms promoted to moving platforms.
## 108 columns; ground segments 0-15, 20-43, 49-76, 81-107 (voids 4/5/4).


func _init() -> void:
	sky_color = Color(0.03, 0.01, 0.08)
	tile_tint = Color(0.6, 0.55, 0.72)
	decor = "space"
	gravity_scale = 0.55
	meteors = true
	layout = "\n".join([
		".".repeat(52) + "CCC" + ".".repeat(53),
		".".repeat(51) + "BBBBB" + ".".repeat(52),
		"",
		".".repeat(30) + "CCC" + ".".repeat(75),
		# moving platforms centered over each of the three voids
		".".repeat(17) + "M" + ".".repeat(28) + "M" + ".".repeat(31) + "M" + ".".repeat(29),
		"",
		"..P....C....A..." + "...." + "...K...C.....A.......C.." + "....." + "....C......A........C......." + "...." + "...K....C......A......F....",
		"G".repeat(16) + ".".repeat(4) + "G".repeat(24) + ".".repeat(5) + "G".repeat(28) + ".".repeat(4) + "G".repeat(27),
	])
