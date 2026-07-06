extends AnimatableBody2D
## Moving asteroid platform (World 4, PG-54). Drifts horizontally so
## landing requires timing; as an AnimatableBody2D with sync_to_physics
## it carries a CharacterBody2D rider natively (the Godot-only upgrade
## over the JS port's static platforms — see PG-54's decision comment).
## The drift span reaches both edges of a void so the player can always
## board and ride across.

const DRIFT := 34.0  # px each way from spawn
const RATE := 1.1    # rad/s

var _home_x := 0.0
var _t := 0.0


func _ready() -> void:
	_home_x = position.x
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	_t += delta
	position.x = _home_x + sin(_t * RATE) * DRIFT
