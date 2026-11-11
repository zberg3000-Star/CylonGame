class_name Bullet
extends Area2D

const SPEED := 640.0
const LIFETIME := 1.15
const RAIDER_SPEED := 300.0
const RAIDER_LIFETIME := 1.6

var direction := Vector2.UP
var age := 0.0
var speed := SPEED
var lifetime := LIFETIME
var hostile := false


func setup(origin: Vector2, travel_direction: Vector2, from_raider: bool = false) -> void:
	position = origin
	direction = travel_direction.normalized()
	# The drawn line points up. Rotate it so it matches the travel direction.
	rotation = direction.angle() + PI / 2.0
	hostile = from_raider
	if hostile:
		speed = RAIDER_SPEED
		lifetime = RAIDER_LIFETIME
		collision_layer = 16
		collision_mask = 1
		add_to_group("raider_shots")


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	age += delta
	var size := get_viewport_rect().size
	var outside := position.x < 0.0 or position.y < 0.0 or position.x > size.x or position.y > size.y
	if age >= lifetime or outside:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if hostile:
		if area.is_in_group("ship"):
			queue_free()
		return
	if area is Asteroid:
		(area as Asteroid).destroy()
		queue_free()
	elif area is Raider:
		(area as Raider).destroy()
		queue_free()


func _draw() -> void:
	var color := Color(1.0, 0.22, 0.15) if hostile else Color(1.0, 0.95, 0.55)
	draw_line(Vector2(0, 7), Vector2(0, -8), color, 2.0)
