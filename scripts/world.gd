# res://world.gd
# Script principal del nivel/mundo del juego
# Gestiona el spawn de enemigos, jefes, música, progreso de niveles y eventos del juego
extends Node2D

# ============================================================================
# PRELOADS DE ESCENAS DE ENEMIGOS
# ============================================================================
const SLIME = preload("uid://c61anvsnkj4dk")
const BOSS = preload("uid://cak370ffpdgv6")
const ORC = preload("uid://ucpxyend4m2x")

# ============================================================================
# RECURSOS DE AUDIO
# ============================================================================
const MUSICA_FONDO = preload("res://assets/sonidos/musica_fondo.mp3")
const MUSICA_BOSS = preload("res://assets/sonidos/musica_boss.mp3")

# ============================================================================
# REFERENCIAS A NODOS DE LA ESCENA
# ============================================================================
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var personaje_omar: Player = $personaje_Omar
@onready var timer_spawn_slime: Timer = $TimerSpawnSlime
@onready var hud: Node = $HUD
@onready var victory_screen: Node = $VictoryScreen

# ============================================================================
# VARIABLES DE CONFIGURACIÓN
# ============================================================================
var timerSlime := 3.0  # Tiempo entre spawns de enemigos (se ajusta según nivel)

# ============================================================================
# ESTADO DEL NIVEL ACTUAL
# ============================================================================
var kills_local_this_level := 0  # Contador de enemigos eliminados en este nivel
var boss_spawned_this_level := false  # Indica si ya se spawnó el jefe en este nivel
var spawned_boss : Node = null  # Referencia al jefe spawnado (niveles normales)
var spawned_bosses: Array = []  # Array de jefes para el nivel final (múltiples jefes)
var final_bosses_remaining: int = 0  # Contador de jefes restantes en el nivel final

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar timer para spawn automático de enemigos
	timer_spawn_slime.timeout.connect(spawn_enemy)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

	# Conectar señales del ScoreManager para reaccionar a cambios de nivel y victoria
	ScoreManager.connect("level_changed", Callable(self, "_on_level_changed"))
	ScoreManager.connect("kills_changed", Callable(self, "_on_kills_changed"))
	ScoreManager.connect("game_won", Callable(self, "_on_game_won"))

	# Iniciar tracking de tiempo de juego y estadísticas
	if GameStats:
		GameStats.reset_stats()

	# Configurar dificultad y estado inicial según el nivel actual
	_update_for_level(ScoreManager.level)
	_on_level_changed(ScoreManager.level)

	# Conectar señal de vida del jugador al HUD para actualizar la barra de vida
	if personaje_omar and personaje_omar.health_component:
		personaje_omar.health_component.health_changed.connect(_on_player_health_changed)
		# Actualizar barra de vida con valores iniciales
		_on_player_health_changed(personaje_omar.health_component.current_health, personaje_omar.health_component.max_health)

	# Iniciar música de fondo normal
	music_player.stream = MUSICA_FONDO
	music_player.play()

# ============================================================================
# SISTEMA DE SPAWN DE ENEMIGOS
# ============================================================================
func spawn_enemy() -> void:
	# Verificar que el jugador existe antes de spawnear enemigos
	if not personaje_omar:
		return
	
	# Seleccionar tipo de enemigo aleatoriamente: 30% Orco, 70% Slime
	var enemy_scene = ORC if randf() < 0.3 else SLIME
	var enemy = enemy_scene.instantiate()
	
	# Calcular posición de spawn aleatoria en un círculo alrededor del jugador
	# Esto asegura que los enemigos aparezcan fuera de la vista del jugador
	var random_angle : float = randf() * PI * 2  # Ángulo aleatorio en radianes
	var spawn_distance : float = randf_range(270, 300)  # Distancia del jugador
	var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	var spawn_position = spawn_offset + personaje_omar.position
	
	# Definir límites del mapa con un margen de seguridad para evitar spawn en los bordes
	var margin = 20.0
	var min_x = margin
	var max_x = 1280.0 - margin
	var min_y = margin
	var max_y = 656.0 - margin
	
	# Asegurar que la posición de spawn esté dentro de los límites del mapa
	spawn_position.x = clamp(spawn_position.x, min_x, max_x)
	spawn_position.y = clamp(spawn_position.y, min_y, max_y)
	
	# Buscar una posición libre de colisiones (evitar spawn en paredes)
	spawn_position = _find_free_spawn_position(spawn_position, min_x, max_x, min_y, max_y)
	
	enemy.position = spawn_position
	
	# Aplicar multiplicadores de dificultad según el nivel actual
	# Los enemigos serán más rápidos y tendrán más vida en niveles más altos
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	enemy.move_speed = int(enemy.move_speed * speed_mult)
	if "max_health_value" in enemy:
		enemy.max_health_value = int(enemy.max_health_value * health_mult)
	
	add_child(enemy)
	
	# Aplicar dificultad también después de que el enemigo se inicialice completamente
	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(speed_mult, health_mult)
	
	# Conectar señal para detectar cuando el enemigo es eliminado
	if enemy.has_signal("enemy_killed"):
		enemy.enemy_killed.connect(_on_slime_killed_by_player)

