extends Area2D
## Lava pool (World 3, PG-53): a non-solid tile-sized hazard that kills
## the player on contact. The collision box drops its top a few pixels
## so brushing the edge from an adjacent tile isn't an instant kill.


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).die("lava")
