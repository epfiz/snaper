extends CharacterBody2D

# --- НАСТРОЙКИ СКОРОСТИ ---
@export var speed_walk: float = 200.0
@export var speed_run: float = 350.0

# --- НАСТРОЙКИ РАЗБРОСА (в градусах) ---
@export var spread_idle: float = 5.0   # Стоит на месте
@export var spread_walk: float = 30.0   # Идёт шагом
@export var spread_run: float = 90.0   # Бежит (Shift)

const BULLET_PATH = "res://bullet.tscn"

var has_pistol: bool = false
var fire_cooldown: float = 0.0
@export var fire_rate: float = 0.25

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun_sprite: Sprite2D = $GunSprite
@onready var muzzle: Marker2D = $GunSprite/Muzzle

func _ready() -> void:
	randomize() # Чтобы разброс был случайным при каждом запуске
	gun_sprite.visible = false

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("move_right"): direction.x += 1
	if Input.is_action_pressed("move_left"):  direction.x -= 1
	if Input.is_action_pressed("move_down"):  direction.y += 1
	if Input.is_action_pressed("move_up"):    direction.y -= 1

	# 1. ОПРЕДЕЛЯЕМ СОСТОЯНИЕ
	var is_moving = direction.length() > 0
	var is_running = Input.is_action_pressed("run") and is_moving # Зажат ли Shift?

	# 2. ВЫБИРАЕМ СКОРОСТЬ
	var current_speed = speed_run if is_running else speed_walk
	if !is_moving: current_speed = 0

	velocity = direction.normalized() * current_speed
	move_and_slide()

	# 3. АНИМАЦИЯ
	if velocity.length() > 0:
		anim.play("run")
		# Ускоряем анимацию при беге, чтобы ноги мелькали чаще
		anim.speed_scale = 2.0 if is_running else 1.0
	else:
		anim.play("idle")
		anim.speed_scale = 1.0

	if velocity.x < 0: 
		anim.flip_h = true 
	elif velocity.x > 0: 
		anim.flip_h = false

	# ВКЛ/ВЫКЛ пистолета
	if Input.is_action_just_pressed("pickup"):
		has_pistol = !has_pistol
		gun_sprite.visible = has_pistol

	# Прицеливание
	if has_pistol:
		gun_sprite.look_at(get_global_mouse_position())

	# Кулдаун
	if fire_cooldown > 0:
		fire_cooldown -= delta

	# СТРЕЛЬБА
	if has_pistol and Input.is_action_just_pressed("shoot") and fire_cooldown <= 0:
		# Выбираем текущий разброс
		var current_spread = 0.0
		if !is_moving:
			current_spread = spread_idle
		elif is_running:
			current_spread = spread_run
		else:
			current_spread = spread_walk
			
		shoot(current_spread)

func shoot(spread_angle: float) -> void:
	fire_cooldown = fire_rate
	
	var bullet = load(BULLET_PATH).instantiate()
	bullet.global_position = muzzle.global_position
	
	# Базовое направление (куда смотрит дуло)
	var base_direction = muzzle.global_transform.x
	
	# Добавляем случайное отклонение
	var random_angle = deg_to_rad(randf_range(-spread_angle, spread_angle))
	var final_direction = base_direction.rotated(random_angle)
	
	bullet.direction = final_direction
	get_tree().root.add_child(bullet)
