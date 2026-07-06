extends CharacterBody2D
## Bat (World 3, PG-53): flies a fixed horizontal patrol with a gentle
## vertical bob, ignoring gravity and floors. Reverses at a wall ahead
## or at the edge of its patrol span. Stompable from above, matching the
## walker enemy's contact rule.

const SPEED := 42.0
const BOB_AMP := 7.0
const BOB_FREQ := 3.0
const SPAN := 40.0
const WALL_PROBE := 7.0

var direction := -1
var _home_x := 0.0
var _base_y := 0.0
var _bob_t := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray: RayCast2D = $WallRay


func _ready() -> void:
	_home_x = global_position.x
	_base_y = global_position.y
	_bob_t = randf() * TAU
	_aim_wall_ray()


func _physics_process(delta: float) -> void:
	_bob_t += delta
	# Horizontal patrol: turn at a wall ahead or at the span limit.
	var next_x := global_position.x + direction * SPEED * delta
	if wall_ray.is_colliding() or absf(next_x - _home_x) > SPAN:
		direction *= -1
		_aim_wall_ray()
	else:
		global_position.x = next_x
	# Vertical bob around the spawn height (purely presentational).
	global_position.y = _base_y + sin(_bob_t * BOB_FREQ) * BOB_AMP


func _aim_wall_ray() -> void:
	wall_ray.target_position.x = WALL_PROBE * direction
	wall_ray.force_raycast_update()
	sprite.flip_h = direction > 0


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	var player := body as Player
	if player.dying:
		return
	# Stomp: player moving down and clearly above the bat's center.
	if player.velocity.y > 0.0 and player.global_position.y < global_position.y - 2.0:
		player.bounce()
		_squash()
	else:
		player.die()


func _squash() -> void:
	Sfx.play_sfx("stomp")
	set_physics_process(false)
	$Hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", 0.2, 0.1)
	tween.tween_callback(queue_free)
