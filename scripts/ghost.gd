class_name Ghost
extends Node2D
## A remote player rendered from interpolated snapshots (PG-51). Reuses
## the chosen avatar sheet but has NO collision and NO input — it can
## never affect the local player's physics, which is what keeps
## single-player behaviour identical during a race. Driven each frame by
## Net.ghost_view() via apply_view().

const SHEET_FRAMES := {"idle": [0, 1], "run": [2, 3, 4, 5], "jump": [6], "fall": [7]}
const SHEET_FPS := {"idle": 3.0, "run": 10.0, "jump": 5.0, "fall": 5.0}

var avatar := 0
var ghost_name := "Player"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel


func setup(av: int, pname: String) -> void:
	avatar = clampi(av, 0, GameManager.AVATAR_SHEETS.size() - 1)
	ghost_name = pname


func _ready() -> void:
	add_to_group("ghosts")
	modulate = Color(1.0, 1.0, 1.0, 0.65)  # ghosts read as translucent
	sprite.sprite_frames = _build_frames(load(GameManager.AVATAR_SHEETS[avatar]))
	sprite.play("idle")
	name_label.text = ghost_name


func apply_view(view: Dictionary) -> void:
	if view.is_empty():
		return
	global_position = Vector2(view["x"], view["y"])
	sprite.flip_h = view.get("facing", 1) < 0
	var anim: String = view.get("anim", "idle")
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


func _build_frames(sheet: Texture2D) -> SpriteFrames:
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
	return frames