# ============================================================================
# MANEJO DE ELIMINACIÓN DE ENEMIGOS
# ============================================================================
func _on_slime_killed_by_player() -> void:
	# Agregar puntos por eliminar enemigo
	ScoreManager.add_points(10)
	
	# Incrementar contador de kills del nivel y notificar cambios
	kills_local_this_level += 1
	ScoreManager.emit_signal("kills_changed", kills_local_this_level, ScoreManager.kills_to_next_level)

	# Si se alcanzó el número de kills necesarios, spawnear el jefe
	if not boss_spawned_this_level and kills_local_this_level >= ScoreManager.kills_to_next_level:
		if ScoreManager.is_max_level():
			# Nivel final: spawnear múltiples jefes
			_spawn_final_level_bosses()
		else:
			# Niveles normales: spawnear un solo jefe
			_spawn_boss_for_level()

# ============================================================================
# SISTEMA DE JEFES (BOSS)
# ============================================================================
func _spawn_boss_for_level() -> void:
	# Evitar spawnear múltiples jefes si ya existe uno
	if spawned_boss and spawned_boss.is_inside_tree():
		return
	
	var boss = BOSS.instantiate()
	# Posicionar el jefe arriba del jugador con un offset horizontal aleatorio
	var offset_x = randf_range(-150, 150)
	boss.position = personaje_omar.position + Vector2(offset_x, -200)
	
	# Aplicar multiplicadores de dificultad según el nivel actual
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	boss.move_speed = int(boss.move_speed * speed_mult)
	if "max_health_value" in boss:
		boss.max_health_value = int(boss.max_health_value * health_mult)
	
	# Usar call_deferred para agregar el boss de forma segura y evitar errores de physics queries
	call_deferred("_add_boss_to_scene", boss, speed_mult, health_mult, false)
	
	spawned_boss = boss
	boss_spawned_this_level = true
	
	# Mostrar mensaje de advertencia en el HUD
	if hud:
		hud.show_boss_incoming()

	# Cambiar a música de batalla de jefe
	music_player.stream = MUSICA_BOSS
	music_player.play()

func _on_boss_killed_by_player() -> void:
	# Otorgar puntos por eliminar al jefe
	ScoreManager.add_points(200)
	
	# Si es el nivel máximo, dejar que complete_level() maneje todo (incluyendo game_won)
	if ScoreManager.is_max_level():
		ScoreManager.complete_level()
		# No hacer nada más aquí, complete_level() emitirá game_won
		return
	
	# Para niveles normales: mostrar mensaje de nivel completado
	if hud:
		hud.show_level_completed()
	
	# Completar el nivel y avanzar al siguiente
	ScoreManager.complete_level()

	# Resetear estado del nivel
	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	_clear_enemies()  # Eliminar todos los enemigos restantes
	
	# Volver a música de fondo normal
	music_player.stream = MUSICA_FONDO
	music_player.play()

# ============================================================================
# GESTIÓN DE CAMBIOS DE NIVEL
# ============================================================================
func _on_level_changed(new_level: int) -> void:
	# Actualizar configuración según el nuevo nivel
	_update_for_level(new_level)
	
	# Resetear todo el estado del nivel anterior
	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	spawned_bosses.clear()
	final_bosses_remaining = 0
	_clear_enemies()  # Limpiar enemigos del nivel anterior

