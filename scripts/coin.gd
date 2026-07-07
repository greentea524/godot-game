extends Area2D
## Collectible coin. Reports to GameManager, which notifies the HUD.


func _on_body_entered(body: Node2D) -> void:
	if body is not Player or (body as Player).dying:
		return
	if Net.active:
		rpc("collect")
	else:
		collect()

@rpc("any_peer", "call_local", "reliable")
func collect() -> void:
	GameManager.add_coin()
	set_deferred("monitoring", false)
	# Pickup sound plays from the coin itself before it is freed (PG-25);
	# the fade-out tween below keeps the node alive long enough.
	$Pickup.play()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 8.0, 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_interval(0.1)
	tween.tween_callback(queue_free)
