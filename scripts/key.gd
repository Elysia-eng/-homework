extends Area2D

@export var key_id: int = 1

var taken: bool = false
var _sprite: Sprite2D = null
var _base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	add_to_group("key")
	body_entered.connect(_on_body_entered)
	_sprite = get_node_or_null("Sprite")
	_base_y = position.y

func _process(delta: float) -> void:
	if taken:
		return
	_time += delta
	position.y = _base_y + sin(_time * 3.0) * 3.0
	if _sprite != null:
		var pulse: float = (sin(_time * 5.0) + 1.0) * 0.5
		_sprite.modulate = Color(1, 1, 1, 1).lerp(Color(1, 0.95, 0.55, 1), pulse)

func _on_body_entered(body: Node2D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	set_deferred("monitoring", false)
	GameManager.collect_key(key_id)
	print("[Key] 获得钥匙 ", key_id)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 24.0, 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)
