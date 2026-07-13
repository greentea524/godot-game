extends Control

var player: Player
var flag: Node2D
var start_x: float = 0.0
var flag_x: float = 1000.0

func _process(_delta: float) -> void:
	if player == null or flag == null:
		player = get_tree().get_first_node_in_group("player") as Player
		var flags = get_tree().get_nodes_in_group("flag")
		if flags.size() > 0:
			flag = flags[0]
			flag_x = flag.global_position.x
			start_x = GameManager.respawn_position.x
	queue_redraw()

func _draw() -> void:
	if flag == null: return
	
	var bar_w = size.x
	var bar_h = 4
	var by = size.y / 2.0 - 2
	
	# track
	draw_rect(Rect2(0, by, bar_w, bar_h), Color(0, 0, 0, 0.4))
	
	var length = max(1.0, flag_x - start_x)
	
	# goal (flag representation)
	draw_rect(Rect2(bar_w - 4, by - 4, 8, bar_h + 8), Color(1.0, 0.82, 0.2))
	
	# ghosts
	if Net.active:
		var ghosts = get_tree().get_nodes_in_group("ghosts")
		for g in ghosts:
			var gprog = clamp((g.global_position.x - start_x) / length, 0.0, 1.0)
			draw_circle(Vector2(gprog * bar_w, by + 2), 4, Color(0.8, 0.8, 1.0, 0.7))
	
	if player:
		var prog = clamp((player.global_position.x - start_x) / length, 0.0, 1.0)
		draw_circle(Vector2(prog * bar_w, by + 2), 6, Color.WHITE)
		draw_circle(Vector2(prog * bar_w, by + 2), 3, Color(0.2, 0.6, 1.0))
