extends Area2D
## Collectible coin. Reports to GameManager, which notifies the HUD.


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying:
		return
	GameManager.add_coin()
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 8.0, 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
