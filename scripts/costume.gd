extends Node2D

var facing: float = 1.0

func _process(_delta: float) -> void:
	if owner and "sprite" in owner:
		facing = -1.0 if owner.sprite.flip_h else 1.0
	queue_redraw()

func _draw() -> void:
	var world = GameManager.world_of(GameManager.current_level)
	if world == 0:
		_draw_straw_hat()
	elif world == 1:
		_draw_lantern()
	elif world == 2:
		_draw_miners_headlamp()
	elif world == 3:
		_draw_space_helmet()
	elif world == 4:
		_draw_skis()
	elif world == 5:
		_draw_cyber_visor()

func _draw_space_helmet() -> void:
	var hy = -4.0
	draw_circle(Vector2(0, hy), 7.0, Color(0.6, 0.8, 1.0, 0.22))
	draw_arc(Vector2(0, hy), 7.0, 0, TAU, 32, Color(0.9, 0.95, 1.0, 0.92), 1.5)
	var ny = hy + 6.0
	draw_rect(Rect2(-4, ny, 8, 2), Color(0.8, 0.8, 0.8))
	draw_rect(Rect2(-5, ny+1, 10, 1), Color(0.6, 0.6, 0.6))

func _draw_skis() -> void:
	var fy = 8.0
	var sx = -2.0 if facing < 0 else 2.0
	draw_rect(Rect2(-7 + sx, fy, 14, 2), Color(0.9, 0.2, 0.2))
	draw_line(Vector2(7 + sx, fy + 2), Vector2(9 + sx, fy), Color(0.9, 0.2, 0.2), 2.0)
	draw_line(Vector2(-7 + sx, fy + 2), Vector2(-9 + sx, fy), Color(0.9, 0.2, 0.2), 2.0)
	draw_line(Vector2(0, 1), Vector2(-4 * facing, fy), Color(0.3, 0.3, 0.3), 1.0)
	
func _draw_straw_hat() -> void:
	var hy = -6.0
	draw_rect(Rect2(-8, hy + 2, 16, 2), Color(0.9, 0.8, 0.4))
	draw_rect(Rect2(-4, hy - 2, 8, 4), Color(0.9, 0.8, 0.4))
	draw_rect(Rect2(-4, hy + 1, 8, 1), Color(0.8, 0.3, 0.3))

func _draw_lantern() -> void:
	var hx = 6.0 * facing
	var hy = 2.0
	draw_line(Vector2(2 * facing, 2), Vector2(hx, hy - 4), Color(0.4, 0.2, 0.1), 1.5)
	draw_rect(Rect2(hx - 2, hy - 4, 4, 6), Color(0.8, 0.7, 0.2))
	draw_rect(Rect2(hx - 1, hy - 3, 2, 4), Color(1.0, 0.9, 0.6))
	draw_circle(Vector2(hx, hy - 1), 15.0, Color(1.0, 0.8, 0.4, 0.15))
	
func _draw_miners_headlamp() -> void:
	var hy = -6.0
	draw_rect(Rect2(-5, hy - 1, 10, 4), Color(0.9, 0.8, 0.2))
	var brim_x = -6 if facing < 0 else 4
	draw_rect(Rect2(brim_x, hy, 2, 2), Color(0.9, 0.8, 0.2))
	var lx = 4.0 * facing
	draw_rect(Rect2(lx - 1, hy, 3, 3), Color(0.7, 0.7, 0.7))
	draw_rect(Rect2(lx, hy + 0.5, 2, 2), Color(1.0, 1.0, 0.8))
	var pts = PackedVector2Array([
		Vector2(lx + 2 * facing, hy + 1.5),
		Vector2(lx + 40 * facing, hy - 10),
		Vector2(lx + 40 * facing, hy + 13)
	])
	draw_polygon(pts, PackedColorArray([Color(1.0, 1.0, 0.8, 0.3), Color(1.0, 1.0, 0.8, 0.0), Color(1.0, 1.0, 0.8, 0.0)]))

func _draw_cyber_visor() -> void:
	var hy = -3.0
	draw_rect(Rect2(-4, hy, 8, 3), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(-3 + (facing * 1), hy + 0.5, 4, 2), Color(1.0, 0.2, 0.2))
	draw_line(Vector2(0, hy), Vector2(0, hy + 3), Color(1.0, 0.5, 0.5, 0.5), 1.0)
