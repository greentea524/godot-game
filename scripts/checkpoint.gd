extends Area2D
## Checkpoint: updates the respawn point when the player passes it.

var _activated := false


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying or _activated:
		return
	if Net.active:
		rpc("activate")
	else:
		activate()

@rpc("any_peer", "call_local", "reliable")
func activate() -> void:
	if _activated: return
	_activated = true
	GameManager.set_checkpoint(global_position)
	modulate = Color(0.55, 1.0, 0.55)
