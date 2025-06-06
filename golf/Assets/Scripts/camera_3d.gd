extends Camera3D

# ------------------------ Camera configuration -------------------------
@export var target: GolfBall						# The target to follow
@export var offset: Vector3 = Vector3(0, 3, -6)		# Default camera offset
@export var rotation_speed: float = 0.005			# Rotation sensitivity
@export var zoom_speed: float = 0.8					# Zoom sensitivity
@export var min_distance: float = 4.0				# Minimum zoom distance
@export var max_distance: float = 20.0				# Maximum zoom distance
@export var min_pitch: float = deg_to_rad(-60)		# Min vertical angle
@export var max_pitch: float = deg_to_rad(5)		# Max vertical angle
@export var invert_mouse_x := false					# Invert horizontal mouse movement
@export var invert_mouse_y := false					# Invert vertical mouse movement
# -----------------------------------------------------------------------

# ------------------------ Internal camera state ------------------------
var yaw: float = 0.0						# Horizontal rotation (left/right)
var pitch: float = 0.0						# Vertical rotation (up/down)
var rotating: bool = false					# If player is currently rotating
var last_mouse_position: Vector2			# Last mouse position
var current_distance: float					# Current camera distance
var mouse_locked := false					# Whether the mouse is locked for rotation
const JOYSTICK_ROTATE_THRESHOLD := 0.15		# Threshold for joystick rotation
var is_upside_down := false					# Is the camera upside-down (affects up vector)
# -----------------------------------------------------------------------

func _ready():
	# Initialize camera state
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	current_distance = offset.length()
	last_mouse_position = get_viewport().get_mouse_position()

func _process(delta):
	if not target:
		return

	update_rotating_state()

	# Zoom with keyboard
	if Input.is_action_pressed("zoom_in"):
		change_distance(-zoom_speed * delta * 10)
	elif Input.is_action_pressed("zoom_out"):
		change_distance(zoom_speed * delta * 10)

	# Rotate with joystick input
	if rotating:
		var joy_input := Controls.get_camera_input()
		yaw -= joy_input.x * rotation_speed * 50
		pitch = clamp(pitch - joy_input.y * rotation_speed * 50, min_pitch, max_pitch)

	# Compute camera direction
	var direction = Vector3(0, 0, 1)
	direction = direction.rotated(Vector3.RIGHT, pitch)
	direction = direction.rotated(Vector3.UP, yaw).normalized()

	# Calculate camera position
	var target_position = target.global_transform.origin
	var desired_position = target_position + direction * current_distance

	# Avoid clipping with raycast
	var space_state = get_world_3d().direct_space_state
	var ray_params = PhysicsRayQueryParameters3D.create(target_position, desired_position)
	ray_params.exclude = [target.get_rid()]  # Ignore the target
	var result = space_state.intersect_ray(ray_params)

	var final_position = desired_position
	if result:
		final_position = result.position - direction * 0.2  # Slight offset from obstacle

	# Set camera position and orientation
	global_transform.origin = final_position
	look_at(target_position, -Vector3.UP if is_upside_down else Vector3.UP)

func _input(event):
	# Zoom with input event
	if Controls.is_zoom_held(event):
		change_distance(Controls.get_zoom_direction(event) * zoom_speed)

	# Toggle mouse capture for rotation
	if Input.is_action_just_pressed("debug_navigation"):
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

	# Rotate with mouse if captured
	if mouse_locked and event is InputEventMouseMotion:
		var mouse_delta = event.relative

		var x = -mouse_delta.x if invert_mouse_x else mouse_delta.x
		var y = -mouse_delta.y if invert_mouse_y else mouse_delta.y

		yaw -= x * rotation_speed
		pitch = clamp(pitch - y * rotation_speed, min_pitch, max_pitch)

# Updates whether camera is in a rotating state
func update_rotating_state():
	var joy_input := Controls.get_camera_input()
	
	if not mouse_locked:
		# Allow joystick-only rotation if mouse is not captured
		rotating = joy_input.length() > JOYSTICK_ROTATE_THRESHOLD
		return

	# If mouse is captured, check both mouse and joystick movement
	var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
	rotating = mouse_delta.length() > 0.1 or joy_input.length() > JOYSTICK_ROTATE_THRESHOLD

# Adjust zoom distance within allowed limits
func change_distance(delta: float):
	current_distance = clamp(current_distance + delta, min_distance, max_distance)
