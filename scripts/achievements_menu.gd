extends CanvasLayer

@onready var container = %AchievementsContainer
@onready var close_button = %CloseButton
@onready var progress_label = %ProgressLabel

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	close_button.grab_focus()
	_populate()

func _populate() -> void:
	var unlocked_count = GameManager.unlocked_achievements.size()
	var total_count = Achievements.LIST.size()
	progress_label.text = "Unlocked: %d / %d" % [unlocked_count, total_count]
	
	for a in Achievements.LIST:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 60)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.18, 0.25)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.content_margin_right = 12
		panel.add_theme_stylebox_override("panel", style)
		
		var is_unlocked = GameManager.unlocked_achievements.has(a.id)
		if not is_unlocked:
			panel.modulate = Color(0.6, 0.6, 0.6, 0.8)
			
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		
		var icon = Label.new()
		icon.text = a.icon if is_unlocked else "🔒"
		icon.add_theme_font_size_override("font_size", 28)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title = Label.new()
		title.text = a.name
		title.add_theme_font_size_override("font_size", 16)
		if is_unlocked:
			title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
			
		var desc = Label.new()
		desc.text = a.desc
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		vbox.add_child(title)
		vbox.add_child(desc)
		
		hbox.add_child(icon)
		hbox.add_child(vbox)
		
		if not is_unlocked:
			var stats = {
				"total_coins": GameManager.total_coins,
				"levels_completed": GameManager.levels_completed,
				"stomps": GameManager.stomps,
				"deaths": GameManager.deaths,
				"avatars_used": GameManager.avatars_used,
				"death_free_clears": GameManager.death_free_clears,
				"death_free_worlds": GameManager.death_free_worlds,
				"fast_clears": GameManager.fast_clears,
				"lightning_clears": GameManager.lightning_clears,
				"world_3_lava_free": GameManager.world_3_lava_free,
				"world_5_water_free": GameManager.world_5_water_free
			}
			var current = min(a.target, Achievements.new().call(a.goal, stats))
			var prog = Label.new()
			prog.text = "%d / %d" % [current, a.target]
			prog.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			prog.add_theme_font_size_override("font_size", 14)
			prog.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			hbox.add_child(prog)
		
		panel.add_child(hbox)
		container.add_child(panel)
