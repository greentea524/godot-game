extends Control
## Main menu (PG-17): title, Start button, instructions, and the
## avatar selection row (PG-30).


func _ready() -> void:
	var start: Button = %StartButton
	start.pressed.connect(GameManager.start_game)
	start.grab_focus()
	_build_avatar_row()


## One toggle button per avatar, showing its idle frame. The selection
## is stored on GameManager so it persists for the whole session.
func _build_avatar_row() -> void:
	var row: HBoxContainer = %AvatarRow
	var group := ButtonGroup.new()
	for i in GameManager.AVATAR_SHEETS.size():
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = i == GameManager.selected_avatar
		button.custom_minimum_size = Vector2(52, 52)
		button.tooltip_text = GameManager.AVATAR_NAMES[i]
		var icon := AtlasTexture.new()
		icon.atlas = load(GameManager.AVATAR_SHEETS[i])
		icon.region = Rect2(0, 0, 16, 16)
		button.icon = icon
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(func() -> void: GameManager.selected_avatar = i)
		row.add_child(button)
