# CheckPoint triger
extends Area3D
class_name CheckPointArea

signal checkpoint_reached(position: Vector3)
@export var is_start: bool = false
@export var shape_resource: Shape3D

func _ready():
	var shape = CollisionShape3D.new()
	shape.shape = shape_resource
	add_child(shape)

	
func _on_body_entered(body):
	if body is GolfBall:
		checkpoint_reached.emit(global_transform.origin)
