extends Node

# Reference to the hole object
@onready var hole: Node3D = $"../Hole" as Hole

# Star counters
var total_stars: int = 0  # Total stars in the level
var collected_stars: int = 0  # Number of collected stars

# Checkpoint tracking
var last_checkpoint_node: Node3D = null # Latest active checkpoint
var current_checkpoint_position: Vector3  # Latest active checkpoint position


# Called when the scene loads
func _ready():
	await get_tree().process_frame  # Delay to ensure all nodes are initialized
	hole.level_won.connect(on_level_won)  # Subscribe to level completion event
	
	# Find and subscribe to star/checkpoint events
	find_and_subscribe_stars()
	find_and_subscribe_checkpoints()

# Function to find all stars in the level
func find_and_subscribe_stars():
	var stars = get_tree().get_nodes_in_group("stars")  # Get all objects in the "stars" group
	total_stars = stars.size()

	# Subscribe to each star's collected event
	for star in stars:
		star.star_collected.connect(on_star_collected)

	print("Total stars on level:", total_stars)

# Discover and listen to all checkpoint nodes
func find_and_subscribe_checkpoints():
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for cp in checkpoints:
		cp.checkpoint_reached.connect(on_checkpoint_reached)
		#print("Subscribed to checkpoint:", cp.name)

		# Set starting checkpoint position if marked as starting point
		if cp.is_start:
			current_checkpoint_position = cp.global_transform.origin
			print("Starting checkpoint set:", current_checkpoint_position)

# Update the current checkpoint when reached
func on_checkpoint_reached(pos: Vector3):
	current_checkpoint_position = pos
	print("Checkpoint updated:", pos)



# Reset the ball's position to the last active checkpoint
func reset_to_checkpoint(ball: Node3D):
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	var new_transform = ball.global_transform
	new_transform.origin = current_checkpoint_position
	ball.global_transform = new_transform
	print("Resetting to:", current_checkpoint_position)


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
