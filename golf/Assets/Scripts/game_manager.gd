extends Node

# Reference to the hole object
@onready var hole: Node3D = $"../Hole" as Hole

# Star counters
var total_stars: int = 0  # Total stars in the level
var collected_stars: int = 0  # Number of collected stars

# Called when the scene loads
func _ready():
	await get_tree().process_frame  # Delay to ensure all nodes are initialized
	hole.level_won.connect(on_level_won)  # Subscribe to level completion event
	
	find_and_subscribe_stars()  # Find and subscribe to star events

# Function to find all stars in the level
func find_and_subscribe_stars():
	var stars = get_tree().get_nodes_in_group("stars")  # Get all objects in the "stars" group
	total_stars = stars.size()  # Store total count

	# Subscribe to each star's collected event
	for star in stars:
		star.star_collected.connect(on_star_collected)

	print("Total stars on level:", total_stars)

# Called when a star is collected
func on_star_collected():
	collected_stars += 1
	print("Collected %d/%d stars" % [collected_stars, total_stars])

# Called when the level is won
func on_level_won():
	print("LEVEL WON")

# Button functions to change levels
func _on_buttonChangetoTest_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")

func _on_buttonChangetoGrass_pressed():
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn") # TODO: replace with new grass level
