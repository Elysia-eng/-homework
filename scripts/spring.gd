extends Area2D

@export var bounce_velocity: float = -340.0
@export var squash_scale: Vector2 = Vector2(1.3, 0.7)

var _sprite: Sprite2D = null
var _cooldown: float = 0.0

func _ready() -> void:
	add_to_group("spring")
	body_entered.connect(_on_body_entered)
	_sprite = get_node_or_null("Sprite")

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)

func _on_body_entered(body: Node2D) -> void:
	if _cooldown > 0.0 or not body.is_in_group("player"):
		return
	_cooldown = 0.2
	if body.has_method("bounce"):
		body.bounce(bounce_velocity)
	_squash()

func _squash() -> void:
	if _sprite == null:
		return
	_sprite.scale = squash_scale
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
