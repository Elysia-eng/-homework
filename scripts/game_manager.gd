extends Node

signal health_changed(health: int, max_health: int)
signal coins_changed(coins: int)
signal checkpoint_activated(world_position: Vector2)
signal boss_health_changed(health: int, max_health: int)
signal boss_registered
signal keys_changed(count: int)
signal key_collected(key_id: int)
signal respawn_requested
signal game_over
signal game_won

const MAX_HEALTH: int = 10
const RESPAWN_COST: int = 5

var max_health: int = MAX_HEALTH
var health: int = MAX_HEALTH
var coins: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var has_checkpoint: bool = false
var is_game_over: bool = false
var is_game_won: bool = false
var boss_max_health: int = 0
var boss_health: int = 0
var keys_collected: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_state()

func reset_state() -> void:
	max_health = MAX_HEALTH
	health = MAX_HEALTH
	coins = 0
	checkpoint_position = Vector2.ZERO
	has_checkpoint = false
	is_game_over = false
	is_game_won = false
	boss_max_health = 0
	boss_health = 0
	keys_collected.clear()
	health_changed.emit(health, max_health)
	coins_changed.emit(coins)
	boss_health_changed.emit(boss_health, boss_max_health)
	keys_changed.emit(keys_collected.size())

func add_coins(amount: int = 1) -> void:
	coins = maxi(coins + amount, 0)
	coins_changed.emit(coins)

func collect_key(key_id: int) -> void:
	if has_key(key_id):
		return
	keys_collected.append(key_id)
	keys_changed.emit(keys_collected.size())
	key_collected.emit(key_id)
	print("[Game] 获得钥匙 ", key_id, "，共 ", keys_collected.size(), " 把")

func has_key(key_id: int) -> bool:
	return keys_collected.has(key_id)

func activate_checkpoint(world_position: Vector2) -> void:
	checkpoint_position = world_position
	has_checkpoint = true
	checkpoint_activated.emit(world_position)

func damage_player(amount: int = 1) -> void:
	if is_game_over or is_game_won:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		_handle_zero_health()

func heal_player(amount: int) -> void:
	if is_game_over or is_game_won:
		return
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health, max_health)

func _handle_zero_health() -> void:
	if coins >= RESPAWN_COST:
		add_coins(-RESPAWN_COST)
		health = max_health
		health_changed.emit(health, max_health)
		respawn_requested.emit()
	else:
		trigger_game_over()

func register_boss(max_hp: int) -> void:
	boss_max_health = max_hp
	boss_health = max_hp
	boss_health_changed.emit(boss_health, boss_max_health)
	boss_registered.emit()

func damage_boss(amount: int = 1) -> void:
	if boss_max_health <= 0:
		return
	boss_health = maxi(boss_health - amount, 0)
	boss_health_changed.emit(boss_health, boss_max_health)
	if boss_health <= 0:
		trigger_victory()

func trigger_game_over() -> void:
	if is_game_over or is_game_won:
		return
	is_game_over = true
	health = 0
	health_changed.emit(health, max_health)
	get_tree().paused = true
	game_over.emit()

func trigger_victory() -> void:
	if is_game_won or is_game_over:
		return
	is_game_won = true
	get_tree().paused = true
	game_won.emit()

func restart_game() -> void:
	get_tree().paused = false
	reset_state()
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if not (is_game_over or is_game_won):
		return
	var pressed_restart := event.is_action_pressed("restart") if InputMap.has_action("restart") else false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		pressed_restart = true
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		pressed_restart = true
	if pressed_restart:
		get_viewport().set_input_as_handled()
		restart_game()
