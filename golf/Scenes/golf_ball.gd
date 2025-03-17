extends RigidBody3D
class_name GolfBall 

@export var force_strength: float = 400.0  # Сила поштовху
@export var camera: Camera3D  # Посилання на камеру
@export var cooldown_time: float = 2.0  # Час кулдауну між ударами

var can_push: bool = true  # Чи можна зараз штовхати м'яч

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and can_push:  # Якщо можна штовхнути
			push_towards_camera()
			can_push = false  # Блокуємо можливість штовхати
			await get_tree().create_timer(cooldown_time).timeout  # Чекаємо 2 секунди
			can_push = true  # Дозволяємо знову штовхати

func push_towards_camera():
	if not camera:
		return
	
	var direction = (global_transform.origin - camera.global_transform.origin).normalized()
	apply_impulse(direction * force_strength)
