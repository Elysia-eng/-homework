extends Area2D

@export var coin_value: int = 1
@export var bob_height: float = 2.0
@export var bob_speed: float = 3.5

var _start_y: float = 0.0
var _time: float = 0.0
var _taken: bool = false

func _ready() -> void:
	add_to_group("coin")
	body_entered.connect(_on_body_entered)
	_start_y = position.y

func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	position.y = _start_y + sin(_time * bob_speed) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	GameManager.add_coins(coin_value)
	_play_pickup()

func _play_pickup() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 9.0, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
