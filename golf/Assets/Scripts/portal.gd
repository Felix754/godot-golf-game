extends Area3D


@export var portal_id: int = 0 # Unique ID to pair this portal with another
# NOTE: Portal IDs must be consistent across pairs.
		# Example of valid setup: IDs [1, 2, 3, 4]
		# Example of invalid setup: IDs [1, 3, 4] -> missing a pair for 3.
		# ID pairs is order-insensitive but must be complete.

@export var exit_offset: Vector3 = Vector3(0, 0, 2) # Offset applied to the exit position after teleportation
@export var marker_name: String = "ExitMarker"
var just_teleported: bool = false

func _ready():
	add_to_group("portals")

func _on_body_entered(body: Node) -> void:
	if just_teleported or not (body is GolfBall):
		return

	# Find the paired receiver portal with the same ID
	var receiver := find_receiver_portal()
	if receiver == null:
		push_error("No receiver portal found for ID %d" % portal_id)
		return

	# Try to find the exit marker inside the receiver portal
	var marker := receiver.get_node_or_null(marker_name)
	if marker == null:
		push_error("Exit marker '%s' not found on receiver portal!" % marker_name)
		return

	# Calculate exit position using marker's forward direction (Z axis) and offset
	var exit_pos: Vector3 = marker.global_transform.origin + marker.global_transform.basis.z * exit_offset.z
	body.global_transform.origin = exit_pos
	print("Exit portal position (id: %d): " % portal_id, exit_pos)

	# Prevent immediate re-teleportation by setting flags
	receiver.set_just_teleported(true)
	await get_tree().create_timer(0.3).timeout
	receiver.set_just_teleported(false)

func find_receiver_portal() -> Area3D:
	# Search for another portal with the same ID in the "portals" group
	for portal in get_tree().get_nodes_in_group("portals"):
		if portal != self and portal.portal_id == portal_id:
			return portal
	return null

func set_just_teleported(value: bool) -> void:
	# Set teleportation lock flag
	just_teleported = value
