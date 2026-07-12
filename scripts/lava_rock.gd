extends Area2D
## Lava rock (World 3, PG-62): a volcano projectile. Arcs under gravity,
## kills the player on contact, and shatters when it lands on solid
## ground (only while descending, so it can rise out of the crater) or
## once it falls out of the level.

const GRAVITY := 980.0
const FALL_CULL := 10 * 16.0  # freed after dropping this far below spawn

var velocity := Vector2.ZERO
var start_y := 0.0

@onready var ground_ray: RayCast2D = $GroundRay


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	if (velocity.y > 0.0 and ground_ray.is_colliding()) \
			or global_position.y - start_y > FALL_CULL:
		_shatter()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).die()


func _shatter() -> void:
	set_physics_process(false)
	monitoring = false
	queue_free()
