extends Node
class_name Controls

# -- CONTROLS -- #
# Move with arrow keys or left stick:
	# → move_arrow_right
	# ← move_arrow_left
	# ↑ move_arrow_up
	# ↓ move_arrow_down
# Look around with right stick:
	# → look_right
	# ← look_left
	# ↑ look_up
	# ↓ look_down
# Zoom camera:
	# zoom_in: Scroll up / D-pad Up
	# zoom_out: Scroll down / D-pad Down
# Camera follow toggle:
	# cam_follow: Right mouse button / Left shoulder button
# Attack / Hit:
	# hit: Space / Bottom face button (e.g. A(xbox), B(Nintedo) or Cross(PS))
# Cancel charge:
	# cancel_charge: X / Right shoulder button
# Click or debug navigation:
	# debug_navigation: Left mouse button


# ---------------------- Input configuration ----------------------------
var use_joystick := false				# Whether a joystick is currently connected
static var original_input_map := {}		# Stores original input bindings
# -----------------------------------------------------------------------

func _ready():
	# Detect joystick presence at startup
	use_joystick = Input.get_connected_joypads().size() > 0
	save_original_input_map()

func _input(event):
	# Log pressed joypad buttons (for debug)
	if event is InputEventJoypadButton and event.pressed:
		print("🔘 Joypad button pressed:", event.button_index)

# Returns whether a joystick is being used
func is_joystick() -> bool:
	return use_joystick

# ---------------------- Arrow input (aiming) ---------------------------
static func get_arrow_input() -> Vector2:
	# Get directional input from arrow keys or stick
	var x = Input.get_action_strength("move_arrow_right") - Input.get_action_strength("move_arrow_left")
	var y = Input.get_action_strength("move_arrow_down") - Input.get_action_strength("move_arrow_up")
	return Vector2(x, y)
# -----------------------------------------------------------------------

# ---------------------- Camera joystick input --------------------------
static func get_camera_input() -> Vector2:
	# Get camera direction from input and apply scaling curve
	var x := Input.get_action_strength("look_left") - Input.get_action_strength("look_right")
	var y := Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	var raw := Vector2(x, y)
	var input_len := raw.length()

	var min_input := 0.05	# Minimum input threshold
	var max_input := 1.0	# Maximum input value
	var min_sens := 0.045	# Sensitivity at minimum input
	var max_sens := 0.3		# Sensitivity at maximum input

	if input_len < min_input:
		return Vector2.ZERO

	var t := (input_len - min_input) / (max_input - min_input)
	var scaled_sens: float = lerp(min_sens, max_sens, clamp(t, 0.0, 1.0))
	return raw.normalized() * scaled_sens
# -----------------------------------------------------------------------

# ---------------------- Gameplay actions -------------------------------
static func is_following_camera() -> bool:
	return Input.is_action_pressed("cam_follow")

static func is_attack_pressed() -> bool:
	return Input.is_action_just_pressed("hit")

static func is_cancel_pressed() -> bool:
	return Input.is_action_just_pressed("cancel_charge")

static func is_camera_rotating() -> bool:
	return Input.is_action_pressed("camera_rotate")
# -----------------------------------------------------------------------

# ---------------------- Zoom controls ----------------------------------
static func is_zoom_held(event: InputEvent) -> bool:
	return event.is_action_pressed("zoom_in") or event.is_action_pressed("zoom_out")

static func get_zoom_direction(event: InputEvent) -> float:
	if event.is_action_pressed("zoom_in"):
		return -1.0
	elif event.is_action_pressed("zoom_out"):
		return 1.0
	return 0.0
# -----------------------------------------------------------------------

# Saves the original key mappings for invert restoration
static func save_original_input_map():
	original_input_map.clear()
	var actions = [
		"look_left", "look_right",
		"look_up", "look_down",
		"move_arrow_up", "move_arrow_down",
		"move_arrow_left", "move_arrow_right"
	]

	for action in actions:
		original_input_map[action] = InputMap.action_get_events(action).duplicate()

# Resets input mapping to the saved state
static func reset_input_map():
	for action in original_input_map.keys():
		InputMap.action_erase_events(action)
		for event in original_input_map[action]:
			InputMap.action_add_event(action, event)
	print("🔁 InputMap restored to original.")
