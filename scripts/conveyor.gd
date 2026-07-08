extends StaticBody2D
## Conveyor belt (World 6): pushes the player horizontally.

@export var dir: int = 1
const SPEED := 60.0

func _ready() -> void:
	constant_linear_velocity = Vector2(dir * SPEED, 0)
	
	if dir < 0:
		$Sprite2D.flip_h = true
