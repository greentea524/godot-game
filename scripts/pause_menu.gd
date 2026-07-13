extends CanvasLayer
## Pause menu (PG-29): ESC toggles pause; the whole scene tree freezes
## via get_tree().paused while this layer keeps processing.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%ResumeButton.pressed.connect(_resume)
	%RestartButton.pressed.connect(_restart)
	%MapButton.pressed.connect(_map)
	%AchievementsButton.pressed.connect(func():
		var ach_menu = preload("res://scenes/achievements_menu.tscn").instantiate()
		add_child(ach_menu)
	)
	%QuitButton.pressed.connect(_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()


func _pause() -> void:
	get_tree().paused = true
	visible = true
	%ResumeButton.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	visible = false


func _restart() -> void:
	_resume()
	GameManager.goto_level(GameManager.current_level)


func _map() -> void:
	_resume()
	GameManager.world_map()


func _quit() -> void:
	_resume()
	GameManager.main_menu()
