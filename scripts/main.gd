extends Node2D

const SHIP_SCENE := preload("res://scenes/ship.tscn")
const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const ASTEROID_SCENE := preload("res://scenes/asteroid.tscn")
const RAIDER_SCENE := preload("res://scenes/raider.tscn")
const POINTS_BY_TIER: Array[int] = [0, 20, 50, 100]
const RAIDER_POINTS := 200
const RAIDER_ROLL_SECONDS := 10.0
const RAIDER_SPAWN_CHANCE := 0.5

var score := 0
var lives := 3
var wave := 1
var game_over := false
var clearing_wave := false
var asteroids_alive := 0
var ship: Ship
var stars := PackedVector2Array()
var raider_roll := 0.0

@onready var score_label: Label = $UI/ScoreLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var message_label: Label = $UI/MessageLabel


func _ready() -> void:
	_make_stars()
	message_label.visible = false
	_spawn_ship()
	_spawn_wave()
	_refresh_hud()


func _process(delta: float) -> void:
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	if game_over:
		return
	raider_roll += delta
	if raider_roll >= RAIDER_ROLL_SECONDS:
		raider_roll -= RAIDER_ROLL_SECONDS
		if randf() < RAIDER_SPAWN_CHANCE:
			_spawn_raider()


func _spawn_ship() -> void:
	ship = SHIP_SCENE.instantiate()
	ship.fired.connect(_on_ship_fired)
	ship.died.connect(_on_ship_died)
	add_child(ship)
	ship.respawn(get_viewport_rect().size * 0.5)


func _on_ship_fired(origin: Vector2, direction: Vector2) -> void:
	if game_over:
		return
	var bullet := BULLET_SCENE.instantiate() as Bullet
	add_child(bullet)
	bullet.setup(origin, direction)


func _on_ship_died() -> void:
	if game_over:
		return
	lives -= 1
	_refresh_hud()
	if lives <= 0:
		game_over = true
		ship.kill()
		message_label.text = "Ship lost. Press R to restart."
		message_label.visible = true
		return
	ship.respawn(get_viewport_rect().size * 0.5)


func _spawn_raider() -> void:
	var raider := RAIDER_SCENE.instantiate() as Raider
	raider.position = _edge_position(56.0)
	raider.fired.connect(_on_raider_fired)
	raider.destroyed.connect(_on_raider_destroyed)
	add_child(raider)


func _on_raider_fired(origin: Vector2, direction: Vector2) -> void:
	if game_over:
		return
	var bullet := BULLET_SCENE.instantiate() as Bullet
	add_child(bullet)
	bullet.setup(origin, direction, true)


func _on_raider_destroyed() -> void:
	score += RAIDER_POINTS
	_refresh_hud()


func _spawn_wave() -> void:
	var count := 2 + wave
	for _i in count:
		_spawn_asteroid(1, _edge_position(), Vector2.ZERO)


func _spawn_asteroid(tier: int, at: Vector2, travel: Vector2) -> void:
	var asteroid := ASTEROID_SCENE.instantiate() as Asteroid
	asteroid.setup(tier, at, travel)
	asteroid.shattered.connect(_on_asteroid_shattered)
	asteroids_alive += 1
	add_child(asteroid)


func _on_asteroid_shattered(at: Vector2, tier: int, travel: Vector2) -> void:
	asteroids_alive -= 1
	score += POINTS_BY_TIER[tier]
	_refresh_hud()
	if tier < 3:
		var base := travel.normalized() if travel.length() > 0.0 else Vector2.RIGHT
		_spawn_asteroid(tier + 1, at, base.rotated(0.55))
		_spawn_asteroid(tier + 1, at, base.rotated(-0.55))
	if asteroids_alive == 0:
		_announce_next_wave()


func _announce_next_wave() -> void:
	if game_over or clearing_wave:
		return
	clearing_wave = true
	wave += 1
	_refresh_hud()
	message_label.text = "Wave %d" % wave
	message_label.visible = true
	get_tree().create_timer(1.2).timeout.connect(_begin_next_wave, CONNECT_ONE_SHOT)


func _begin_next_wave() -> void:
	if game_over:
		return
	message_label.visible = false
	clearing_wave = false
	_spawn_wave()


func _edge_position(margin: float = 24.0) -> Vector2:
	var size := get_viewport_rect().size
	match randi() % 4:
		0:
			return Vector2(randf_range(0.0, size.x), -margin)
		1:
			return Vector2(randf_range(0.0, size.x), size.y + margin)
		2:
			return Vector2(-margin, randf_range(0.0, size.y))
		_:
			return Vector2(size.x + margin, randf_range(0.0, size.y))


func _refresh_hud() -> void:
	score_label.text = "Score %d    Wave %d" % [score, wave]
	lives_label.text = "Lives %d" % lives


func _make_stars() -> void:
	var size := get_viewport_rect().size
	for _i in 70:
		stars.append(Vector2(randf() * size.x, randf() * size.y))
	queue_redraw()


func _draw() -> void:
	for star in stars:
		draw_circle(star, 1.2, Color(1, 1, 1, 0.65))
