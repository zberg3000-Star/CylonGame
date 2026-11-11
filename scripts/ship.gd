class_name Ship
extends Area2D

## Emitted when the player fires. Main listens and creates the bullet.
signal fired(origin: Vector2, direction: Vector2)
## Emitted when an asteroid touches the ship.
signal died

const TURN_SPEED := 3.2
const THRUST := 280.0
const REVERSE_THRUST := 180.0
const MAX_SPEED := 380.0
const DRAG := 30.0
const FIRE_COOLDOWN := 0.22
const NOSE_OFFSET := 20.0

var velocity := Vector2.ZERO
var cooldown := 0.0
var invulnerable := 0.0
var alive := true
var thrusting := false


func _physics_process(delta: float) -> void:
	if not alive:
		return

	cooldown = maxf(cooldown - delta, 0.0)
	var was_invulnerable := invulnerable > 0.0
	invulnerable = maxf(invulnerable - delta, 0.0)
	if was_invulnerable and invulnerable <= 0.0:
		_hit_if_touching_asteroid()

	# get_axis returns -1 when only the first action is held, +1 for the second.
	# A is turn_left, so holding A makes this value negative and the ship turns
	# counter-clockwise. D turns clockwise.
	var turn := Input.get_axis("turn_left", "turn_right")
	rotation += turn * TURN_SPEED * delta

	# Vector2.UP rotated by the ship's rotation is the direction the nose points.
	var facing := Vector2.UP.rotated(rotation)
	thrusting = false
	if Input.is_action_pressed("thrust"):
		velocity += facing * THRUST * delta
		thrusting = true
	if Input.is_action_pressed("reverse"):
		velocity -= facing * REVERSE_THRUST * delta
		thrusting = true

	velocity = velocity.move_toward(Vector2.ZERO, DRAG * delta)
	velocity = velocity.limit_length(MAX_SPEED)
	position += velocity * delta
	_wrap_to_screen()

	if Input.is_action_pressed("shoot") and cooldown <= 0.0:
		cooldown = FIRE_COOLDOWN
		fired.emit(position + facing * NOSE_OFFSET, facing)

	queue_redraw()


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid:
		_take_hit()


func _hit_if_touching_asteroid() -> void:
	for area in get_overlapping_areas():
		if area is Asteroid:
			_take_hit()
			return


func _take_hit() -> void:
	if not alive or invulnerable > 0.0:
		return
	died.emit()


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	rotation = 0.0
	invulnerable = 2.0
	alive = true
	visible = true
	queue_redraw()


func kill() -> void:
	alive = false
	visible = false
	velocity = Vector2.ZERO


func _wrap_to_screen() -> void:
	var size := get_viewport_rect().size
	position.x = wrapf(position.x, 0.0, size.x)
	position.y = wrapf(position.y, 0.0, size.y)


func _draw() -> void:
	if not alive:
		return
	# Blink while the ship cannot be hit, so the pause is visible.
	if invulnerable > 0.0 and int(invulnerable * 12.0) % 2 == 0:
		return

	var hull := PackedVector2Array([
		Vector2(0, -16),
		Vector2(-12, 14),
		Vector2(12, 14),
	])
	draw_colored_polygon(hull, Color(0.75, 0.9, 1.0))
	var outline := hull.duplicate()
	outline.append(hull[0])
	draw_polyline(outline, Color.WHITE, 2.0)
	if thrusting:
		var flame := PackedVector2Array([
			Vector2(-6, 14),
			Vector2(0, 26),
			Vector2(6, 14),
		])
		draw_colored_polygon(flame, Color(1.0, 0.55, 0.15))
