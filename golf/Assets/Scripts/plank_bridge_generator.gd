extends Node3D

@export var plank_scene: PackedScene
@export var plank_count: int = 10
@export var plank_spacing: float = 1.2
@export var break_delay: float = 5.0

func _ready():
	for i in range(plank_count):
		var plank = plank_scene.instantiate()
		add_child(plank)
		plank.transform.origin = Vector3(i * plank_spacing, 0, 0)
		
		if plank.has_method("set_break_delay"):
			plank.set_break_delay(break_delay)
