extends Control
## Level complete screen (PG-19): shows coins collected, world stage
## progress, and loads the next level.


func _ready() -> void:
	%CoinsLabel.text = "Coins collected: %d" % GameManager.coins
	_build_stage_progress()
	var next: Button = %NextButton
	next.pressed.connect(GameManager.next_level)
	next.grab_focus()


## Shows all 4 worlds' stage progress as a concise map.
func _build_stage_progress() -> void:
	var progress_row: HBoxContainer = %ProgressRow
	progress_row.add_theme_constant_override("separation", 35) # Spacing between worlds

	for w in GameManager.WORLDS.size():
		var w_box := VBoxContainer.new()
		w_box.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var w_label := Label.new()
		w_label.text = "World %d" % (w + 1)
		w_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		w_label.add_theme_font_size_override("font_size", 13)
		w_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
		
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		
		var stages_in_world: int = GameManager.WORLDS[w].size()
		var world_start := GameManager.flat_index(w, 0)
		
		for stage in stages_in_world:
			var index := world_start + stage
			var dot := Label.new()
			dot.add_theme_font_size_override("font_size", 18)
			
			if index <= GameManager.current_level:
				dot.text = "●"
				dot.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
			else:
				dot.text = "○"
				dot.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
				
			# Highlight the current level specifically
			if index == GameManager.current_level:
				var tween := create_tween().set_loops()
				tween.tween_property(dot, "modulate:a", 0.3, 0.6)
				tween.tween_property(dot, "modulate:a", 1.0, 0.6)
				
			row.add_child(dot)
			
		w_box.add_child(w_label)
		w_box.add_child(row)
		progress_row.add_child(w_box)
