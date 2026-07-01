extends Control
## Level complete screen (PG-19): shows coins collected, loads the next level.


func _ready() -> void:
	%CoinsLabel.text = "Coins collected: %d" % GameManager.coins
	var next: Button = %NextButton
	next.pressed.connect(GameManager.next_level)
	next.grab_focus()
