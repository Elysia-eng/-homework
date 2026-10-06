extends Area2D

signal coin_collected

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		coin_collected.emit()
		set_deferred("monitoring", false)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(queue_free)
