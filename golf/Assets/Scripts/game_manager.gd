extends Node

# Reference to the hole object
@onready var hole: Node3D = $"../Hole" as Hole

# Star counters
var total_stars: int = 0  # Total stars in the level
var collected_stars: int = 0  # Number of collected stars

# Checkpoint tracking
var last_checkpoint_node: Node3D = null # Latest active checkpoint
var current_checkpoint_position: Vector3  # Latest active checkpoint position

# Function to switch levels
func switchtolvl(lvl):
	for obj in get_tree().get_nodes_in_group("levels"):
			obj.visible = false
			obj.position = Vector3(0,-20000,0)
	lvl.position = Vector3(0,2,0)
	lvl.visible = true
	
# Called when the scene loads
func _ready():
	await get_tree().process_frame  # Delay to ensure all nodes are initialized
	hole.level_won.connect(on_level_won)  # Subscribe to level completion event
	
	# Find and subscribe to star/checkpoint events
	find_and_subscribe_stars()
	find_and_subscribe_checkpoints()
	
	if Autoload.level == 0:
		switchtolvl($"../Floor")
	elif Autoload.level == 1:
		switchtolvl($"../grass_asphalt")
	elif Autoload.level == 2:
		switchtolvl($"../level1")
	elif Autoload.level == 3:
		switchtolvl($"../test2")
	
	# Play star animation node (using group)
	for obj in get_tree().get_nodes_in_group("Stars"):
		obj.play_animation()
		# --- For single star ---
		#var star_anim = $"../Check_star".get_node("AnimationPlayer") 
		#star_anim.play("star_anim") 
	
# Function to find all stars in the level
func find_and_subscribe_stars():
	var stars = get_tree().get_nodes_in_group("stars")  # Get all objects in the "stars" group
	total_stars = stars.size()  # Store total count

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
	Autoload.level = 0
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")

func _on_buttonChangetoGrass_pressed():
	Autoload.level = 1
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
	
func _on_buttonChangetoLvl1_pressed():
	Autoload.level = 2
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
	
func _on_buttonChangetoTest2_pressed():
	Autoload.level = 3
	get_tree().change_scene_to_file("res://Assets/Scenes/main.tscn")
