extends Area2D

@export var damage: int = 1

func _ready() -> void:
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		_try_hurt(body)

func _on_body_entered(body: Node2D) -> void:
	_try_hurt(body)

func _try_hurt(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return

	var hurt = body.take_damage(damage)
	if hurt and body.has_method("knockback"):
		body.knockback(global_position)
