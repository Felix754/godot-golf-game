extends Camera3D

# ---------------- Camera configuration ----------------
@export var target: GolfBall						# The object the camera follows
@export var offset: Vector3 = Vector3(0, 3, -6)		# Initial camera offset
@export var rotation_speed: float = 0.005			# Mouse rotation sensitivity
@export var zoom_speed: float = 0.5					# Scroll zoom speed
@export var min_distance: float = 4.0				# Minimum zoom distance
@export var max_distance: float = 20.0				# Maximum zoom distance
@export var min_pitch: float = deg_to_rad(-60)		# Minimum vertical angle
@export var max_pitch: float = deg_to_rad(5)		# Maximum vertical angle
# -----------------------------------------------------

# ---------------- Internal state ---------------------
var yaw: float = 0.0				# Horizontal angle (left-right)
var pitch: float = 0.0				# Vertical angle (up-down)
var rotating: bool = false			# Whether the camera is being rotated
var last_mouse_position: Vector2	# Last mouse position used to calculate delta
var current_distance: float			# Current zoom distance
# -----------------------------------------------------
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	# Show the mouse cursor
	current_distance = offset.length()				# Set initial zoom distance

func _process(delta):
	if not target:
		return

	var target_position = target.global_transform.origin

	# If rotating, update yaw and pitch based on mouse movement
	if rotating:
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
		yaw -= mouse_delta.x * rotation_speed
		pitch = clamp(pitch - mouse_delta.y * rotation_speed, min_pitch, max_pitch)
		last_mouse_position = get_viewport().get_mouse_position()

	# Calculate camera direction from pitch and yaw
	var direction = Vector3(0, 0, 1)
	direction = direction.rotated(Vector3.RIGHT, pitch)
	direction = direction.rotated(Vector3.UP, yaw)
	direction = direction.normalized()

	# Apply zoom and update camera position
	var zoomed_offset = direction * current_distance
	global_transform.origin = target_position + zoomed_offset

	# Always look at the target
	look_at(target_position, Vector3.UP)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
			last_mouse_position = get_viewport().get_mouse_position()

	if event is InputEventMouseMotion and rotating:
		# Update rotation if dragging mouse
		var mouse_delta = event.relative
		yaw -= mouse_delta.x * rotation_speed
		pitch = clamp(pitch - mouse_delta.y * rotation_speed, min_pitch, max_pitch)

	if event is InputEventMouseButton and event.is_pressed():
		# Handle zoom in/out
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_distance(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_distance(zoom_speed)

func change_distance(delta: float):
	# Clamp zoom distance between min and max values
	current_distance = clamp(current_distance + delta, min_distance, max_distance)
