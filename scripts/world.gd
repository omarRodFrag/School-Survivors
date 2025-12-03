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
@onready var victory_screen: Node = $VictoryScreen

var timerSlime := 3.0

# Estado de nivel local
var kills_local_this_level := 0
var boss_spawned_this_level := false
var spawned_boss : Node = null
var spawned_bosses: Array = []  # Para el nivel final con múltiples jefes
var final_bosses_remaining: int = 0  # Contador para nivel final

func _ready() -> void:
	timer_spawn_slime.timeout.connect(spawn_enemy)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

	ScoreManager.connect("level_changed", Callable(self, "_on_level_changed"))
	ScoreManager.connect("kills_changed", Callable(self, "_on_kills_changed"))
	ScoreManager.connect("game_won", Callable(self, "_on_game_won"))

	# Iniciar tracking de tiempo
	if GameStats:
		GameStats.reset_stats()

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

func spawn_enemy() -> void:
	if not personaje_omar:
		return
	var enemy_scene = ORC if randf() < 0.3 else SLIME  # 30% chance de Orco, 70% Slime
	var enemy = enemy_scene.instantiate()
	var random_angle : float = randf() * PI * 2
	var spawn_distance : float = randf_range(270, 300)
	var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	var spawn_position = spawn_offset + personaje_omar.position
	
	# Límites fijos del mapa: (0, 0) a (1280, 656)
	var margin = 20.0  # Margen de seguridad para evitar spawn en los bordes
	var min_x = margin
	var max_x = 1280.0 - margin
	var min_y = margin
	var max_y = 656.0 - margin
	
	# Clamp la posición de spawn dentro de los límites del mapa
	spawn_position.x = clamp(spawn_position.x, min_x, max_x)
	spawn_position.y = clamp(spawn_position.y, min_y, max_y)
	
	# Verificar si la posición está libre de colisiones, si no, buscar una alternativa
	spawn_position = _find_free_spawn_position(spawn_position, min_x, max_x, min_y, max_y)
	
	enemy.position = spawn_position
	
	# Aplicar multiplicadores de dificultad
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	enemy.move_speed = int(enemy.move_speed * speed_mult)
	if "max_health_value" in enemy:
		enemy.max_health_value = int(enemy.max_health_value * health_mult)
	
	add_child(enemy)
	
	# Aplicar también después de _ready() por si acaso
	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(speed_mult, health_mult)
	
	# Conectar señal del enemigo
	if enemy.has_signal("enemy_killed"):
		enemy.enemy_killed.connect(_on_slime_killed_by_player)

func _on_slime_killed_by_player() -> void:
	ScoreManager.add_points(10)
	kills_local_this_level += 1
	ScoreManager.emit_signal("kills_changed", kills_local_this_level, ScoreManager.kills_to_next_level)

	if not boss_spawned_this_level and kills_local_this_level >= ScoreManager.kills_to_next_level:
		if ScoreManager.is_max_level():
			_spawn_final_level_bosses()
		else:
			_spawn_boss_for_level()

func _spawn_boss_for_level() -> void:
	if spawned_boss and spawned_boss.is_inside_tree():
		return
	var boss = BOSS.instantiate()
	var offset_x = randf_range(-150, 150)
	boss.position = personaje_omar.position + Vector2(offset_x, -200)
	
	# Aplicar multiplicadores de dificultad al boss
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	boss.move_speed = int(boss.move_speed * speed_mult)
	if "max_health_value" in boss:
		boss.max_health_value = int(boss.max_health_value * health_mult)
	
	# Usar call_deferred para evitar error de flushing queries
	call_deferred("_add_boss_to_scene", boss, speed_mult, health_mult, false)
	
	spawned_boss = boss
	boss_spawned_this_level = true
	if hud:
		hud.show_boss_incoming()

	# Cambia a música del boss
	music_player.stream = MUSICA_BOSS
	music_player.play()

func _on_boss_killed_by_player() -> void:
	ScoreManager.add_points(200)
	
	# Si es el nivel máximo, no limpiar ni cambiar música aquí, dejar que complete_level() lo maneje
	if ScoreManager.is_max_level():
		ScoreManager.complete_level()
		# No hacer nada más aquí, complete_level() emitirá game_won
		return
	
	# Solo mostrar mensaje si no es el nivel final
	if hud:
		hud.show_level_completed()
	
	ScoreManager.complete_level()

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
	spawned_bosses.clear()
	final_bosses_remaining = 0
	_clear_enemies()

func _on_kills_changed(_kills_this_level: int, _kills_to_next_level: int) -> void:
	pass  # No usado directamente

func _update_for_level(level:int) -> void:
	# Calcular tiempo base de spawn
	var base_spawn_time = 3.0
	var base_time = max(0.5, base_spawn_time - (level - 1) * 0.35)
	
	# Aplicar multiplicador de dificultad (reduce tiempo entre spawns)
	var spawn_multiplier = ScoreManager.get_spawn_rate_multiplier(level)
	timerSlime = base_time * spawn_multiplier
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

