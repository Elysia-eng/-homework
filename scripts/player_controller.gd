extends CharacterBody2D

@export_category("移动参数")
@export var move_speed: float = 75.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var jump_velocity: float = -190.0
@export var max_jumps: int = 2

@export_category("飞行参数")
@export var fly_speed: float = 90.0
@export var fly_acceleration: float = 300.0

@export_category("射击参数")
@export var bullet_scene: PackedScene
@export var shoot_damage: int = 1
@export var shoot_cooldown: float = 0.25

@export_category("闪现参数")
@export var dash_distance: float = 34.0
@export var dash_cooldown: float = 0.45
@export var double_press_interval: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var shoot_point: Marker2D = $ShootPoint

var flying: bool = false
var jumps_left: int = 2
var shoot_timer: float = 0.0
var dash_timer: float = 0.0
var spawn_position: Vector2 = Vector2.ZERO
var _last_left_press: int = -100000
var _last_right_press: int = -100000

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	jumps_left = max_jumps

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won:
		velocity = Vector2.ZERO
		return

	shoot_timer = maxf(shoot_timer - delta, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	_handle_dash_input()

	if flying:
		_handle_fly_vertical(delta)
	else:
		_apply_gravity(delta)
		if Input.is_action_just_pressed("jump"):
			_try_jump()

	_handle_horizontal_movement(delta)

	if _shoot_pressed() and shoot_timer <= 0.0:
		_shoot()

	_update_sprite_direction()
	move_and_slide()

	if not flying and is_on_floor():
		jumps_left = max_jumps

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_game_over or GameManager.is_game_won:
		return
	if event.is_action_pressed("fly") and not event.is_echo():
		_toggle_fly()
		get_viewport().set_input_as_handled()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_fly_vertical(delta: float) -> void:
	var direction := Input.get_axis("squat", "jump")
	var target_speed := direction * fly_speed
	velocity.y = move_toward(velocity.y, target_speed, fly_acceleration * delta)

func _handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var top_speed := fly_speed if flying else move_speed
	var accel := fly_acceleration if flying else acceleration
	var brake := fly_acceleration if flying else deceleration

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * top_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, brake * delta)

func _try_jump() -> void:
	if is_on_floor():
		jumps_left = max_jumps
	if jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

func _toggle_fly() -> void:
	flying = not flying
	if flying:
		velocity = velocity.lerp(Vector2.ZERO, 0.5)
	else:
		jumps_left = maxi(jumps_left, 1)

func _shoot_pressed() -> bool:
	return InputMap.has_action("shoot") and Input.is_action_pressed("shoot")

func _shoot() -> void:
	if bullet_scene == null:
		return
	shoot_timer = shoot_cooldown
	var bullet := bullet_scene.instantiate()
	var from: Vector2 = shoot_point.global_position if shoot_point != null else global_position
	var to: Vector2 = get_global_mouse_position()
	var dir := from.direction_to(to)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var container: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
	container.add_child(bullet)
	if bullet.has_method("launch"):
		bullet.launch(dir, from)
	bullet.set("damage", shoot_damage)

func _update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0

func _handle_dash_input() -> void:
	var now := Time.get_ticks_msec()
	if Input.is_action_just_pressed("move_left"):
		if now - _last_left_press <= int(double_press_interval * 1000.0):
			_last_left_press = -100000
			_try_dash(-1)
		else:
			_last_left_press = now
	elif Input.is_action_just_pressed("move_right"):
		if now - _last_right_press <= int(double_press_interval * 1000.0):
			_last_right_press = -100000
			_try_dash(1)
		else:
			_last_right_press = now

func _try_dash(direction: int) -> void:
	if dash_timer > 0.0:
		return
	dash_timer = dash_cooldown

	var from := global_position
	var to := from + Vector2(direction * dash_distance, 0.0)

	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to, 1, [get_rid()])
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var wall: Vector2 = hit["position"]
		to = wall - Vector2(direction * 7.0, 0.0)
		if direction > 0:
			to.x = maxf(to.x, from.x)
		else:
			to.x = minf(to.x, from.x)

	global_position = to
	velocity.x = direction * move_speed
	_play_dash_effect()

func _play_dash_effect() -> void:
	if sprite == null:
		return
	sprite.modulate = Color(0.72, 0.94, 1.0, 0.9)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25)
