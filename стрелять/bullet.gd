extends Area2D

var speed: float = 800.0
var direction: Vector2

func _ready() -> void:
	# Подписываемся на событие "тело вошло в зону пули"
	body_entered.connect(_on_body_entered)
	
	# Автоудаление через 2 сек, если ни во что не попала
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Пуля коснулась любого физического объекта (стены, пола и т.д.)
	queue_free()
