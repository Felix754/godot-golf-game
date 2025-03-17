extends Camera3D

@export var target: GolfBall  # Об'єкт (м'ячик), за яким слідкує камера
@export var offset: Vector3 = Vector3(0, 3, -6)  # Початкове положення камери
@export var rotation_speed: float = 0.005  # Чутливість обертання миші
@export var zoom_speed: float = 0.5  # Швидкість віддалення/наближення
@export var min_distance: float = 4.0  # Мінімальна відстань
@export var max_distance: float = 15.0  # Максимальна відстань

var yaw: float = 0.0  # Кут повороту навколо осі Y
var rotating: bool = false  # Чи ми обертаємо камеру зараз
var last_mouse_position: Vector2  # Позиція миші перед обертанням
var current_distance: float  # Поточна відстань

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Видимий курсор
	current_distance = offset.length()  # Ініціалізуємо відстань

func _process(delta):
	if not target:
		return
	
	# Отримуємо позицію м'яча
	var target_position = target.global_transform.origin

	# Обертання камери при натиснутій ЛКМ
	if rotating:
		var mouse_delta = get_viewport().get_mouse_position() - last_mouse_position
		yaw -= mouse_delta.x * rotation_speed
		last_mouse_position = get_viewport().get_mouse_position()

	# Обчислюємо віддалену позицію камери
	var direction = offset.normalized()  # Напрямок камери
	var zoomed_offset = direction * current_distance  # Масштабований вектор відстані
	var rotated_offset = zoomed_offset.rotated(Vector3.UP, yaw)  # Обертаємо камеру
	
	# Миттєве переміщення камери
	global_transform.origin = target_position + rotated_offset
	
	# Дивимося на м'яч
	look_at(target_position, Vector3.UP)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed  # Починаємо або припиняємо обертання
			last_mouse_position = get_viewport().get_mouse_position()

	# Обробка зміни відстані
	if event is InputEventMouseMotion and rotating:
		var mouse_delta = event.relative
		yaw -= mouse_delta.x * rotation_speed

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_distance(-zoom_speed)  # Приближення
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_distance(zoom_speed)  # Віддалення

func change_distance(delta: float):
	current_distance = clamp(current_distance + delta, min_distance, max_distance)
