extends Camera3D

# ------------------------ Camera configuration -------------------------
@export var target: GolfBall                         # The target to follow
@export var offset: Vector3 = Vector3(0, 3, -6)      # Default camera offset
@export var rotation_speed: float = 0.005            # Rotation sensitivity
@export var zoom_speed: float = 0.8                  # Zoom sensitivity
@export var min_distance: float = 4.0                # Minimum zoom distance
@export var max_distance: float = 20.0               # Maximum zoom distance
@export var min_pitch: float = deg_to_rad(-60)       # Min vertical angle
@export var max_pitch: float = deg_to_rad(5)         # Max vertical angle
# -----------------------------------------------------------------------

# ------------------------ Internal camera state ------------------------
var yaw: float = 0.0                       # Horizontal rotation (left/right)
var pitch: float = 0.0                     # Vertical rotation (up/down)
var rotating: bool = false                 # If player is currently rotating
var last_mouse_position: Vector2           # Last mouse position
var current_distance: float                # Current camera distance
var mouse_locked := false   # Whether the mouse is locked and rotating the camera
const JOYSTICK_ROTATE_THRESHOLD := 0.15    # Threshold for joystick rotation
# -----------------------------------------------------------------------

func _ready():
	# Initialize camera
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_distance = offset.length()
	last_mouse_position = get_viewport().get_mouse_position()

func _process(delta):
	if not target:
		return

	update_rotating_state()

	# Handle zooming
	if Input.is_action_pressed("zoom_in"):
		change_distance(-zoom_speed * delta * 10)
	elif Input.is_action_pressed("zoom_out"):
		change_distance(zoom_speed * delta * 10)

	# Update camera rotation if rotating
	if rotating:
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
		yaw -= mouse_delta.x * rotation_speed
		pitch = clamp(pitch - mouse_delta.y * rotation_speed, min_pitch, max_pitch)
		last_mouse_position = get_viewport().get_mouse_position()

		var joy_input := Controls.get_camera_input()
		yaw -= joy_input.x * rotation_speed * 50
		pitch = clamp(pitch - joy_input.y * rotation_speed * 50, min_pitch, max_pitch)

	# Calculate direction and update position
	var direction = Vector3(0, 0, 1)
	direction = direction.rotated(Vector3.RIGHT, pitch)
	direction = direction.rotated(Vector3.UP, yaw).normalized()

	var zoomed_offset = direction * current_distance
	var target_position = target.global_transform.origin
	global_transform.origin = target_position + zoomed_offset
	look_at(target_position, Vector3.UP)

func _input(event):
	# Handle zoom input from event
	if Controls.is_zoom_held(event):
		change_distance(Controls.get_zoom_direction(event) * zoom_speed)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		mouse_locked = not mouse_locked
		if mouse_locked:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func update_rotating_state():
	# Determine if the player is rotating the camera
	var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
	var joy_input := Controls.get_camera_input()
	rotating = mouse_delta.length() > 0.1 or joy_input.length() > JOYSTICK_ROTATE_THRESHOLD

func change_distance(delta: float):
	# Clamp zoom distance
	current_distance = clamp(current_distance + delta, min_distance, max_distance)
