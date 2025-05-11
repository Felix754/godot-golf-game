extends Area3D
class_name WindArea

@export var wind_direction: Vector3 = Vector3(1, 0, 0) # Direction of the wind (default to right)
@export var wind_strength: float = 10.0 # Strength of the wind
@export var shape_resource: Shape3D

func _ready():
	var shape = CollisionShape3D.new()
	shape.shape = shape_resource
	add_child(shape)


# List of bodies currently inside the wind area
var bodies_in_wind: Array[RigidBody3D] = []

# Called when a body enters the wind area
func _on_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		bodies_in_wind.append(body)

# Called when a body exits the wind area
func _on_body_exited(body: Node3D) -> void:
	if body is RigidBody3D:
		bodies_in_wind.erase(body)

# Apply force to all bodies inside the wind area every physics frame
func _physics_process(delta: float) -> void:
	for body in bodies_in_wind:
		if body: # Check if the body still exists
			var force = wind_direction.normalized() * wind_strength
			body.apply_central_force(force)

#TODO: Collision shape in the main scene(Not in the wind.tscn)
# Implementation might be preaty nested, so I`ll consider to make it simplier
