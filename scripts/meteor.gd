extends Area2D
## Meteor (World 4, PG-54): falls straight down at a constant speed and
## kills the player on contact. Spawned by the level's meteor shower on
## the later space stages; frees itself once it drops past the level.

const SPEED := 170.0

## Set by the spawner to the level's kill plane (plus a margin).
var fall_limit := 100000.0


func _physics_process(delta: float) -> void:
	position.y += SPEED * delta
	if global_position.y > fall_limit:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).die()
