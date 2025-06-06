extends Area3D

# Reference to the main camera in the current scene
@onready var camera: Camera3D = get_tree().get_current_scene().get_node("Camera3D")

# Whether gravity has been inverted
var gravity_inverted := false

func _on_body_entered(body: Node) -> void:
	if body is GolfBall:
		# Invert gravity scale and internal state on the ball
		body.gravity_scale *= -1
		body.gravity_inverted = !body.gravity_inverted

		# Invert camera and input mappings
		swap_and_invert_camera()
		invert_input_mappings()

# Swaps min and max pitch of camera, flips axes and state
func swap_and_invert_camera():
	var tmp = camera.min_pitch
	camera.min_pitch = -camera.max_pitch
	camera.max_pitch = -tmp
	camera.is_upside_down = !camera.is_upside_down
	camera.invert_mouse_x = !camera.invert_mouse_x
	camera.invert_mouse_y = !camera.invert_mouse_y

# Swaps paired input actions for movement and camera
func invert_input_mappings():
	var input_pairs = [
		["look_left", "look_right"],
		["look_up", "look_down"],
		["move_arrow_up", "move_arrow_down"],
		["move_arrow_left", "move_arrow_right"]
	]

	for pair in input_pairs:
		var action_a = pair[0]
		var action_b = pair[1]

		var events_a = InputMap.action_get_events(action_a)
		var events_b = InputMap.action_get_events(action_b)

		# Clear both actions
		InputMap.action_erase_events(action_a)
		InputMap.action_erase_events(action_b)

		# Reassign swapped events
		for event in events_b:
			InputMap.action_add_event(action_a, event)
		for event in events_a:
			InputMap.action_add_event(action_b, event)

	print("All input mappings successfully inverted.")
