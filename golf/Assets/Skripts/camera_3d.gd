extends Camera3D

@export var target: GolfBall  # The object (golf ball) the camera follows
@export var offset: Vector3 = Vector3(0, 3, -6)  # Initial camera position offset
@export var rotation_speed: float = 0.005  # Mouse rotation sensitivity
@export var zoom_speed: float = 0.5  # Zoom in/out speed
@export var min_distance: float = 4.0  # Minimum distance from the target
@export var max_distance: float = 15.0  # Maximum distance from the target

var yaw: float = 0.0  # Rotation angle around the Y axis
var rotating: bool = false  # Whether the camera is currently rotating
var last_mouse_position: Vector2  # Mouse position before rotation
var current_distance: float  # Current distance from the target

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Make the cursor visible
	current_distance = offset.length()  # Initialize the distance

func _process(delta):
	if not target:
		return
	
	# Get the position of the golf ball
	var target_position = target.global_transform.origin

	# Camera rotation when the left mouse button is pressed
	if rotating:
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
		yaw -= mouse_delta.x * rotation_speed  # Adjust yaw based on mouse movement
		last_mouse_position = get_viewport().get_mouse_position()

	# Calculate the camera's offset position
	var direction = offset.normalized()  # Camera direction
	var zoomed_offset = direction * current_distance  # Scaled offset vector based on current distance
	var rotated_offset = zoomed_offset.rotated(Vector3.UP, yaw)  # Rotate camera based on yaw
	
	# Instantly update the camera's position
	global_transform.origin = target_position + rotated_offset
	
	# Make the camera look at the golf ball
	look_at(target_position, Vector3.UP)

func _input(event):
	# Rotate camera on left mouse button click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed  # Start or stop rotation
			last_mouse_position = get_viewport().get_mouse_position()

	# Handle mouse motion for rotating the camera
	if event is InputEventMouseMotion and rotating:
		var mouse_delta = event.relative
		yaw -= mouse_delta.x * rotation_speed  # Adjust yaw during motion

	# Handle zoom in and zoom out
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_distance(-zoom_speed)  # Zoom in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_distance(zoom_speed)  # Zoom out

# Change the camera's distance from the target
func change_distance(delta: float):
	current_distance = clamp(current_distance + delta, min_distance, max_distance)  # Clamp the distance within the specified range
