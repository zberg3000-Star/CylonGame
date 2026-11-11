class_name Asteroid
extends Area2D

## tier is 1 large, 2 medium, or 3 small.
## travel is the direction the rock was moving when it broke.
signal shattered(at: Vector2, tier: int, travel: Vector2)

const RADII: Array[float] = [0.0, 58.0, 34.0, 18.0]
const SPEEDS: Array[float] = [0.0, 80.0, 120.0, 170.0]

var tier := 1
var velocity := Vector2.ZERO
var spin := 0.0
var outline := PackedVector2Array()
var destroyed := false


func setup(new_tier: int, at: Vector2, travel: Vector2) -> void:
	tier = clampi(new_tier, 1, 3)
	position = at
	var speed := SPEEDS[tier] * randf_range(0.8, 1.25)
	if travel.length() < 1.0:
		velocity = Vector2.from_angle(randf() * TAU) * speed
	else:
		velocity = travel.normalized() * speed
	spin = randf_range(-1.5, 1.5)
	_build_outline()


func _ready() -> void:
	add_to_group("asteroids")
	if outline.is_empty():
		_build_outline()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += spin * delta
	var size := get_viewport_rect().size
	# The extra margin lets a rock slide fully off one edge before it reappears.
	position.x = wrapf(position.x, -48.0, size.x + 48.0)
	position.y = wrapf(position.y, -48.0, size.y + 48.0)


func destroy() -> void:
	if destroyed:
		return
	destroyed = true
	shattered.emit(global_position, tier, velocity)
	queue_free()


func _build_outline() -> void:
	var radius := RADII[tier]
	var count := randi_range(8, 12)
	outline = PackedVector2Array()
	for i in count:
		var angle := TAU * float(i) / float(count)
		var distance := radius * randf_range(0.7, 1.15)
		outline.append(Vector2.from_angle(angle) * distance)

	var shape := CollisionPolygon2D.new()
	shape.polygon = outline
	add_child(shape)
	queue_redraw()


func _draw() -> void:
	if outline.size() < 3:
		return
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, Color(0.78, 0.84, 0.92), 2.0)
