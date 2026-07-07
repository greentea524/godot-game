extends StaticBody2D
## Crumbling platform (World 3, PG-53): solid until the player stands on
## it, then it shakes, collapses (collision off + hidden), and respawns
## after a delay — but never rematerializes on top of the player.

const SHAKE_TIME := 0.4
const RESPAWN_TIME := 3.0

enum State { IDLE, SHAKING, GONE }
var _state := State.IDLE

@onready var col: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var stand_zone: Area2D = $StandZone


func _on_stand_zone_body_entered(body: Node2D) -> void:
	if _state == State.IDLE and body is Player:
		if Net.active:
			rpc("shake")
		else:
			shake()


@rpc("any_peer", "call_local", "reliable")
func shake() -> void:
	_state = State.SHAKING
	var tween := create_tween()
	# Rapid horizontal jitter for the shake duration.
	var shakes := int(SHAKE_TIME / 0.05)
	for i in shakes:
		tween.tween_property(sprite, "position:x", 1.0 if i % 2 == 0 else -1.0, 0.05)
	tween.tween_callback(_collapse)


func _collapse() -> void:
	_state = State.GONE
	sprite.position.x = 0.0
	sprite.visible = false
	col.set_deferred("disabled", true)
	await get_tree().create_timer(RESPAWN_TIME).timeout
	# Wait until the player is clear of the cell before returning.
	while _player_overlapping():
		await get_tree().create_timer(0.25).timeout
	sprite.visible = true
	col.set_deferred("disabled", false)
	_state = State.IDLE


func _player_overlapping() -> bool:
	for body in stand_zone.get_overlapping_bodies():
		if body is Player:
			return true
	return false
