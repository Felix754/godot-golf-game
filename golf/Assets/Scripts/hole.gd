extends Node3D

class_name Hole

signal level_won


func _on_area_3d_body_entered(body):
	if body is GolfBall:
		level_won.emit()
