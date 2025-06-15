extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var parent = get_parent()
		if parent:
			var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_IN)
			fade_tween.tween_property(parent, "modulate:a", 0, 0.3)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var parent = get_parent()
		if parent:
			var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT)
			fade_tween.tween_property(parent, "modulate:a", 1, 0.3)
