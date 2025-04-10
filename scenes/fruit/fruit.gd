extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🍎 fruit")
		body.collect_fruit()
		await get_tree().create_timer(0.1).timeout
		queue_free()
