extends Area2D
## Goal flag: touching it completes the level.

var _reached := false

func _ready() -> void:
	add_to_group("flag")

func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying or _reached:
		return
	if Net.active:
		rpc("reach_flag")
	else:
		reach_flag()

@rpc("any_peer", "call_local", "reliable")
func reach_flag() -> void:
	if _reached: return
	_reached = true
	# Jingle plays on goal contact, before the UI transition (PG-27);
	# the Sfx autoload keeps it alive across the scene change.
	Sfx.play_sfx("level_complete")
	if owner and "level_time" in owner:
		GameManager.submit_level_clear(owner.level_time)
	GameManager.level_complete()
