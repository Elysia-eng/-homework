extends Area2D

@export var active_color: Color = Color(1, 1, 1, 1)

var activated: bool = false
var _sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)
	_sprite = get_node_or_null("Sprite")
	if _sprite != null:
		_sprite.modulate = Color(0.68, 0.68, 0.74, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	GameManager.activate_checkpoint(global_position)
	set_deferred("monitoring", false)
	_play_activate()

func _play_activate() -> void:
	if _sprite == null:
		return
	_sprite.modulate = active_color
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.3, 0.8), 0.1)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
