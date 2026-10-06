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

@onready var sprite: Sprite2D = $Sprite2D

var flying: bool = false
var jumps_left: int = 2
var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	jumps_left = max_jumps

func _physics_process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won:
		velocity = Vector2.ZERO
		return

	if flying:
		_handle_fly_vertical(delta)
	else:
		_apply_gravity(delta)
		if Input.is_action_just_pressed("jump"):
			_try_jump()

	_handle_horizontal_movement(delta)
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

func _update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0

func bounce(force: float) -> void:
	flying = false
	velocity.y = force
	jumps_left = max_jumps
