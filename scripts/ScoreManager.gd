extends Node

signal score_changed(new_score)
signal level_changed(new_level)
signal kills_changed(kills_this_level, kills_to_next_level)

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
