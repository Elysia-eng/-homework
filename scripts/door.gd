extends StaticBody2D

@export var key_id: int = 1

var _opened: bool = false
var _label: Label = null

func _ready() -> void:
	add_to_group("door")
	_label = get_node_or_null("Prompt")
	GameManager.keys_changed.connect(_on_keys_changed)
	_refresh()

func _on_keys_changed(_count: int) -> void:
	if _opened:
		return
	_refresh()
	if GameManager.has_key(key_id):
		_open()

func _refresh() -> void:
	if _label == null:
		return
	if _opened:
		_label.text = "门已打开"
	elif GameManager.has_key(key_id):
		_label.text = "钥匙已到手"
	else:
		_label.text = "需要钥匙 %d" % key_id

func _open() -> void:
	_opened = true
	_refresh()
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(queue_free)
