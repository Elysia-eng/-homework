extends Area2D

@export var speed: float = 240.0
@export var damage: int = 1
@export var lifetime: float = 1.6
@export var hits_player: bool = false

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)

func launch(dir: Vector2, from: Vector2) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = from
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hits_player:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
			return
	elif body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
		return

	if body is TileMapLayer or body is StaticBody2D:
		queue_free()
