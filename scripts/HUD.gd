# res://ui/HUD.gd
extends CanvasLayer

@onready var label_score: Label = $MarginContainer/VBoxContainer/Panel/LabelScore
@onready var label_level: Label = $MarginContainer/VBoxContainer/Panel/LabelLevel
@onready var label_kills: Label = $MarginContainer/VBoxContainer/Panel/LabelKills
@onready var message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _msg_timer: Timer = Timer.new()

var message_duration := 2.0
var _score_manager: Node = null

func _ready() -> void:
	_msg_timer.one_shot = true
	add_child(_msg_timer)
	_msg_timer.connect("timeout", Callable(self, "_on_message_timeout"))

	# Aseguramos que las labels existen (debug)
	if not label_score:
		print("[HUD] label_score no encontrado")
	if not label_level:
		print("[HUD] label_level no encontrado")
	if not label_kills:
		print("[HUD] label_kills no encontrado")
	if not message_label:
		print("[HUD] message_label no encontrado")

	label_score.text = "Puntos: 0"
	label_level.text = "Nivel: 1"
	label_kills.text = "Progreso: 0 / 10"
	message_label.visible = false

	# Intentamos enlazar al ScoreManager de forma robusta
	if Engine.has_singleton("ScoreManager"):
		_score_manager = ScoreManager
		print("[HUD] ScoreManager encontrado via Engine.has_singleton")
	else:
		_score_manager = get_node_or_null("/root/ScoreManager")
		if _score_manager:
			print("[HUD] ScoreManager encontrado en /root/ScoreManager")
		else:
			print("[HUD] ScoreManager NO encontrado. Revisa Autoload (Project -> Project Settings -> Autoload).")

	# Conectar señales si encontramos el ScoreManager
	if _score_manager:
		# Para evitar dobles conexiones, desconectamos primero si existieran (silencioso)
		# (catch en try para evitar errores si no está conectado)
		# Conectar señales
		_score_manager.connect("score_changed", Callable(self, "_on_score_changed"))
		_score_manager.connect("level_changed", Callable(self, "_on_level_changed"))
		_score_manager.connect("kills_changed", Callable(self, "_on_kills_changed"))
		print("[HUD] Conectadas señales a ScoreManager")

		# Forzar sincronización inicial (en caso de que ScoreManager ya tuviera estado)
		if "score" in _score_manager:
			_on_score_changed(_score_manager.score)
		if "level" in _score_manager:
			_on_level_changed(_score_manager.level)
		# kills_changed se emitirá cuando sea necesario

func _on_score_changed(new_score: int) -> void:
	print("[HUD] _on_score_changed recibido:", new_score) # DEBUG: ver si llega la señal
	label_score.text = "Puntos: %d" % new_score

func _on_level_changed(new_level: int) -> void:
	print("[HUD] _on_level_changed recibido:", new_level)
	label_level.text = "Nivel: %d" % new_level
	_show_message("¡Nivel %d!" % new_level, 1.6)

func _on_kills_changed(kills_this_level: int, kills_to_next_level: int) -> void:
	print("[HUD] _on_kills_changed recibido:", kills_this_level, kills_to_next_level)
	label_kills.text = "Progreso: %d / %d" % [kills_this_level, kills_to_next_level]

func _show_message(text: String, duration: float = -1.0) -> void:
	if duration > 0.0:
		_msg_timer.wait_time = duration
	else:
		_msg_timer.wait_time = message_duration
	message_label.text = text
	message_label.visible = true
	_msg_timer.start()

func _on_message_timeout() -> void:
	message_label.visible = false

func show_boss_incoming() -> void:
	_show_message("¡Jefe incoming!", 2.0)

func show_level_completed() -> void:
	_show_message("¡Nivel completado!", 2.0)
