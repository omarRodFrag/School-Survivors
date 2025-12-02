# res://world.gd
extends Node2D

const SLIME = preload("uid://c61anvsnkj4dk")
const BOSS = preload("uid://cak370ffpdgv6")
const ORC = preload("uid://ucpxyend4m2x")

# Música
const MUSICA_FONDO = preload("res://assets/sonidos/musica_fondo.mp3")
const MUSICA_BOSS = preload("res://assets/sonidos/musica_boss.mp3")

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var personaje_omar: Player = $personaje_Omar
@onready var timer_spawn_slime: Timer = $TimerSpawnSlime
@onready var hud: Node = $HUD

var timerSlime := 3.0

# Límites del mapa para spawn (manuales: 0,0 hasta 1280,656)
var map_bounds: Rect2

# Estado de nivel local
var kills_local_this_level := 0
var boss_spawned_this_level := false
var spawned_boss : Node = null

func _ready() -> void:
	timer_spawn_slime.timeout.connect(spawn_enemy)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

	ScoreManager.connect("level_changed", Callable(self, "_on_level_changed"))
	ScoreManager.connect("kills_changed", Callable(self, "_on_kills_changed"))

	_update_for_level(ScoreManager.level)
	_on_level_changed(ScoreManager.level)

	# Conectar señal de vida del jugador al HUD
	if personaje_omar and personaje_omar.health_component:
		personaje_omar.health_component.health_changed.connect(_on_player_health_changed)
		# Actualizar barra inicial
		_on_player_health_changed(personaje_omar.health_component.current_health, personaje_omar.health_component.max_health)

	# Inicia música de fondo normal
	music_player.stream = MUSICA_FONDO
	music_player.play()
	
	# Calcular límites del mapa para spawn
	_calculate_map_bounds()

func spawn_enemy() -> void:
	if not personaje_omar:
		return
	var enemy_scene = ORC if randf() < 0.3 else SLIME  # 30% chance de Orco, 70% Slime
	var enemy = enemy_scene.instantiate()
	
	# Intentar encontrar una posición válida (máximo 20 intentos)
	var valid_position: Vector2 = Vector2.ZERO
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		var random_angle : float = randf() * PI * 2
		var spawn_distance : float = randf_range(270, 300)
		var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
		valid_position = spawn_offset + personaje_omar.position
		
		if _is_valid_spawn_position(valid_position):
			break
		
		attempts += 1
	
	# Si no encontramos una posición válida después de todos los intentos, usar la última intentada
	enemy.position = valid_position
	add_child(enemy)
	# Conectar señal del enemigo
	if enemy.has_signal("enemy_killed"):
		enemy.enemy_killed.connect(_on_slime_killed_by_player)

func _on_slime_killed_by_player() -> void:
	ScoreManager.add_points(10)
	kills_local_this_level += 1
	ScoreManager.emit_signal("kills_changed", kills_local_this_level, ScoreManager.kills_to_next_level)

	if not boss_spawned_this_level and kills_local_this_level >= ScoreManager.kills_to_next_level:
		_spawn_boss_for_level()

func _spawn_boss_for_level() -> void:
	if spawned_boss and spawned_boss.is_inside_tree():
		return
	var boss = BOSS.instantiate()
	
	# Intentar encontrar una posición válida para el boss
	var valid_position: Vector2 = personaje_omar.position + Vector2(0, -200)  # Posición por defecto
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		var offset_x = randf_range(-150, 150)
		var boss_pos = personaje_omar.position + Vector2(offset_x, -200)
		
		if _is_valid_spawn_position(boss_pos):
			valid_position = boss_pos
			break
		
		attempts += 1
	
	boss.position = valid_position
	add_child(boss)
	# Conectar señal del boss
	if boss.has_signal("boss_killed"):
		boss.boss_killed.connect(_on_boss_killed_by_player)
	spawned_boss = boss
	boss_spawned_this_level = true
	if hud:
		hud.show_boss_incoming()

	# Cambia a música del boss
	music_player.stream = MUSICA_BOSS
	music_player.play()

func _on_boss_killed_by_player() -> void:
	ScoreManager.add_points(200)
	ScoreManager.complete_level()

	if hud:
		hud.show_level_completed()

	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	_clear_enemies()
	
	# Vuelve a música normal
	music_player.stream = MUSICA_FONDO
	music_player.play()

func _on_level_changed(new_level: int) -> void:
	_update_for_level(new_level)
	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	_clear_enemies()

func _on_kills_changed(_kills_this_level: int, _kills_to_next_level: int) -> void:
	pass  # No usado directamente

func _update_for_level(level:int) -> void:
	timerSlime = max(0.5, 3.0 - (level - 1) * 0.35)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

func _clear_enemies() -> void:
	for child in get_children():
		if child is Player:
			continue
		if child is Timer:
			continue
		if child.has_node("Components") and child != personaje_omar:
			child.queue_free()

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if hud:
		hud.update_health_bar(current_health, max_health)

# Calcular límites del mapa usando valores manuales medidos
func _calculate_map_bounds() -> void:
	# Límites medidos: esquina superior izquierda (0, 0) hasta inferior derecha (1280, 656)
	# Usar un margen para evitar spawn en los bordes
	var margin = 50.0
	map_bounds = Rect2(
		0 + margin,      # x mínima
		0 + margin,      # y mínima
		1280 - (margin * 2),  # ancho (1280 - margen izquierdo - margen derecho)
		656 - (margin * 2)    # alto (656 - margen superior - margen inferior)
	)
	
	print("[World] Límites del mapa configurados: ", map_bounds)

# Verificar si una posición está dentro de los límites válidos del mapa y sin colisiones
func _is_valid_spawn_position(pos: Vector2) -> bool:
	# Primero verificar límites del mapa
	if not map_bounds.has_point(pos):
		return false
	
	# Verificar colisiones con objetos usando shape query
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Crear un shape de tamaño pequeño para detectar objetos
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)  # Tamaño aproximado de un enemigo pequeño
	
	query.shape = shape
	query.transform.origin = pos
	query.collision_mask = 1  # Layer 1 es el TileMap
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# Verificar colisiones con TileMap y objetos estáticos
	var results = space_state.intersect_shape(query)
	
	# Si hay resultados, verificar que no sean objetos que bloqueen el spawn
	if results.size() > 0:
		for result in results:
			var collider = result.get("collider")
			if collider:
				# Si es TileMapLayer o StaticBody2D, rechazar la posición
				if collider is TileMapLayer or collider is StaticBody2D:
					return false
				# Si tiene CollisionShape2D pero no es CharacterBody2D, puede ser objeto estático
				if collider.has_node("CollisionShape2D") and not (collider is CharacterBody2D):
					# Rechazar si no es el jugador (objetos estáticos bloquean spawn)
					if not (collider is Player):
						return false
	
	return true
