extends RigidBody3D
class_name GolfBall

# ----------------------- Hit force configuration -----------------------
@export var max_force: float = 400.0		# Maximum hit force
@export var min_force: float = 10.0			# Minimum hit force
@export var charge_time: float = 2.0		# Time to charge from min to max force
@export var camera: Camera3D				# Reference to the camera
@export var cooldown_time: float = 1.0		# Cooldown between hits
@export var stop_threshold: float = 0.03	# Speed threshold to consider the ball stopped
@onready var arrow = $"../arrow"			# Reference to the direction arrow
@export var arrow_rotation_speed := 2.5		# Speed at which the arrow rotates
@export var arrow_distance := 5.0			# Distance from ball to arrow
var arrow_angle := 0.0						# Current angle of the arrow
var charging_up := true  # true = increasing, false = decreasing
#------------------------------------------------------------------------

# ----------------------- Hit control state -----------------------------
var can_push: bool = true				# Whether the ball can be hit
var charging: bool = false				# Whether the player is holding the hit key
var charge_amount: float = min_force	# Current charged force
# -----------------------------------------------------------------------

var game_manager: Node = null     # Reference to the game manager

# ----------------------- Surface properties ----------------------------
var friction_factor: float = 1.0		# Current surface friction
var bounciness: float = 0.5			 	# Current surface bounciness
# -----------------------------------------------------------------------

# ----------------------- Surface material mappings ---------------------
var friction_table = {	# Maps material friction to damping
	0.1: 0.995,
	0.3: 0.9,
	0.5: 0.95,
	1.0: 0.88
}

var bounce_table = {	# Maps friction to bounciness
	0.1: 0.3,
	0.3: 0.3,
	0.5: 0.3,
	1.0: 0.05,
	99.0: 1.0
}
# ------------------------------------------------------------------------

var is_airborne := false					# Whether the ball is in the air
var previous_friction_factor: float = -1.0	# Previously applied friction (for change detection)

func _ready():
	# Called when the node is added to the scene
	game_manager = $"../GameManager"
	var plane_mesh = arrow.get_node("Plane") as MeshInstance3D
	var original_material = plane_mesh.get_active_material(0)
	if original_material:
		# Create a unique green material for the arrow
		var unique_material = original_material.duplicate()
		unique_material.albedo_color = Color(0, 1, 0)  # Initial color is green
		plane_mesh.set_surface_override_material(0, unique_material)
	# Set up a timer to periodically check the surface material
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.timeout.connect(check_surface)
	add_child(timer)

func _input(event):
	# Handle key input for charging and hitting the ball
	if event is InputEventKey:
		if event.pressed:
			if can_push and not charging and event.keycode == KEY_SPACE:
				charging = true
				charge_amount = min_force
				print("Charging started")
		elif not event.pressed and charging and event.keycode == KEY_SPACE:
			charging = false
			push_towards_arrow()
			can_push = false
			await get_tree().create_timer(cooldown_time).timeout
			can_push = true

func _process(delta):
	# Rotate arrow based on player input
	var angle_delta := 0.0
	if Input.is_action_pressed("ui_right"):
		angle_delta -= arrow_rotation_speed * delta
	if Input.is_action_pressed("ui_left"):
		angle_delta += arrow_rotation_speed * delta
	if angle_delta != 0.0:
		arrow_angle += angle_delta

	# Update arrow position and rotation
	if arrow:
		var offset = Vector3(
			sin(arrow_angle) * arrow_distance,
			0.1,
			cos(arrow_angle) * arrow_distance
		)
		arrow.global_position = global_position + offset
		var direction = global_position - arrow.global_position
		direction.y = 0
		direction = direction.normalized()
		var basis = Basis()
		basis.z = direction
		basis.x = basis.z.cross(Vector3.UP).normalized()
		basis.y = Vector3.UP
		arrow.global_transform.basis = basis
		arrow.rotate_y(deg_to_rad(-90))

	# Charge force and change arrow color
	if charging:
		var rate = (max_force - min_force) / charge_time

		if charging_up:
			charge_amount += rate * delta
			if charge_amount >= max_force:
				charge_amount = max_force
				charging_up = false
		else:
			charge_amount -= rate * delta
			if charge_amount <= min_force:
				charge_amount = min_force
				charging_up = true

		var arrow_material = arrow.get_node("Plane").get_active_material(0)
		var t = (charge_amount - min_force) / (max_force - min_force)
		var arrow_color = Color(t, 1.0 - t, 0.0)  # Color from green to red and back
		if arrow_material:
			arrow_material.albedo_color = arrow_color


func push_towards_arrow():
	# Apply impulse and torque in arrow direction
	if not arrow:
		return
	var direction = (arrow.global_position - global_position)
	direction.y = 0
	direction = direction.normalized()
	apply_central_impulse(direction * charge_amount)
	var torque_axis = Vector3.UP.cross(direction)
	var torque_strength = charge_amount * 0.4
	apply_torque_impulse(torque_axis * torque_strength)
	print("Ball hit in arrow direction with force:", charge_amount)
	var arrow_material = arrow.get_node("Plane").get_active_material(0)
	if arrow_material:
		arrow_material.albedo_color = Color(0, 1, 0)  # Reset to green after hit
		charge_amount = min_force
		charging_up = true


func _physics_process(delta):
	# Reset ball if it falls off the map
	if global_transform.origin.y < -110.0:
		game_manager.reset_to_checkpoint(self)
		print("Out of bounds! Resetting to:", game_manager.current_checkpoint_position)
	# Adjust angular damping based on speed
	if !is_airborne:
		var speed = linear_velocity.length()
		if speed > 5.0:
			angular_damp = 1.0
		elif speed > 1.0:
			angular_damp = 8.0
		elif speed > 0.1:
			angular_damp = 20.0
	apply_friction(delta)
	# Stop the ball if it's moving very slowly
	if linear_velocity.length() < stop_threshold:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

func apply_friction(delta: float):
	# Apply friction depending on whether the ball is airborne
	var air_multiplier = 0.2 if is_airborne else 1.0
	var damping = 1.0 - (friction_factor * delta * 5.0 * air_multiplier)
	linear_velocity.x *= max(0.0, damping)
	linear_velocity.z *= max(0.0, damping)

func check_surface():
	# Cast a ray down to detect the surface and set friction/bounciness
	var from = global_transform.origin
	var to = from - Vector3.UP * 5.0
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("collider") and result["collider"] is StaticBody3D:
		is_airborne = false
		var material = result["collider"].physics_material_override
		if material:
			var raw_friction = snapped(material.friction, 0.1)
			friction_factor = raw_friction
			bounciness = bounce_table.get(friction_factor, 0.5)
			physics_material_override.bounce = bounciness
	else:
		is_airborne = true
		friction_factor = 0.1
		angular_damp = 0.0
