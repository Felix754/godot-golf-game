extends Label

func _process(delta):
	text = "FPS: " + str(Engine.get_frames_per_second())

#Using Device #0: NVIDIA - NVIDIA GeForce RTX 3060 Laptop GPU
# avarage 75 FPS
