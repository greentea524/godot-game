extends Node2D
## Procedurally generated space decorations (planets, stars, debris) for World 4.

var kind := "stars"
var layer_width := 1000.0
var layer_height := 800.0

func _ready() -> void:
	# Use a stable seed for consistent looking backgrounds
	seed(hash(kind))
	queue_redraw()

func _draw() -> void:
	if kind == "stars":
		_draw_stars()
	elif kind == "planets":
		_draw_planets()
	elif kind == "debris":
		_draw_debris()

func _draw_stars() -> void:
	for i in range(250):
		var pos = Vector2(randf() * layer_width, randf() * layer_height)
		draw_circle(pos, randf_range(0.5, 1.5), Color(1, 1, 1, randf_range(0.3, 0.9)))

func _draw_planets() -> void:
	for i in range(6):
		var pos = Vector2(randf() * layer_width, randf() * layer_height)
		var r = randf_range(15.0, 60.0)
		var c = Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8))
		draw_circle(pos, r, c)
		
		# Optional crater details
		for j in range(3):
			var cr = randf_range(2.0, r / 3.0)
			var angle = randf() * TAU
			var dist = randf_range(0, r - cr)
			var cpos = pos + Vector2(cos(angle)*dist, sin(angle)*dist)
			draw_circle(cpos, cr, c.darkened(0.2))

		# Planetary ring
		if randf() > 0.5:
			var ring_color = Color(0.8, 0.8, 0.8, 0.4)
			var ring_r = r * randf_range(1.3, 1.8)
			# Godot's draw_arc is centered, so we approximate a slanted ring with a wide line
			draw_line(pos - Vector2(ring_r, ring_r*0.2), pos + Vector2(ring_r, ring_r*0.2), ring_color, randf_range(2.0, 5.0))

func _draw_debris() -> void:
	for i in range(40):
		var pos = Vector2(randf() * layer_width, randf() * layer_height)
		var pts = PackedVector2Array()
		var points_count = randi_range(4, 7)
		for j in range(points_count):
			var angle = j * TAU / float(points_count)
			var r = randf_range(2.0, 8.0)
			pts.append(pos + Vector2(cos(angle)*r, sin(angle)*r))
		var color = Color(0.4, 0.4, 0.45).darkened(randf_range(0.0, 0.4))
		draw_colored_polygon(pts, color)
