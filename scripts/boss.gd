extends CharacterBody2D

@export_category("Boss 属性")
@export var max_health: int = 20
@export var shoot_interval: float = 10.0

@export_category("八方向弹幕")
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 1
@export var bullet_speed: float = 150.0
@export var spawn_offset: float = 16.0

@export_category("阶段与无敌")
@export var phase2_at_health: int = 10
@export var invulnerable_duration: float = 10.0
@export var flash_interval: float = 0.15
@export var phase2_interval_scale: float = 0.5

@export_category("第二阶段飞行")
@export var fly_speed: float = 90.0
@export var fly_frequency: float = 1.8

@export_category("血条显示范围")
@export var bar_visible_range: float = 320.0

const EIGHT_DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, -1),
	Vector2(0, -1),
	Vector2(1, -1),
]

var _shoot_timer: float = 0.0
var _invulnerable: bool = false
var _invuln_timer: float = 0.0
var _phase: int = 1
var _flying: bool = false
var _fly_time: float = 0.0
var _bar_shown: bool = false
var _sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("enemy")
	_shoot_timer = shoot_interval
	_sprite = get_node_or_null("Sprite")
	GameManager.register_boss(max_health)
	GameManager.set_boss_bar_visible(false)

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won:
		velocity = Vector2.ZERO
		return

	_update_bar_visibility()

	if _flying:
		_fly_time += delta
		velocity.x = 0.0
		velocity.y = sin(_fly_time * fly_frequency) * fly_speed
		move_and_slide()
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = 0.0
		move_and_slide()

	_update_invulnerability(delta)

	_shoot_timer = maxf(_shoot_timer - delta, 0.0)
	if _shoot_timer <= 0.0:
		_shoot_timer = _current_interval()
		_fire_eight_directions()

func _current_interval() -> float:
	if _phase >= 2:
		return shoot_interval * phase2_interval_scale
	return shoot_interval

func _update_bar_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var near: bool = global_position.distance_to((player as Node2D).global_position) <= bar_visible_range
	if near != _bar_shown:
		_bar_shown = near
		GameManager.set_boss_bar_visible(near)
		print("[Boss] 玩家进入范围 = ", near, "（距离阈值 ", bar_visible_range, "）")

func _fire_eight_directions() -> void:
	if bullet_scene == null:
		return
	for dir in EIGHT_DIRECTIONS:
		_spawn_bullet(dir.normalized())

func _spawn_bullet(dir: Vector2) -> void:
	var bullet := bullet_scene.instantiate()
	var container: Node = get_parent()
	if container == null:
		container = get_tree().current_scene
	container.add_child(bullet)
	if bullet.has_method("launch"):
		bullet.launch(dir, global_position + dir * spawn_offset)
	bullet.set("speed", bullet_speed)
	bullet.set("damage", bullet_damage)
	bullet.set("from_boss", true)

func _update_invulnerability(delta: float) -> void:
	if not _invulnerable:
		return
	_invuln_timer -= delta
	if _sprite != null:
		_sprite.modulate.a = 0.35 if int(_invuln_timer / flash_interval) % 2 == 0 else 1.0
	if _invuln_timer <= 0.0:
		_invulnerable = false
		if _sprite != null:
			_sprite.modulate.a = 1.0
		print("[Boss] 无敌结束")
		GameManager.enable_reflect()

func _start_invulnerable() -> void:
	_invulnerable = true
	_invuln_timer = invulnerable_duration
	print("[Boss] 血量剩 ", GameManager.boss_health, "，进入 ", invulnerable_duration, " 秒无敌")

func is_invulnerable() -> bool:
	return _invulnerable

func current_phase() -> int:
	return _phase

func is_flying() -> bool:
	return _flying

func take_damage(amount: int = 1) -> void:
	if _invulnerable:
		return
	GameManager.damage_boss(amount)
	if GameManager.boss_health <= 0:
		die()
		return
	if _phase == 1 and GameManager.boss_health <= phase2_at_health:
		_phase = 2
		_flying = true
		_fly_time = 0.0
		_start_invulnerable()
		print("[Boss] 进入第二阶段：射击间隔变为 ", _current_interval(), " 秒，开始飞行")

func die() -> void:
	remove_from_group("enemy")
	velocity = Vector2.ZERO
	set_physics_process(false)
	var shape := get_node_or_null("CollisionShape2D")
	if shape != null:
		shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_property(self, "scale", scale * 1.6, 0.6)
	tween.chain().tween_callback(queue_free)
