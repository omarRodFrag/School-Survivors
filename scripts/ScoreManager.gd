extends Node

const MAX_LEVEL = 3

signal score_changed(new_score)
signal level_changed(new_level)
signal kills_changed(kills_this_level, kills_to_next_level)
signal game_won(score: int, final_level: int, stats: Dictionary)

var score: int = 0
var level: int = 1
var kills_this_level: int = 0
var kills_to_next_level: int = 10

func _ready() -> void:
	_update_kills_goal()
	# Emitir estado inicial para que HUD lo muestre al arrancar
	emit_signal("score_changed", score)
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

func _update_kills_goal() -> void:
	kills_to_next_level = 10 * level

func add_points(points: int) -> void:
	score += points
	emit_signal("score_changed", score)

# No usaremos add_kill para avanzar niveles automáticamente en nuestro flujo,
# lo dejamos por si quieres usarlo en otra parte.
func add_kill(count_as_level_kill: bool = true) -> void:
	if count_as_level_kill:
		kills_this_level += 1
		emit_signal("kills_changed", kills_this_level, kills_to_next_level)
		if kills_this_level >= kills_to_next_level:
			_next_level()

# Método que indica que el nivel fue completado (ej: moriste al boss)
func complete_level() -> void:
	# Registrar nivel completado antes de verificar si es el final
	if GameStats:
		GameStats.add_level_completed()
	
	# Verificar si es el nivel final
	if level >= MAX_LEVEL:
		# El juego ha sido completado - emitir señal de victoria
		var stats = {}
		if GameStats:
			stats = GameStats.get_all_stats()
		game_won.emit(score, level, stats)
		return
	
	_next_level()

func _next_level() -> void:
	level += 1
	kills_this_level = 0
	_update_kills_goal()
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

func reset() -> void:
	score = 0
	level = 1
	kills_this_level = 0
	_update_kills_goal()
	emit_signal("score_changed", score)
	emit_signal("level_changed", level)
	emit_signal("kills_changed", kills_this_level, kills_to_next_level)

# Multiplicadores de dificultad basados en el nivel
func get_spawn_rate_multiplier(level_num: int) -> float:
	# Reduce el tiempo entre spawns (más enemigos)
	# Nivel 1 = 1.0, Nivel 15 = ~0.3 (muy rápido)
	return max(0.3, 1.0 - (level_num - 1) * 0.05)

func get_enemy_speed_multiplier(level_num: int) -> float:
	# Aumenta velocidad de enemigos
	# Nivel 1 = 1.0, Nivel 15 = 2.0
	return min(2.0, 1.0 + (level_num - 1) * 0.071)

func get_enemy_health_multiplier(level_num: int) -> float:
	# Aumenta vida de enemigos
	# Nivel 1 = 1.0, Nivel 15 = 3.0
	return min(3.0, 1.0 + (level_num - 1) * 0.143)

func is_max_level() -> bool:
	return level >= MAX_LEVEL
