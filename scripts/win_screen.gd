extends Control
## You Win screen (PG-20): shown after completing Level 3.


func _ready() -> void:
	%CoinsLabel.text = "Total coins: %d" % GameManager.coins
	var menu: Button = %MenuButton
	menu.pressed.connect(GameManager.main_menu)
	menu.grab_focus()
