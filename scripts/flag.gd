extends Area2D
## Goal flag: touching it completes the level.

var _reached := false


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying or _reached:
		return
	_reached = true
	# Jingle plays on goal contact, before the UI transition (PG-27);
	# the Sfx autoload keeps it alive across the scene change.
	Sfx.play_sfx("level_complete")
	GameManager.level_complete()