func _on_kills_changed(_kills_this_level: int, _kills_to_next_level: int) -> void:
	pass  # No usado directamente (la lógica está en _on_slime_killed_by_player)

# Ajustar dificultad del spawn según el nivel actual
func _update_for_level(level:int) -> void:
	# Calcular tiempo base de spawn (disminuye con cada nivel para mayor dificultad)
	var base_spawn_time = 3.0
	var base_time = max(0.5, base_spawn_time - (level - 1) * 0.35)
	
	# Aplicar multiplicador de dificultad que reduce el tiempo entre spawns
	# En niveles altos, los enemigos aparecen más frecuentemente
	var spawn_multiplier = ScoreManager.get_spawn_rate_multiplier(level)
	timerSlime = base_time * spawn_multiplier
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

# ============================================================================
# SISTEMA DE SPAWN SEGURO (DETECCIÓN DE COLISIONES)
# ============================================================================
# Busca una posición libre para spawnear enemigos, evitando paredes y obstáculos
func _find_free_spawn_position(initial_position: Vector2, min_x: float, max_x: float, min_y: float, max_y: float) -> Vector2:
	# Primero verificar si la posición inicial está libre
	if _is_position_free(initial_position):
		return initial_position
	
	# Si no está libre, buscar una posición alternativa en círculos concéntricos
	# Esto permite encontrar una posición cercana que esté libre
	var space_state = get_world_2d().direct_space_state
	var search_radius = 30.0  # Radio base de búsqueda
	var max_attempts = 8  # Intentar 8 direcciones diferentes por círculo
	var attempts = 0
	
	# Buscar en 3 círculos concéntricos alrededor de la posición inicial
	for radius_multiplier in range(1, 4):
		var current_radius = search_radius * radius_multiplier
		# Probar posiciones en diferentes ángulos (distribuidas uniformemente)
		for i in range(max_attempts):
			var angle = (TAU / max_attempts) * i  # TAU = 2*PI (ángulo completo)
			var offset = Vector2(cos(angle), sin(angle)) * current_radius
			var test_position = initial_position + offset
			
			# Asegurar que la posición de prueba está dentro de los límites del mapa
			test_position.x = clamp(test_position.x, min_x, max_x)
			test_position.y = clamp(test_position.y, min_y, max_y)
			
			# Si esta posición está libre, usarla
			if _is_position_free(test_position):
				return test_position
			
			attempts += 1
			if attempts >= 20:  # Límite de intentos para evitar loops infinitos
				break
	
	# Si no encontramos posición libre después de todos los intentos, usar la inicial
	# (es mejor spawnear en una colisión que no spawnear enemigos)
	return initial_position

