class_name Bullet
extends Area2D

const SPEED := 640.0
const LIFETIME := 1.15

var direction := Vector2.UP
var age := 0.0


func setup(origin: Vector2, travel_direction: Vector2) -> void:
	position = origin
	direction = travel_direction.normalized()
	# The drawn line points up. Rotate it so it matches the travel direction.
	rotation = direction.angle() + PI / 2.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	age += delta
	var size := get_viewport_rect().size
	var outside := position.x < 0.0 or position.y < 0.0 or position.x > size.x or position.y > size.y
	if age >= LIFETIME or outside:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid:
		(area as Asteroid).destroy()
		queue_free()


func _draw() -> void:
	draw_line(Vector2(0, 7), Vector2(0, -8), Color(1.0, 0.95, 0.55), 2.0)
