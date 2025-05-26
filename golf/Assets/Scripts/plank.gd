extends StaticBody3D

var break_delay: float = 5.0

func set_break_delay(delay: float) -> void:
	break_delay = delay

func _on_area_3d_body_entered(body):
	if body is GolfBall:
		print("Plank triggered - breaking in ", break_delay, " seconds")
		await get_tree().create_timer(break_delay).timeout
		queue_free()
