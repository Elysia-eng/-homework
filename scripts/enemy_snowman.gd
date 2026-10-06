extends CharacterBody2D

@export var max_health: int = 1
@export var move_speed: float = 26.0
@export var shoot_interval: float = 1.0
@export var detect_range: float = 140.0
@export var gravity_force: float = 520.0
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 1
@export var start_direction: int = -1

var health: int = 1
var direction: int = -1

var _shoot_timer: float = 0.0
var _player: Node2D = null
var _sprite: Sprite2D = null
var _floor_probe: RayCast2D = null

func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	direction = -1 if start_direction <= 0 else 1
	_shoot_timer = shoot_interval
	_sprite = get_node_or_null("Sprite")
	_floor_probe = get_node_or_null("FloorProbe")
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won:
		velocity = Vector2.ZERO
		return

	if not is_on_floor():
		velocity.y += gravity_force * delta

	if _floor_probe != null:
		_floor_probe.position.x = direction * 8.0
		if is_on_floor() and not _floor_probe.is_colliding():
			direction = -direction

	velocity.x = direction * move_speed
	move_and_slide()

	if is_on_wall():
		direction = -direction

	if _sprite != null:
		_sprite.flip_h = direction > 0

	_update_shooting(delta)

func _update_shooting(delta: float) -> void:
	if bullet_scene == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return

	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	if _shoot_timer > 0.0:
		return
	if global_position.distance_to(_player.global_position) > detect_range:
		return

	_shoot_timer = shoot_interval
	_shoot_at_player()

func _shoot_at_player() -> void:
	if _player == null:
		return
	var bullet := bullet_scene.instantiate()
	var from := global_position + Vector2(0.0, -1.0)
	var dir := from.direction_to(_player.global_position)
	var container: Node = get_parent()
	if container == null:
		container = get_tree().current_scene
	container.add_child(bullet)
	if bullet.has_method("launch"):
		bullet.launch(dir, from)

func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	remove_from_group("enemy")
	velocity = Vector2.ZERO
	set_physics_process(false)
	var shape := get_node_or_null("CollisionShape2D")
	if shape != null:
		shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_property(self, "scale", scale * 1.4, 0.22)
	tween.chain().tween_callback(queue_free)
