extends Node3D

@export var laser_length: float = 5.0
var laser_width: float = 1
var laser_height: float = 1
@export var laser_material: Material  # Optional material for the beam

var game_manager: Node = null  # Reference to the GameManager node

func _ready():
	# Find the GameManager node in the current scene
	if not game_manager:
		game_manager = find_game_manager()
	if not game_manager:
		push_error("GameManager not found in scene tree!")
	# Update laser geometry and visuals
	update_laser()

func find_game_manager() -> Node:
	# Returns the GameManager node from the current scene root, if present
	var root = get_tree().get_current_scene()
	if root:
		return root.get_node_or_null("GameManager")
	return null

func _on_collision_area_body_entered(body: Node3D) -> void:
	# React to the GolfBall entering the laser area
	if body is GolfBall and game_manager:
		print("WORKING")
		game_manager.reset_to_checkpoint(body)
	elif body is GolfBall:
		print("NOT WORKING - GameManager not set")

func update_laser():
	# Position the laser's endpoints
	$LeftEnd.position = Vector3(-laser_length / 2.0, 0, 0)
	$RightEnd.position = Vector3(laser_length / 2.0, 0, 0)

	# Scale and position the laser beam
	$LaserBeam.position = Vector3(0, 0, 0)
	$LaserBeam.scale = Vector3(laser_length, laser_height, laser_width)

	# Apply material if set
	if laser_material:
		$LaserBeam.material_override = laser_material

	# Configure the collision shape to match the laser dimensions
	var collision_shape = $CollisionArea.get_node("CollisionShape3D")
	if collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = Vector3(laser_length, laser_height, laser_width)
	else:
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.size = Vector3(laser_length, laser_height, laser_width)

	# Reset position of the collision area
	$CollisionArea.position = Vector3(0, 0, 0)
