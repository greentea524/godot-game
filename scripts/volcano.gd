extends Node2D
## Erupting volcano (World 3, PG-62): a harmless, non-solid ground mound
## that periodically lobs deadly lava rocks in an arc. The crater
## brightens as the next eruption charges, telegraphing it. Ported from
## the JS platformer's PG-58. Timing is per-instance (random phase), like
## the meteor shower, so it stays simple in multiplayer ghost-races.

const MIN_INTERVAL := 2.8
const MAX_INTERVAL := 4.4
const ROCK_SPEED_X := 70.0
const ROCK_SPEED_Y_MIN := 200.0
const ROCK_SPEED_Y_MAX := 260.0
const LAVA_ROCK_SCENE := preload("res://scenes/lava_rock.tscn")

var _timer := 1.0
var _interval := MIN_INTERVAL

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# Random initial phase so multiple volcanoes don't fire in sync.
	_timer = 1.0 + randf() * MIN_INTERVAL


func _physics_process(delta: float) -> void:
	_timer -= delta
	# Crater glow charges up as the eruption approaches (telegraph).
	var charge := 1.0 - clampf(_timer / _interval, 0.0, 1.0)
	sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.55, 0.3), charge * 0.7)
	if _timer > 0.0:
		return
	_interval = randf_range(MIN_INTERVAL, MAX_INTERVAL)
	_timer = _interval
	_erupt()


func _erupt() -> void:
	var count := 2 + (1 if randf() < 0.5 else 0)
	for i in count:
		var rock := LAVA_ROCK_SCENE.instantiate()
		rock.position = position + Vector2(0, -6)
		rock.start_y = rock.position.y
		rock.velocity = Vector2(
			randf_range(-ROCK_SPEED_X, ROCK_SPEED_X),
			-randf_range(ROCK_SPEED_Y_MIN, ROCK_SPEED_Y_MAX))
		get_parent().add_child(rock)
