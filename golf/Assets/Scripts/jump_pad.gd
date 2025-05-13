# JumpPad.gd
extends Area3D

@export var jump_force: float = 120.0

func _on_body_entered(body):
	if body is GolfBall:
		body.linear_velocity.y = jump_force
		print("Jump pad force: ", jump_force)
		