# Verifica si una posición está libre de colisiones con obstáculos del mapa
func _is_position_free(position: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	
	# Crear un círculo pequeño para verificar colisiones en el área de spawn
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 15.0  # Radio del área de verificación
	
	# Crear query de física para verificar colisiones
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = circle_shape
	query.transform.origin = position
	query.collision_mask = 1  # Layer 1 es el TileMap (paredes/obstáculos)
	query.exclude = []  # No excluir nada, queremos detectar todas las colisiones
	
	# Verificar si hay colisiones en esta posición
	var results = space_state.intersect_shape(query)
	
	# Si hay resultados, la posición NO está libre (hay una colisión)
	return results.is_empty()

# ============================================================================
# UTILIDADES Y LIMPIEZA
# ============================================================================
# Elimina todos los enemigos de la escena (usado al cambiar de nivel o completarlo)
func _clear_enemies() -> void:
	for child in get_children():
		# No eliminar el jugador
		if child is Player:
			continue
		# No eliminar timers
		if child is Timer:
			continue
		# Eliminar cualquier entidad con HealthComponent (enemigos) excepto el jugador
		if child.has_node("Components") and child != personaje_omar:
			child.queue_free()

# Actualizar barra de vida del jugador en el HUD cuando cambia
func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if hud and hud.has_method("update_health_bar"):
		hud.update_health_bar(current_health, max_health)

# ============================================================================
# SISTEMA DE NIVEL FINAL (MÚLTIPLES JEFES)
# ============================================================================
# Spawnea múltiples jefes para crear una batalla final desafiante
func _spawn_final_level_bosses() -> void:
	# Evitar spawnear múltiples veces
	if spawned_bosses.size() > 0:
		return
	
	spawned_bosses.clear()
	final_bosses_remaining = 3  # Contador de jefes que deben ser eliminados
	
	# Definir posiciones alrededor del jugador para crear un enfrentamiento estratégico
	var spawn_positions = [
		personaje_omar.position + Vector2(0, -200),  # Arriba
		personaje_omar.position + Vector2(-200, 0),  # Izquierda
		personaje_omar.position + Vector2(200, 0)    # Derecha
	]
	
	# Obtener multiplicadores de dificultad para el nivel final
	var current_level = ScoreManager.level
	var speed_mult = ScoreManager.get_enemy_speed_multiplier(current_level)
	var health_mult = ScoreManager.get_enemy_health_multiplier(current_level)
	
	# Spawnear 3 jefes simultáneamente
	for i in range(3):
		var boss = BOSS.instantiate()
		var valid_position = spawn_positions[i]
		
		boss.position = valid_position
		
		# Aplicar multiplicadores de dificultad antes de agregar a la escena
		boss.move_speed = int(boss.move_speed * speed_mult)
		if "max_health_value" in boss:
			boss.max_health_value = int(boss.max_health_value * health_mult)
		
		# Usar call_deferred para agregar de forma segura y evitar errores de physics
		call_deferred("_add_boss_to_scene", boss, speed_mult, health_mult, true)
		
		spawned_bosses.append(boss)
	
	boss_spawned_this_level = true
	
	# Mostrar advertencia de jefes
	if hud:
		hud.show_boss_incoming()

	# Cambiar a música épica de batalla final
	music_player.stream = MUSICA_BOSS
	music_player.play()

# Manejar la eliminación de un jefe en el nivel final
func _on_final_boss_killed() -> void:
	ScoreManager.add_points(200)
	final_bosses_remaining -= 1
	
	# Verificar si todos los jefes fueron eliminados
	if final_bosses_remaining <= 0:
		# Todos los jefes fueron eliminados - el jugador ganó el juego
		spawned_bosses.clear()
		boss_spawned_this_level = false
		_clear_enemies()
		
		# Completar el nivel final (esto emitirá la señal game_won)
		ScoreManager.complete_level()
		
		# Volver a música normal (aunque se pausará con la pantalla de victoria)
		music_player.stream = MUSICA_FONDO
		music_player.play()

# ============================================================================
# GESTIÓN DE VICTORIA
# ============================================================================
func _on_game_won(score: int, _final_level: int, stats: Dictionary) -> void:
	# Mostrar pantalla de victoria con puntuación y estadísticas
	if victory_screen:
		victory_screen.show_victory(score, stats)
	else:
		# Fallback: buscar la pantalla manualmente si no está en @onready
		var found_screen = get_node_or_null("VictoryScreen")
		if found_screen:
			found_screen.show_victory(score, stats)
		else:
			push_error("[World] ERROR: VictoryScreen no encontrado")

# ============================================================================
# FUNCIÓN AUXILIAR PARA AGREGAR BOSS
# ============================================================================
# Agrega un boss a la escena de forma segura usando call_deferred
func _add_boss_to_scene(boss: Node, speed_mult: float, health_mult: float, is_final_boss: bool) -> void:
	add_child(boss)
	
	# Aplicar dificultad también después de que el boss se inicialice completamente
	if boss.has_method("apply_difficulty"):
		boss.apply_difficulty(speed_mult, health_mult)
	
	# Conectar señal del boss para detectar cuando es eliminado
	if boss.has_signal("boss_killed"):
		if is_final_boss:
			# Conectar a la función especial para nivel final
			boss.boss_killed.connect(_on_final_boss_killed)
		else:
			# Conectar a la función normal para niveles regulares
			boss.boss_killed.connect(_on_boss_killed_by_player)
