extends Node

@onready var hole: Node3D = $"../Hole" as Hole

func _ready():
	hole.level_won.connect(on_level_won)


func on_level_won():
	print("LEVEL WON")
