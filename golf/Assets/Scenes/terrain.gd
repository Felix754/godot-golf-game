extends Node3D
'''
func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: Node):
	if body is GolfBall:
		print("Golf ball touched terrain – resetting to checkpoint")
		if body.game_manager:
			body.game_manager.reset_to_checkpoint(body)
'''
