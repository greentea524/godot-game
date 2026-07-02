class_name Player
extends CharacterBody2D
## Side-scroller player controller: run, variable-height jump with
## coyote time + jump buffering, one mid-air double jump, state-driven
## animations, death/respawn, and the session-selected avatar skin.

const SPEED := 140.0
const JUMP_VELOCITY := -320.0
const JUMP_CUT_MULTIPLIER := 0.4
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.1
const MAX_AIR_JUMPS := 1
const STOMP_BOUNCE := -200.0
const DEATH_HOP := -220.0
const RESPAWN_DELAY := 0.9

## All avatar sheets share this 8-frame layout (16x16 per frame).
const SHEET_FRAMES := {"idle": [0, 1], "run": [2, 3, 4, 5], "jump": [6], "fall": [7]}
const SHEET_FPS := {"idle": 3.0, "run": 10.0, "jump": 5.0, "fall": 5.0}

var dying := false

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _air_jumps_left := MAX_AIR_JUMPS

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer = $DoubleJumpSound


func _ready() -> void:
	_apply_avatar()


func _physics_process(delta: float) -> void:
	if dying:
		# Mario-style death hop: collisions are off, just fall out of view.
		velocity.y += get_gravity().y * delta
		move_and_slide()
		return

	if is_on_floor():
		_coyote_timer = COYOTE_TIME
		_air_jumps_left = MAX_AIR_JUMPS
	else:
		velocity.y += get_gravity().y * delta
		_coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER
	else:
		_jump_buffer_timer -= delta

	var can_ground_jump := is_on_floor() or _coyote_timer > 0.0
	if _jump_buffer_timer > 0.0 and can_ground_jump:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jump_sound.play()
	elif Input.is_action_just_pressed("jump") and not can_ground_jump \
			and _air_jumps_left > 0:
		# Double jump (PG-21): one extra boost per airtime, reset on landing.
		velocity.y = JUMP_VELOCITY
		_air_jumps_left -= 1
		_jump_buffer_timer = 0.0
		double_jump_sound.play()
		_double_jump_flair()

	# Variable jump height: releasing jump early cuts the ascent.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED

	move_and_slide()
	_update_animation(direction)


## Builds the sprite frames from the avatar sheet chosen in the main
## menu (PG-30). All sheets share one frame layout, so switching
## avatars is just an atlas swap.
func _apply_avatar() -> void:
	var sheet: Texture2D = load(GameManager.avatar_sheet())
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in SHEET_FRAMES:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, SHEET_FPS[anim])
		frames.set_animation_loop(anim, true)
		for index in SHEET_FRAMES[anim]:
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(index * 16, 0, 16, 16)
			frames.add_frame(anim, frame)
	sprite.sprite_frames = frames
	sprite.play("idle")


func _update_animation(direction: float) -> void:
	if direction != 0.0:
		sprite.flip_h = direction < 0.0
	if not is_on_floor():
		sprite.play("jump" if velocity.y < 0.0 else "fall")
	elif absf(velocity.x) > 5.0:
		sprite.play("run")
	else:
		sprite.play("idle")


## Distinct visual for the second jump: a quick squash-and-stretch.
func _double_jump_flair() -> void:
	sprite.scale = Vector2(1.4, 0.6)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)


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
