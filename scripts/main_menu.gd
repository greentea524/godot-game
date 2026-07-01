extends Control
## Main menu (PG-17): title, Start button, instructions.


func _ready() -> void:
	var start: Button = %StartButton
	start.pressed.connect(GameManager.start_game)
	start.grab_focus()
