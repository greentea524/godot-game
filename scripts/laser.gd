extends Area2D
## Laser emitter (World 6): toggles a vertical kill-beam on a timer.
## States: charging (0.5s) -> active (2.0s) -> cooldown (2.0s) -> repeat.

const CHARGE_TIME := 0.5
const ACTIVE_TIME := 2.0
const COOLDOWN_TIME := 2.0

var _state := "cooldown"
var _timer := 0.0

@onready var beam: ColorRect = $Beam
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Stagger the timers so they don't all fire at once
	_timer = randf() * COOLDOWN_TIME
	_update_visuals()

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		if _state == "cooldown":
			_state = "charging"
			_timer = CHARGE_TIME
		elif _state == "charging":
			_state = "active"
			_timer = ACTIVE_TIME
		else:
			_state = "cooldown"
			_timer = COOLDOWN_TIME
		_update_visuals()
	
	if _state == "charging":
		# Flicker effect while charging
		beam.modulate.a = randf_range(0.2, 0.6)

func _update_visuals() -> void:
	if _state == "active":
		beam.modulate.a = 1.0
		beam.color = Color(1.0, 0.2, 0.2)
		collision.set_deferred("disabled", false)
	elif _state == "charging":
		beam.color = Color(1.0, 0.5, 0.5)
		collision.set_deferred("disabled", true)
	else:
		beam.modulate.a = 0.0
		collision.set_deferred("disabled", true)

func _on_body_entered(body: Node2D) -> void:
	if _state == "active" and body is Player:
		(body as Player).die()
