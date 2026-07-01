extends Area2D
## Goal flag: touching it completes the level.

var _reached := false


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying or _reached:
		return
	_reached = true
	GameManager.level_complete()
