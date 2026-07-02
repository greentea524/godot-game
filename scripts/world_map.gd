extends Control
## World map (PG-37): shown after finishing the last stage of a world.
## Lists every world with its stages — completed stages get a coin
## icon, the next stage shows the player's avatar, locked stages are
## dimmed. Continue proceeds to the next level or the win screen.

const COIN_TEXTURE := preload("res://assets/coin.png")


func _ready() -> void:
	%Subtitle.text = "World %d complete!" % (GameManager.world_of(GameManager.current_level) + 1)
	_build_map()
	var cont: Button = %ContinueButton
	cont.pressed.connect(GameManager.continue_from_world_map)
	cont.grab_focus()


func _build_map() -> void:
	var box: VBoxContainer = %MapBox
	for world in GameManager.WORLDS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var world_label := Label.new()
		world_label.text = "World %d" % (world + 1)
		world_label.add_theme_font_size_override("font_size", 14)
		world_label.custom_minimum_size = Vector2(72, 0)
		row.add_child(world_label)
		for stage in GameManager.WORLDS[world].size():
			row.add_child(_stage_cell(world, stage))
		box.add_child(row)


func _stage_cell(world: int, stage: int) -> VBoxContainer:
	var index := GameManager.flat_index(world, stage)
	var cell := VBoxContainer.new()
	cell.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var label := Label.new()
	label.text = "%d-%d" % [world + 1, stage + 1]
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if GameManager.is_completed(index):
		icon.texture = _atlas_frame(COIN_TEXTURE)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	elif index == GameManager.levels_completed:
		icon.texture = _atlas_frame(load(GameManager.avatar_sheet()))
	else:
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

	cell.add_child(icon)
	cell.add_child(label)
	return cell


func _atlas_frame(sheet: Texture2D) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(0, 0, 16, 16)
	return frame
