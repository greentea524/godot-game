extends CanvasLayer
## In-game HUD: live coin counter and lives display (PG-18).

@onready var coins_label: Label = %CoinsLabel
@onready var lives_label: Label = %LivesLabel


func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	_on_coins_changed(GameManager.coins)
	_on_lives_changed(GameManager.lives)


func _on_coins_changed(count: int) -> void:
	coins_label.text = "Coins: %d" % count


func _on_lives_changed(count: int) -> void:
	lives_label.text = "Lives: %d" % count
