extends Area2D
## Spike hazard: instantly kills the player on contact.


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).die()
