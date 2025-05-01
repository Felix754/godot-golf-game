extends RigidBody3D
class_name GolfBall

# ----------------------- Hit force configuration -----------------------
@export var max_force: float = 400.0		# Maximum hit force
@export var min_force: float = 10.0			# Minimum hit force
@export var charge_time: float = 2.0		# Time to fully charge the shot
@export var camera: Camera3D				# Camera used to determine hit direction
@export var cooldown_time: float = 2.0		# Cooldown time between hits
@export var stop_threshold: float = 0.03	# Ball full stop
@onready var arrow=$"/root/main/Camera3D/arrow"
#------------------------------------------------------------------------

# ----------------------- Hit control state -----------------------
var can_push: bool = true			# Can the ball currently be hit
var charging: bool = false			# Is the ball currently charging a hit
var charge_amount: float = min_force		# Accumulated charge force
# -----------------------------------------------------------------
var game_manager: Node = null
# ----------------------- Surface properties -----------------------
var friction_factor: float = 1.0		# Current friction from surface
var bounciness: float = 0.5			# Current bounce factor
#-------------------------------------------------------------------

# ----------------------- Surface material mappings -----------------------
var friction_table = {
	0.1: 0.995,	# Ice
	0.3: 0.9,	# Grass
	0.5: 0.95,	# Concrete
	1.0: 0.88	# Sand
}

var bounce_table = {
	0.1: 0.3,	# Ice – reduced bounce for smoother gameplay
	0.3: 0.3,	# Grass – soft bounce
	0.5: 0.3,	# Concrete – consistent bounce
	1.0: 0.05,	# Sand – almost no bounce
	99.0: 1.0	# Experimental surface – full bounce
}
# ------------------------------------------------------------------------

# State tracking
var is_airborne := false				# Whether the ball is currently in the air
var previous_friction_factor: float = -1.0	# Previously applied friction (for printing only)

# Called when the node is added to the scene
func _ready():
	game_manager = $"../GameManager"	
	# Timer to check surface properties periodically
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.timeout.connect(check_surface)
	add_child(timer)
	arrow.visible=false

# Input handling: spacebar to charge and hit
func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and can_push and not charging:
			charging = true
			charge_amount = min_force
			print("Charging started")
			arrow.visible = true
		elif not event.pressed and charging:
			arrow.visible=false
			charging = false
			push_towards_camera()
			can_push = false
			await get_tree().create_timer(cooldown_time).timeout
			can_push = true
			

# Called every frame: update charge if charging
func _process(delta):
	if charging:
		var rate = (max_force - min_force) / charge_time
		charge_amount = min(charge_amount + rate * delta, max_force)
		
		var arrow_material = arrow.get_node("Plane").get_active_material(0)
		var t = (charge_amount - min_force) / (max_force - min_force)
		var arrow_color = Color(t, 1.0 - t, 0.0)
		if arrow_material:
			arrow_material.albedo_color = arrow_color

# Apply impulse to ball and torque to simulate rolling direction
func push_towards_camera():
	if not camera:
		return

	# Calculate horizontal direction from camera to ball
	var direction = global_transform.origin - camera.global_transform.origin
	direction.y = 0
	direction = direction.normalized()


	# Apply impulse in that direction
	apply_central_impulse(direction * charge_amount)

	# Apply torque in opposite direction to simulate rolling
	var torque_axis = Vector3.UP.cross(direction)
	var torque_strength = charge_amount * 0.4
	apply_torque_impulse(torque_axis * torque_strength)

	print("Ball hit with force:", charge_amount)

# Called every physics frame
func _physics_process(delta):
	if global_transform.origin.y < -10.0:  # або Area3D падіння
		game_manager.reset_to_checkpoint(self)
		print("Out of bounds! Resetting to:", game_manager.current_checkpoint_position)

	# Adjust angular dampening based on speed when grounded
	if !is_airborne:
		var speed = linear_velocity.length()

		if speed > 5.0:
			angular_damp = 1.0
		elif speed > 1.0:
			angular_damp = 8.0
		elif speed > 0.1:
			angular_damp = 20.0


	apply_friction(delta)

	# Stop the ball completely if almost still
	if linear_velocity.length() < stop_threshold:
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO


# Apply linear damping (friction), reduced in air
func apply_friction(delta: float):
	var air_multiplier = 0.2 if is_airborne else 1.0
	var damping = 1.0 - (friction_factor * delta * 5.0 * air_multiplier)
	linear_velocity.x *= max(0.0, damping)
	linear_velocity.z *= max(0.0, damping)

# Detect and update surface material properties
func check_surface():
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

	if friction_factor != previous_friction_factor:
		print("Friction factor changed:", friction_factor, "| Bounciness:", bounciness)
		previous_friction_factor = friction_factor
