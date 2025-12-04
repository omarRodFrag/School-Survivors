# Gestor de puntuación y niveles del juego
# Autoload singleton que gestiona el progreso del juego, puntuación y dificultad
extends Node

# ============================================================================
# CONSTANTES
# ============================================================================
const MAX_LEVEL = 15  # Nivel máximo del juego (nivel final)

# ============================================================================
# SEÑALES
# ============================================================================
signal score_changed(new_score)  # Se emite cuando cambia la puntuación
signal level_changed(new_level)  # Se emite cuando cambia el nivel
signal kills_changed(kills_this_level, kills_to_next_level)  # Se emite cuando cambian los kills
signal game_won(score: int, final_level: int, stats: Dictionary)  # Se emite cuando se gana el juego

# ============================================================================
# VARIABLES DE ESTADO
# ============================================================================
var score: int = 0  # Puntuación total del jugador
var level: int = 1  # Nivel actual del juego
var kills_this_level: int = 0  # Enemigos eliminados en el nivel actual
var kills_to_next_level: int = 10  # Enemigos necesarios para avanzar de nivel

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	_update_kills_goal()
	# Emitir estado inicial para que el HUD lo muestre al iniciar
	emit_signal("score_changed", score)
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

# ============================================================================
# GESTIÓN DE PROGRESO
# ============================================================================
# Actualiza el objetivo de kills necesario para avanzar de nivel
func _update_kills_goal() -> void:
	kills_to_next_level = 10 * level  # Aumenta con cada nivel

# Agrega puntos a la puntuación total
func add_points(points: int) -> void:
	score += points
	emit_signal("score_changed", score)

# Agrega un kill (método opcional, no se usa en el flujo principal)
func add_kill(count_as_level_kill: bool = true) -> void:
	if count_as_level_kill:
		kills_this_level += 1
		emit_signal("kills_changed", kills_this_level, kills_to_next_level)
		if kills_this_level >= kills_to_next_level:
			_next_level()

# ============================================================================
# GESTIÓN DE NIVELES
# ============================================================================
# Completar el nivel actual y avanzar (o ganar si es el nivel final)
func complete_level() -> void:
	# Registrar nivel completado en estadísticas
	if GameStats:
		GameStats.add_level_completed()
	
	# Verificar si es el nivel final
	if level >= MAX_LEVEL:
		# El juego ha sido completado - emitir señal de victoria con estadísticas
		var stats = {}
		if GameStats:
			stats = GameStats.get_all_stats()
		game_won.emit(score, level, stats)
		return
	
	# Avanzar al siguiente nivel
	_next_level()

# Avanza al siguiente nivel y resetea el progreso
func _next_level() -> void:
	level += 1
	kills_this_level = 0
	_update_kills_goal()  # Actualizar objetivo de kills para el nuevo nivel
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

# Resetea todo el estado del juego a los valores iniciales
func reset() -> void:
	score = 0
	level = 1
	kills_this_level = 0
	_update_kills_goal()
	emit_signal("score_changed", score)
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

# ============================================================================
# MULTIPLICADORES DE DIFICULTAD
# ============================================================================
# Estos multiplicadores aumentan la dificultad progresivamente según el nivel

# Multiplicador de tasa de spawn: reduce el tiempo entre aparición de enemigos
# En niveles más altos, los enemigos aparecen más frecuentemente
func get_spawn_rate_multiplier(level_num: int) -> float:
	# Reduce el tiempo entre spawns (más enemigos)
	# Nivel 1 = 1.0, Nivel 15 = ~0.3 (muy rápido)
	return max(0.3, 1.0 - (level_num - 1) * 0.05)

# Multiplicador de velocidad de enemigos: aumenta la velocidad según el nivel
func get_enemy_speed_multiplier(level_num: int) -> float:
	# Aumenta velocidad de enemigos
	# Nivel 1 = 1.0, Nivel 15 = 2.0 (doble de velocidad)
	return min(2.0, 1.0 + (level_num - 1) * 0.071)

# Multiplicador de vida de enemigos: aumenta la vida según el nivel
func get_enemy_health_multiplier(level_num: int) -> float:
	# Aumenta vida de enemigos
	# Nivel 1 = 1.0, Nivel 15 = 3.0 (triple de vida)
	return min(3.0, 1.0 + (level_num - 1) * 0.143)

# ============================================================================
# UTILIDADES
# ============================================================================
# Verifica si el nivel actual es el nivel máximo
func is_max_level() -> bool:
	return level >= MAX_LEVEL
