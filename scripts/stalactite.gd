extends Area2D
## Stalactite (World 3, PG-53): hangs from the ceiling until the player
## passes beneath, then drops under gravity and shatters when it hits a
## solid tile (or falls out of the level). Deadly on contact.

const GRAVITY := 980.0
const FALL_CULL := 20 * 16.0  # freed after dropping this far (out of level)

var _falling := false
var _vy := 0.0
var _start_y := 0.0

@onready var ground_ray: RayCast2D = $GroundRay


func _ready() -> void:
	_start_y = global_position.y


func _physics_process(delta: float) -> void:
	if not _falling:
		return
	_vy += GRAVITY * delta
	position.y += _vy * delta
	if ground_ray.is_colliding() or global_position.y - _start_y > FALL_CULL:
		_shatter()


## The drop zone (a tall box beneath the tip) fires this when the player
## passes underneath.
func _on_drop_zone_body_entered(body: Node2D) -> void:
	if not _falling and body is Player:
		_falling = true


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).die()


func _shatter() -> void:
	set_physics_process(false)
	monitoring = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)
