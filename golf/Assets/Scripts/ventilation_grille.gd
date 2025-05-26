extends StaticBody3D

func _on_area_3d_body_entered(body):
	if body is GolfBall:
		print("Grid triggered - removing")
		queue_free()
