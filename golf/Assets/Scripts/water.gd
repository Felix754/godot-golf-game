extends Area3D

@export var sinking_speed: float = 2.0
@export var max_sink_velocity: float = -30.0
@export var horizontal_damping: float = 50.0  # Higher value = faster slowing down

@onready var golf_ball = null

func _on_body_entered(body):
	if body is GolfBall:
		print("Water START")
		golf_ball = body

func _on_body_exited(body):
	if body is GolfBall:
		print("Water END")
		golf_ball = null

func _physics_process(delta):
	if golf_ball and golf_ball.is_inside_tree():
		var vel = golf_ball.linear_velocity
		# Simulate downward sinking motion
		vel.y = max(vel.y - sinking_speed * delta, max_sink_velocity)
		# Sharply reduce horizontal speed
		vel.x = move_toward(vel.x, 0.0, horizontal_damping * delta)
		vel.z = move_toward(vel.z, 0.0, horizontal_damping * delta)
		golf_ball.linear_velocity = vel
