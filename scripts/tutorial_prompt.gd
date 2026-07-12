class_name TutorialPrompt
extends CanvasLayer
## Transient on-screen tutorial banner (PG-65, ported from the JS
## platformer's double-jump hint). Fades a message in, holds, then fades
## out. Purely visual — no gameplay impact.

@onready var root: Control = $Root
@onready var label: Label = %TutorialLabel


func _ready() -> void:
	root.modulate.a = 0.0


func show_message(text: String, hold := 3.0) -> void:
	label.text = text
	root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.4)
	tween.tween_interval(hold)
	tween.tween_property(root, "modulate:a", 0.0, 0.6)
