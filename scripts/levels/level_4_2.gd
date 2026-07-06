extends "res://scripts/level.gd"
## Level 4-2 (PG-54) — meteor belt. Meteors rain from above at random
## intervals; drifting asteroid platforms (moving, per PG-54's decision)
## ferry the player over the voids; more aliens and a checkpoint. Ported
## from the JS reference (levels.js LEVEL_4_2), with the JS's static
## bridge platforms promoted to moving AnimatableBody2D platforms.
## 88 columns; ground segments 0-19, 25-48, 53-87 (5- and 4-wide voids).


func _init() -> void:
	sky_color = Color(0.02, 0.02, 0.06)
	tile_tint = Color(0.62, 0.64, 0.74)
	decor = "space"
	gravity_scale = 0.55
	meteors = true
	layout = "\n".join([
		".".repeat(40) + "CCC" + ".".repeat(45),
		".".repeat(39) + "BBBBB" + ".".repeat(44),
		"",
		".".repeat(20) + "CC" + ".".repeat(66),
		# moving platforms centered over each void (was static BBBB/BBB)
		".".repeat(22) + "M" + ".".repeat(27) + "M" + ".".repeat(37),
		"",
		"..P.....C.....A....." + "....." + "...K....C......A........" + "...." + "....C.......A.......C......F.......",
		"G".repeat(20) + ".".repeat(5) + "G".repeat(24) + ".".repeat(4) + "G".repeat(35),
	])
