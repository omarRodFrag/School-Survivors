# Gestor de estadísticas del juego
# Autoload singleton que rastrea y almacena estadísticas de la partida actual
extends Node

# ============================================================================
# ESTADÍSTICAS
# ============================================================================
var play_time: float = 0.0  # Tiempo total de juego en segundos
var slimes_killed: int = 0  # Contador de slimes eliminados
var orcs_killed: int = 0  # Contador de orcos eliminados
var bosses_killed: int = 0  # Contador de jefes eliminados
var total_damage_taken: int = 0  # Daño total recibido por el jugador
var levels_completed: int = 0  # Niveles completados

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	reset_stats()  # Inicializar todas las estadísticas en 0

# ============================================================================
# TRACKING DE TIEMPO
# ============================================================================
# Actualiza el tiempo de juego cada frame
func _process(delta: float) -> void:
	play_time += delta

# ============================================================================
# RESET DE ESTADÍSTICAS
# ============================================================================
# Resetea todas las estadísticas a sus valores iniciales
func reset_stats() -> void:
	play_time = 0.0
	slimes_killed = 0
	orcs_killed = 0
	bosses_killed = 0
	total_damage_taken = 0
	levels_completed = 0

# ============================================================================
# REGISTRO DE ELIMINACIONES
# ============================================================================
# Incrementa el contador de slimes eliminados
func add_slime_kill() -> void:
	slimes_killed += 1

# Incrementa el contador de orcos eliminados
func add_orc_kill() -> void:
	orcs_killed += 1

# Incrementa el contador de jefes eliminados
func add_boss_kill() -> void:
	bosses_killed += 1

# ============================================================================
# REGISTRO DE DAÑO
# ============================================================================
# Agrega daño recibido al total (solo para el jugador)
func add_damage_taken(amount: int) -> void:
	total_damage_taken += amount

# ============================================================================
# REGISTRO DE PROGRESO
# ============================================================================
# Incrementa el contador de niveles completados
func add_level_completed() -> void:
	levels_completed += 1

# ============================================================================
# UTILIDADES
# ============================================================================
# Obtiene el tiempo de juego actual
func get_play_time() -> float:
	return play_time

# Formatea el tiempo en segundos a formato MM:SS
func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

# Retorna todas las estadísticas en un diccionario
# Útil para mostrar en la pantalla de victoria o guardado
func get_all_stats() -> Dictionary:
	return {
		"play_time": play_time,
		"slimes_killed": slimes_killed,
		"orcs_killed": orcs_killed,
		"bosses_killed": bosses_killed,
		"total_damage_taken": total_damage_taken,
		"levels_completed": levels_completed
	}