func _find_free_spawn_position(initial_position: Vector2, min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	# Verificar si la posición inicial está libre usando un shape query
	if _is_position_free(initial_position):
		return initial_position
	
	# Si no está libre, buscar una posición alternativa en círculos concéntricos
	var space_state = get_world_2d().direct_space_state
	var search_radius = 30.0
	var max_attempts = 8  # Intentar 8 direcciones diferentes
	var attempts = 0
	
	# Intentar posiciones en círculos concéntricos
	for radius_multiplier in range(1, 4):  # 3 círculos concéntricos
		var current_radius = search_radius * radius_multiplier
		for i in range(max_attempts):
			var angle = (TAU / max_attempts) * i
			var offset = Vector2(cos(angle), sin(angle)) * current_radius
			var test_position = initial_position + offset
			
			# Asegurar que está dentro de los límites
			test_position.x = clamp(test_position.x, min_x, max_x)
			test_position.y = clamp(test_position.y, min_y, max_y)
			
			if _is_position_free(test_position):
				return test_position
			
			attempts += 1
			if attempts >= 20:  # Límite de intentos totales
				break
	
	# Si no encontramos posición libre después de todos los intentos, usar la inicial
	# (mejor spawn en una colisión que no spawnear)
	return initial_position

func _is_position_free(position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# Crear un círculo pequeño para verificar colisiones
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 15.0  # Radio pequeño para verificar el área de spawn
	
	# Crear query de forma
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform.origin = position
	query.collision_mask = 1  # Layer 1 es el TileMap (paredes/obstáculos)
	query.exclude = []  # No excluir nada, queremos detectar todas las colisiones
	
	# Verificar si hay colisiones
	var results = space_state.intersect_shape(query)
	
	# Si hay resultados, la posición NO está libre
	return results.is_empty()

func _clear_enemies() -> void:
	for child in get_children():
		if child is Player:
			continue
		if child is Timer:
			continue
		if child.has_node("Components") and child != personaje_omar:
			child.queue_free()
func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if hud and hud.has_method("update_health_bar"):
		hud.update_health_bar(current_health, max_health)

# Spawnea múltiples jefes para el nivel final
func _spawn_final_level_bosses() -> void:
	if spawned_bosses.size() > 0:
		return  # Ya spawneados
	
	spawned_bosses.clear()
	final_bosses_remaining = 3
	
	# Posiciones alrededor del jugador: arriba, izquierda, derecha
	var spawn_positions = [
		personaje_omar.position + Vector2(0, -200),  # Arriba
		personaje_omar.position + Vector2(-200, 0),  # Izquierda
		personaje_omar.position + Vector2(200, 0)    # Derecha
	]
	
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	# Spawnear 3 jefes
	for i in range(3):
		var boss = BOSS.instantiate()
		var valid_position = spawn_positions[i]
		
		boss.position = valid_position
		
		# Aplicar multiplicadores de dificultad ANTES de add_child
		boss.move_speed = int(boss.move_speed * speed_mult)
		if "max_health_value" in boss:
			boss.max_health_value = int(boss.max_health_value * health_mult)
		
		# Usar call_deferred para evitar error de flushing queries
		call_deferred("_add_boss_to_scene", boss, speed_mult, health_mult, true)
		
		spawned_bosses.append(boss)
	
	boss_spawned_this_level = true
	if hud:
		hud.show_boss_incoming()

	# Cambia a música del boss
	music_player.stream = MUSICA_BOSS
	music_player.play()

func _on_final_boss_killed() -> void:
	ScoreManager.add_points(200)
	final_bosses_remaining -= 1
	
	# Verificar si todos los jefes fueron eliminados
	if final_bosses_remaining <= 0:
		# Todos los jefes fueron eliminados - completar juego
		spawned_bosses.clear()
		boss_spawned_this_level = false
		_clear_enemies()
		
		# Completar nivel (esto emitirá game_won si es nivel MAX_LEVEL)
		ScoreManager.complete_level()
		
		# Volver a música normal
		music_player.stream = MUSICA_FONDO
		music_player.play()

func _on_game_won(score: int, _final_level: int, stats: Dictionary) -> void:
	# Mostrar pantalla de victoria usando la referencia @onready
	if victory_screen:
		victory_screen.show_victory(score, stats)
	else:
		# Fallback: buscar manualmente
		var found_screen = get_node_or_null("VictoryScreen")
		if found_screen:
			found_screen.show_victory(score, stats)
		else:
			push_error("[World] ERROR: VictoryScreen no encontrado")

# Función auxiliar para agregar boss al árbol de escena usando call_deferred
func _add_boss_to_scene(boss: Node, speed_mult: float, health_mult: float, is_final_boss: bool) -> void:
	add_child(boss)
	
	# Aplicar también después para asegurar que se actualice health_component
	if boss.has_method("apply_difficulty"):
		boss.apply_difficulty(speed_mult, health_mult)
	
	# Conectar señal del boss
	if boss.has_signal("boss_killed"):
		if is_final_boss:
			boss.boss_killed.connect(_on_final_boss_killed)
		else:
			boss.boss_killed.connect(_on_boss_killed_by_player)
