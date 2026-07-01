class_name Player
extends CharacterBody2D
## Side-scroller player controller: run, variable-height jump with
## coyote time + jump buffering, state-driven animations, death/respawn.

const SPEED := 140.0
const JUMP_VELOCITY := -320.0
const JUMP_CUT_MULTIPLIER := 0.4
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1
const STOMP_BOUNCE := -200.0
const DEATH_HOP := -220.0
const RESPAWN_DELAY := 0.9

var dying := false

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	if dying:
		# Mario-style death hop: collisions are off, just fall out of view.
		velocity.y += get_gravity().y * delta
		move_and_slide()
		return

	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		velocity.y += get_gravity().y * delta
		_coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER
	else:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Variable jump height: releasing jump early cuts the ascent.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: float) -> void:
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 5.0:
		sprite.play("run")
	else:
		sprite.play("idle")


## Upward bounce after stomping an enemy.
func bounce() -> void:
	velocity.y = STOMP_BOUNCE


func die() -> void:
	if dying:
		return
	dying = true
	sprite.modulate = Color(1.0, 0.45, 0.45)
	sprite.play("fall")
	velocity = Vector2(0.0, DEATH_HOP)
	collision_layer = 0
	collision_mask = 0
	if GameManager.lose_life():
		GameManager.trigger_game_over()
	else:
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		_respawn()


func _respawn() -> void:
	global_position = GameManager.respawn_position
	velocity = Vector2.ZERO
	collision_layer = 2
	collision_mask = 1
	dying = false
	camera.reset_smoothing()
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.3)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.6)
