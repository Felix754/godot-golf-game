extends Node

class_name Controls
var use_joystick := false

func _ready():
	use_joystick = Input.get_connected_joypads().size() > 0

func is_joystick() -> bool:
	return use_joystick

static func get_arrow_input() -> Vector2:
	var x = Input.get_action_strength("move_arrow_right") - Input.get_action_strength("move_arrow_left")
	var y = 0
	return Vector2(x, y)

static func get_camera_input() -> Vector2:
	var x = Input.get_action_strength("move_cam_right") - Input.get_action_strength("move_cam_left")
	var y = Input.get_action_strength("move_cam_down") - Input.get_action_strength("move_cam_up")
	return Vector2(x, y)

static func is_following_camera() -> bool:
	print("triggerR")
	return Input.is_action_pressed("cam_follow")

static func is_attack_pressed() -> bool:
	print('A')
	return Input.is_action_just_pressed("hit")

static func is_cancel_pressed() -> bool:
	print('B')
	return Input.is_action_just_pressed("cancel_charge")

static func debug_joystick_axes():
	
	# Log joystick axis values to debug if input is being detected
	if Input.get_connected_joypads().size() > 0:
		var device_id = Input.get_connected_joypads()[0]
		print("Axis 0 (Left Stick X): ", Input.get_joy_axis(device_id, 0))
		print("Axis 1 (Left Stick Y): ", Input.get_joy_axis(device_id, 1))
		print("Axis 2 (Right Stick X): ", Input.get_joy_axis(device_id, 2))
		print("Axis 3 (Right Stick Y): ", Input.get_joy_axis(device_id, 3))
