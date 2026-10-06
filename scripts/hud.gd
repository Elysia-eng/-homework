extends CanvasLayer

const HEART_FULL := preload("res://assets/game/ui/heart_full.png")
const HEART_HALF := preload("res://assets/game/ui/heart_half.png")
const HEART_EMPTY := preload("res://assets/game/ui/heart_empty.png")

const HEART_COUNT: int = 5
const POINTS_PER_HEART: int = 2

@onready var _hearts_box: HBoxContainer = $Hearts
@onready var _health_label: Label = $HealthLabel
@onready var _coin_label: Label = $CoinPanel/CoinLabel
@onready var _boss_bar: ProgressBar = $BossBar
@onready var _boss_label: Label = $BossLabel
@onready var _message: Label = $Message
@onready var _hint: Label = $Hint

var _hearts: Array[TextureRect] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hearts()

	GameManager.health_changed.connect(_on_health_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.boss_health_changed.connect(_on_boss_health_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_won.connect(_on_game_won)

	_on_health_changed(GameManager.health, GameManager.max_health)
	_on_coins_changed(GameManager.coins)
	_on_boss_health_changed(GameManager.boss_health, GameManager.boss_max_health)
	_message.visible = false
	_hint.visible = false

func _build_hearts() -> void:
	for i in HEART_COUNT:
		var heart := TextureRect.new()
		heart.texture = HEART_FULL
		heart.custom_minimum_size = Vector2(18, 18)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hearts_box.add_child(heart)
		_hearts.append(heart)

func _on_health_changed(health: int, max_health: int) -> void:
	_health_label.text = "%d / %d" % [health, max_health]
	for i in _hearts.size():
		var value := health - i * POINTS_PER_HEART
		if value >= POINTS_PER_HEART:
			_hearts[i].texture = HEART_FULL
		elif value == 1:
			_hearts[i].texture = HEART_HALF
		else:
			_hearts[i].texture = HEART_EMPTY

func _on_coins_changed(coins: int) -> void:
	_coin_label.text = "x %d" % coins

func _on_boss_health_changed(health: int, max_health: int) -> void:
	var show_bar := max_health > 0 and not (GameManager.is_game_over or GameManager.is_game_won)
	_boss_bar.visible = show_bar
	_boss_label.visible = show_bar
	if not show_bar:
		return
	_boss_bar.max_value = float(max_health)
	_boss_bar.value = float(health)

func _on_game_over() -> void:
	_boss_bar.visible = false
	_boss_label.visible = false
	_message.text = "游戏失败 GAME OVER"
	_message.add_theme_color_override("font_color", Color(0.92, 0.28, 0.32))
	_message.visible = true
	_hint.text = "按 R 重新开始  (Press R to restart)"
	_hint.visible = true

func _on_game_won() -> void:
	_boss_bar.visible = false
	_boss_label.visible = false
	_message.text = "游戏胜利 YOU WIN!"
	_message.add_theme_color_override("font_color", Color(0.98, 0.82, 0.25))
	_message.visible = true
	_hint.text = "按 R 重新开始  (Press R to restart)"
	_hint.visible = true
