extends "res://scripts/level.gd"

func _init() -> void:
	decor = "ice"
	sky_color = Color(0.72, 0.85, 0.95)
	tile_tint = Color(0.78, 0.88, 0.96)
	ice = true
	layout = """
............................CCC.................................
...........................BBBBB................................

..................CC......................CC....................
.................BBBB....................BBBB...................

..P.....C...C.C...............Y...........C.C......F....
IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
"""
