extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var icon_label: Label = %IconLabel
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var sound: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	panel.position.y = -120
	panel.position.x = 640 / 2.0 - 150 # Centered on a 640 width screen

func display(achievement: Dictionary) -> void:
	icon_label.text = achievement.get("icon", "")
	name_label.text = achievement.get("name", "")
	desc_label.text = achievement.get("desc", "")
	
	if sound.stream:
		sound.play()
	
	var tween := create_tween()
	# Slide in
	tween.tween_property(panel, "position:y", 20.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Hold
	tween.tween_interval(3.5)
	# Slide out
	tween.tween_property(panel, "position:y", -120.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# Cleanup
	tween.tween_callback(queue_free)
