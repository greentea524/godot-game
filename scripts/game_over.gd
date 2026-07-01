extends Control
## Game Over screen (PG-20): retry the current level or return to menu.


func _ready() -> void:
	var retry: Button = %RetryButton
	retry.pressed.connect(GameManager.retry_level)
	%MenuButton.pressed.connect(GameManager.main_menu)
	retry.grab_focus()
