extends RigidBody3D
class_name GolfBall 

# Variables for hit force
@export var max_force: float = 400.0  # Maximum hit force
@export var min_force: float = 10.0   # Minimum hit force
@export var charge_time: float = 2.0  # Time required for full charge 
@export var camera: Camera3D  # Camera used to determine the hit direction
@export var cooldown_time: float = 2.0  # Cooldown time after a hit

# Variables for controlling charging and hits
var can_push: bool = true  
var charging: bool = false  
var charge_amount: float = min_force  # Current charge level

# Physical properties
var friction_factor: float = 1.0  # Surface friction factor
var bounciness: float = 0.5  # Surface bounce factor

# Friction table for different surfaces
var friction_table = {
	0.1: 0.995,  # Ice – very low friction
	0.3: 0.9,    # Grass – slightly lower friction
	0.5: 0.95,   # Concrete – moderate friction
	1.0: 0.88    # Sand – softer braking
}

# Bounciness table for different surfaces
var bounce_table = {
	0.1: 0.8,  # Ice – quite bouncy
	0.3: 0.3,  # Grass – soft bounce
	0.5: 0.5,  # Concrete – moderate bounce
	1.0: 0.05,  # Sand – almost no bounce
	99.0: 1.0  # TODO: Very bouncy surface (for future surface implementations)
}

func _ready():
	#continuous_cd = true  # Enable continuous collision detection (CCD)

	# Timer for periodically checking the surface
	var timer = Timer.new()
	timer.wait_time = 0.1  
	timer.autostart = true
	timer.timeout.connect(check_surface)  
	add_child(timer)

# Handling input events
func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and can_push and not charging:
			charging = true
			charge_amount = min_force
			print("Charging started")  # Start charging

		elif not event.pressed and charging:
			charging = false
			push_towards_camera()  # Hit the ball
			can_push = false
			await get_tree().create_timer(cooldown_time).timeout
			can_push = true  

# Update charge amount in _process
func _process(delta):
	if charging:
		var charge_rate = (max_force - min_force) / charge_time
		charge_amount = min(charge_amount + charge_rate * delta, max_force)

# Applies impulse to the ball towards the camera's direction
func push_towards_camera():
	if not camera:
		return
	
	var direction = (global_transform.origin - camera.global_transform.origin).normalized()
	direction.y = 0
	direction = direction.normalized()

	apply_central_impulse(direction * charge_amount)
	print("Ball hit with force:", charge_amount)

# Physics processing
func _physics_process(delta):
	check_surface()
	
	# Apply frictional damping
	var damping = 1.0 - (friction_factor * delta * 5.0)  
	linear_velocity.x *= max(0.0, damping)
	linear_velocity.z *= max(0.0, damping)

	# Stop the ball if it's moving too slowly
	if linear_velocity.length() < 0.05:
		linear_velocity = Vector3.ZERO

# Previous values for friction and bounciness
var previous_friction_factor: float = -1.0
var previous_bounciness: float = -1.0  

# Function to determine the surface under the ball
func check_surface():
	var space_state = get_world_3d().direct_space_state
	var from = global_transform.origin
	var to = from - Vector3(0, 5, 0)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if result.has("collider") and result["collider"] is StaticBody3D:
		var material = result["collider"].physics_material_override
		if material:
			var raw_friction = material.friction
				
			# Round friction coefficient
			friction_factor = snapped(raw_friction, 0.1)  
			bounciness = bounce_table.get(friction_factor, 0.5)  

			# Update ball material
			physics_material_override.bounce = bounciness  

	# Print updated values if they have changed
	if friction_factor != previous_friction_factor:
		print("Friction factor changed:", friction_factor, "| Bounciness:", bounciness)
		previous_friction_factor = friction_factor
