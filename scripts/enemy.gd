extends CharacterBody2D
## Patrolling enemy: walks until its floor ray finds a ledge or its wall
## ray hits a tile, then turns around. Stompable from above.

const SPEED := 30.0
const FLOOR_RAY_OFFSET := 6.0
const WALL_RAY_REACH := 7.0

var direction := -1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_ray: RayCast2D = $FloorRay
@onready var wall_ray: RayCast2D = $WallRay


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	elif wall_ray.is_colliding() or not floor_ray.is_colliding():
		_turn()
	velocity.x = direction * SPEED
	move_and_slide()


func _turn() -> void:
	direction *= -1
	floor_ray.position.x = FLOOR_RAY_OFFSET * direction
	wall_ray.target_position.x = WALL_RAY_REACH * direction
	sprite.flip_h = direction > 0


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	var player := body as Player
	if player.dying:
		return
	# Stomp: player moving down and clearly above the enemy's center.
	if player.velocity.y > 0.0 and player.global_position.y < global_position.y - 2.0:
		player.bounce()
		_squash()
	else:
		player.die()


func _squash() -> void:
	set_physics_process(false)
	$Hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", 0.2, 0.1)
	tween.tween_callback(queue_free)
