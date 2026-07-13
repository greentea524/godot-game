extends Control
## Main menu (PG-17): title, Start button, instructions, and the
## avatar selection row (PG-30).

const WORLDS = [
	{
		"name": "World 1 – Grasslands",
		"icon_color": Color(0.35, 0.69, 0.27),
		"desc": "A bright and sunny adventure through open fields and rolling hills. The perfect place to find your footing."
	},
	{
		"name": "World 2 – Dark Forest",
		"icon_color": Color(0.14, 0.23, 0.16),
		"desc": "The trees grow tall and the path grows narrow. Watch your step — enemies lurk in the shadows."
	},
	{
		"name": "World 3 – Underworld",
		"icon_color": Color(0.7, 0.2, 0.1),
		"desc": "Deep beneath the surface lies a world of lava, caves, and darkness. Only the brave survive."
	},
	{
		"name": "World 4 – Space",
		"icon_color": Color(0.1, 0.1, 0.3),
		"desc": "Gravity is just a suggestion up here. Jump between asteroids and dodge meteors in the final frontier."
	},
	{
		"name": "World 5 – Frozen Peaks",
		"icon_color": Color(0.6, 0.8, 0.9),
		"desc": "Slippery ice, falling stalactites, and freezing waters await. Keep moving to stay warm!"
	},
	{
		"name": "World 6 – Neon Factory",
		"icon_color": Color(0.8, 0.2, 0.8),
		"desc": "Conveyor belts, lasers, and drones. Precision is required to survive the gauntlet."
	}
]

func _ready() -> void:
	var start: Button = %StartButton
	start.pressed.connect(GameManager.start_game)
	start.grab_focus()
	%MultiplayerButton.pressed.connect(GameManager.open_multiplayer)
	%AchievementsButton.pressed.connect(func():
		var ach_menu = preload("res://scenes/achievements_menu.tscn").instantiate()
		add_child(ach_menu)
	)
	_build_avatar_row()
	_build_world_preview()


func _build_world_preview() -> void:
	var row: HBoxContainer = %WorldPreviewRow
	for i in WORLDS.size():
		var w = WORLDS[i]
		
		var panel = Button.new()
		panel.custom_minimum_size = Vector2(250, 80)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.18, 0.25)
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("normal", style)
		
		var hover_style = style.duplicate()
		hover_style.bg_color = style.bg_color.lightened(0.15)
		panel.add_theme_stylebox_override("hover", hover_style)
		panel.add_theme_stylebox_override("pressed", style)
		panel.add_theme_stylebox_override("focus", hover_style)
		
		var disabled_style = style.duplicate()
		disabled_style.bg_color = Color(0.1, 0.12, 0.15)
		panel.add_theme_stylebox_override("disabled", disabled_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		panel.add_child(hbox)
		
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(12, 0)
		icon.color = w["icon_color"]
		hbox.add_child(icon)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var title = Label.new()
		title.text = w["name"]
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", w["icon_color"].lightened(0.5))
		vbox.add_child(title)
		
		var desc = Label.new()
		desc.text = w["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		desc.custom_minimum_size = Vector2(190, 45)
		vbox.add_child(desc)
		
		var arrow = Label.new()
		arrow.text = ">"
		arrow.add_theme_font_size_override("font_size", 24)
		arrow.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(arrow)
		
		# Lock Worlds beyond the player's progress
		var max_world := GameManager.world_of(clampi(GameManager.levels_completed, 0, GameManager.level_count() - 1))
		if i > max_world:
			title.text += " [LOCKED]"
			title.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
			panel.disabled = true
			arrow.visible = false
		else:
			panel.pressed.connect(func() -> void: GameManager.goto_level(GameManager.flat_index(i, 0)))
		
		row.add_child(panel)


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
		button.custom_minimum_size = Vector2(40, 40)
		button.tooltip_text = GameManager.AVATAR_NAMES[i]
		var icon := AtlasTexture.new()
		icon.atlas = load(GameManager.AVATAR_SHEETS[i])
		icon.region = Rect2(0, 0, 16, 16)
		button.icon = icon
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(func() -> void: 
			GameManager.selected_avatar = i
			GameManager.track_avatar(i)
		)
		row.add_child(button)
