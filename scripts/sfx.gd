extends Node
## Autoloaded fire-and-forget sound effects. Used for sounds whose
## emitting node dies before the sound finishes: stomped enemies are
## freed, and the goal flag triggers a scene change (PG-26, PG-27).

const STREAMS := {
	"stomp": preload("res://assets/sfx/stomp.wav"),
	"level_complete": preload("res://assets/sfx/level_complete.wav"),
}


func play_sfx(sound_name: String) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = STREAMS[sound_name]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
