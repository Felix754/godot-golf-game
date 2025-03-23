extends RigidBody3D
class_name GolfBall 

@export var max_force: float = 400.0  # Maximum hit force
@export var min_force: float = 10.0   # Minimum hit force
@export var charge_time: float = 2.0  # Full charge time (seconds)
@export var camera: Camera3D
@export var cooldown_time: float = 2.0  # Cooldown time after hit

var can_push: bool = true  
var charging: bool = false  
var charge_amount: float = min_force  # Initial charge level
var friction_factor: float = 1.0  # Friction factor for the surface

# Friction coefficients for different types of surfaces
var friction_table = {
	0.1: 0.995,  # Ice – very low friction
	0.3: 0.9,    # Grass – slightly lower friction
	0.5: 0.95,   # Concrete – moderate friction
	1.0: 0.88    # Sand – softer braking
}

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.1  # Timer interval for checking surface
	timer.autostart = true
	timer.timeout.connect(check_surface)  # Connect surface check function to the timer
	add_child(timer)

func _input(event):
	# Start charging when the space key is pressed
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed and can_push and not charging:
			charging = true
			charge_amount = min_force  # Reset charge before starting a new charge
			print("Charging started")

		# Hit when space key is released
		elif not event.pressed and charging:
			charging = false
			push_towards_camera()  # Apply the force towards the camera's direction
			can_push = false
			await get_tree().create_timer(cooldown_time).timeout  # Wait for cooldown before next hit
			can_push = true  

func _process(delta):
	# Increase hit force while charging
	if charging:
		var charge_rate = (max_force - min_force) / charge_time  # Calculate charge rate based on time
		charge_amount = min(charge_amount + charge_rate * delta, max_force)  # Clamp the charge to the maximum force
		print("Charging... Current force:", charge_amount)  # Print the charging progress

func push_towards_camera():
	if not camera:
		return
	
	var direction = (global_transform.origin - camera.global_transform.origin).normalized()  # Get direction towards camera
	direction.y = 0  # Ignore vertical direction
	direction = direction.normalized()  # Normalize direction to avoid large force

	apply_central_impulse(direction * charge_amount)  # Apply the calculated force to the ball
	print("Ball hit with force:", charge_amount)  # Print the hit force

func _physics_process(delta):
	check_surface()  # Check the surface friction during each physics frame
	# The slower the ball, the less braking effect there is
	
	# Get the damping factor from the friction factor
	var damping = 1.0 - (friction_factor * delta * 5.0)  
	linear_velocity.x *= max(0.0, damping)  # Apply damping to X velocity
	linear_velocity.z *= max(0.0, damping)  # Apply damping to Z velocity

	if linear_velocity.length() < 0.05:  # Stop the ball if the velocity is too small
		linear_velocity = Vector3.ZERO

# Surface detection logic
var previous_friction_factor: float = -1.0  # Store previous friction factor to detect changes

func check_surface():
	var space_state = get_world_3d().direct_space_state
	var from = global_transform.origin
	var to = from - Vector3(0, 5, 0)  # Raycast downwards to detect surface

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false  # Ignore areas (for performance)
	query.collide_with_bodies = true  # Detect collisions with bodies

	var result = space_state.intersect_ray(query)  # Perform the raycast

	if result:
		if result.has("collider"):
			var collider = result["collider"]
			if collider is StaticBody3D and collider.physics_material_override:
				var material = collider.physics_material_override
				friction_factor = material.friction  # Get friction from the surface's physics material
			else:
				friction_factor = 0.0  # No friction if the surface doesn't have a material
		else:
			friction_factor = 0.0  # No friction if no surface is detected
	else:
		friction_factor = 0.0  # No friction if raycast hits nothing

	# Print a message only if the friction factor has changed
	if friction_factor != previous_friction_factor:
		print("Friction factor changed:", friction_factor)  # Log the friction change
		previous_friction_factor = friction_factor  # Update the previous friction factor
