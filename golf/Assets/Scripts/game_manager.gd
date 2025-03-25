extends Node

@onready var hole: Node3D = $"../Hole" as Hole

func _ready():
	hole.level_won.connect(on_level_won)


func on_level_won():
	print("LEVEL WON")

func _on_buttonChangetoTest_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
func _on_buttonChangetoGrass_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn") # todo: replace with new grass level
