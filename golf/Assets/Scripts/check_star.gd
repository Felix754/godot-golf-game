extends Node3D

class_name Check_star

signal star_collected

func _ready():
	add_to_group("stars")  # Ensure the star is in the correct group

func _on_area_3d_body_entered(body):
	if body is GolfBall:
		print("Star collected!")  # Debug message
		star_collected.emit()
		queue_free() # Delete star
