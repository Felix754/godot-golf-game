# CheckPoint triger
extends Area3D

signal checkpoint_reached(position: Vector3)
@export var is_start: bool = false


	
func _on_body_entered(body):
	if body is GolfBall:
		checkpoint_reached.emit(global_transform.origin)
