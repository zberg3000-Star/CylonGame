class_name Raider
extends Area2D

## Main creates a hostile bullet from this.
signal fired(origin: Vector2, direction: Vector2)
## Emitted once, when a player shot destroys the raider.
signal destroyed

const SPEED := 85.0
const TURN_SPEED := 1.05
const ALIGN_DOT := 0.99
const FIRE_PERIOD := 1.35
const HUNT_SECONDS := 30.0
const NOSE_OFFSET := 28.0
const HUNT_MARGIN := 90.0
const EXIT_MARGIN := 140.0

var age := 0.0
var fire_cooldown := 0.8
var leaving := false
var exit_direction := Vector2.RIGHT
var dead := false


func _ready() -> void:
	var inward := get_viewport_rect().size * 0.5 - global_position
	if inward.length() > 1.0:
		rotation = inward.angle() + PI / 2.0


func _physics_process(delta: float) -> void:
	if dead:
		return

	age += delta
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if age >= HUNT_SECONDS:
		_begin_exit()

	var ship := get_tree().get_first_node_in_group("ship") as Ship
	var aim := exit_direction
	if not leaving and ship != null and ship.alive:
		aim = ship.global_position - global_position
	elif not leaving:
		_begin_exit()
		aim = exit_direction

	if aim.length() > 1.0:
		var desired := aim.angle() + PI / 2.0
		var error := wrapf(desired - rotation, -PI, PI)
		rotation += clampf(error, -TURN_SPEED * delta, TURN_SPEED * delta)

	var facing := Vector2.UP.rotated(rotation)
	var speed := SPEED
	if not leaving and aim.length() > 1.0:
		var aligned := facing.dot(aim.normalized()) >= ALIGN_DOT
		if aligned and fire_cooldown <= 0.0:
			fire_cooldown = FIRE_PERIOD
			fired.emit(global_position + facing * NOSE_OFFSET, facing)
		elif not aligned:
			speed *= 0.35

	global_position += facing * speed * delta
	if leaving:
		if _is_outside():
			queue_free()
	else:
		_wrap_to_screen()
	queue_redraw()


func destroy() -> void:
	if dead:
		return
	dead = true
	destroyed.emit()
	queue_free()


func _begin_exit() -> void:
	if leaving:
		return
	leaving = true
	var size := get_viewport_rect().size
	var from_center := global_position - size * 0.5
	if from_center.length() < 40.0:
		exit_direction = Vector2.from_angle(randf() * TAU)
	else:
		exit_direction = from_center.normalized()


func _is_outside() -> bool:
	var size := get_viewport_rect().size
	return (
		global_position.x < -EXIT_MARGIN
		or global_position.y < -EXIT_MARGIN
		or global_position.x > size.x + EXIT_MARGIN
		or global_position.y > size.y + EXIT_MARGIN
	)


func _wrap_to_screen() -> void:
	var size := get_viewport_rect().size
	# The margin is wider than the spawn point, so a raider that starts just
	# off-screen flies in instead of wrapping to the opposite edge.
	global_position.x = wrapf(global_position.x, -HUNT_MARGIN, size.x + HUNT_MARGIN)
	global_position.y = wrapf(global_position.y, -HUNT_MARGIN, size.y + HUNT_MARGIN)


func _draw() -> void:
	var left_wing := PackedVector2Array([
		Vector2(-5, -2),
		Vector2(-32, 8),
		Vector2(-22, 18),
		Vector2(-6, 12),
	])
	var right_wing := PackedVector2Array([
		Vector2(5, -2),
		Vector2(32, 8),
		Vector2(22, 18),
		Vector2(6, 12),
	])
	var hull := PackedVector2Array([
		Vector2(0, -26),
		Vector2(-7, -4),
		Vector2(-5, 18),
		Vector2(5, 18),
		Vector2(7, -4),
	])
	draw_colored_polygon(left_wing, Color(0.42, 0.1, 0.09))
	draw_colored_polygon(right_wing, Color(0.42, 0.1, 0.09))
	draw_colored_polygon(hull, Color(0.72, 0.18, 0.14))
	_draw_outline(left_wing, Color(1.0, 0.45, 0.35))
	_draw_outline(right_wing, Color(1.0, 0.45, 0.35))
	_draw_outline(hull, Color(1.0, 0.62, 0.5))
	var pulse := 0.55 + 0.45 * sin(age * 6.0)
	draw_circle(Vector2(0, -8), 2.8, Color(1.0, 0.12, 0.08).lerp(Color(1.0, 0.55, 0.25), pulse))


func _draw_outline(points: PackedVector2Array, color: Color) -> void:
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, color, 1.5)
