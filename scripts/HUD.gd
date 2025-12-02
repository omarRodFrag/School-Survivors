# res://ui/HUD.gd
extends CanvasLayer

@onready var label_score: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelScore
@onready var label_level: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelLevel
@onready var label_kills: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelKills
@onready var message_panel: Panel = $MessageCenterContainer/MessagePanel
@onready var message_label: Label = $MessageCenterContainer/MessagePanel/MessageLabel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBarContainer/HealthBar
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
	if message_panel:
		message_panel.visible = false
	if message_label:
		message_label.visible = false
	
	# Configurar barra de vida inicial (Godot 4 usa max_value)
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = 100

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
		_score_manager.connect("score_changed", Callable(self, "_on_score_changed"))
		_score_manager.connect("level_changed", Callable(self, "_on_level_changed"))
		_score_manager.connect("kills_changed", Callable(self, "_on_kills_changed"))
		print("[HUD] Conectadas señales a ScoreManager")

		if "score" in _score_manager:
			_on_score_changed(_score_manager.score)
		if "level" in _score_manager:
			_on_level_changed(_score_manager.level)

func _on_score_changed(new_score: int) -> void:
	print("[HUD] _on_score_changed recibido:", new_score)
	label_score.text = "Puntos: %d" % new_score

func _on_level_changed(new_level: int) -> void:
	print("[HUD] _on_level_changed recibido:", new_level)
	label_level.text = "Nivel: %d" % new_level
	_show_message("¡Nivel %d!" % new_level, 1.6)

func _on_kills_changed(kills_this_level: int, kills_to_next_level: int) -> void:
	print("[HUD] _on_kills_changed recibido:", kills_this_level, kills_to_next_level)
	label_kills.text = "Progreso: %d / %d" % [kills_this_level, kills_to_next_level]

func _show_message(text: String, duration: float = -1.0) -> void:
	if not message_label or not message_panel:
		return
		
	if duration > 0.0:
		_msg_timer.wait_time = duration
	else:
		_msg_timer.wait_time = message_duration
	message_label.text = text
	
	# Mostrar panel y label con animación (fade in y scale)
	message_panel.modulate.a = 0.0
	message_label.modulate.a = 0.0
	message_label.scale = Vector2(0.8, 0.8)
	message_panel.scale = Vector2(0.8, 0.8)
	message_panel.visible = true
	message_label.visible = true
	
	# Crear tween para animación suave
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(message_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_panel, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_msg_timer.start()

func _on_message_timeout() -> void:
	# Animación de fade out antes de ocultar
	if message_panel and message_label and message_panel.visible:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(message_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(message_label, "modulate:a", 0.0, 0.15)
		tween.tween_property(message_label, "scale", Vector2(0.8, 0.8), 0.15)
		tween.tween_property(message_panel, "scale", Vector2(0.8, 0.8), 0.15)
		tween.tween_callback(func(): 
			message_panel.visible = false
			message_label.visible = false
		).set_delay(0.15)

func show_boss_incoming() -> void:
	_show_message("¡Jefe en Camino!", 2.0)

func show_level_completed() -> void:
	_show_message("¡Nivel completado!", 2.0)

func update_health_bar(current_health: int, max_health: int) -> void:
	if not health_bar:
		return

	# Evitar división por cero
	if max_health <= 0:
		max_health = 1

	# Godot 4 usa max_value
	health_bar.max_value = max_health
	health_bar.value = clamp(current_health, 0, max_health)
	
	# Cambiar color según porcentaje de vida
	var health_percentage = float(health_bar.value) / float(health_bar.max_value)

	# Crear estilos dinámicamente
	var style_green = StyleBoxFlat.new()
	style_green.bg_color = Color(0, 0.7293443, 0.060525373, 1)
	style_green.corner_radius_top_left = 3
	style_green.corner_radius_top_right = 3
	style_green.corner_radius_bottom_right = 3
	style_green.corner_radius_bottom_left = 3
	
	var style_red = StyleBoxFlat.new()
	style_red.bg_color = Color(0.7293443, 0.060525373, 0, 1)
	style_red.corner_radius_top_left = 3
	style_red.corner_radius_top_right = 3
	style_red.corner_radius_bottom_right = 3
	style_red.corner_radius_bottom_left = 3
	
	if health_percentage <= 0.3:
		# Rojo para vida baja — usar set con path de propiedad
		health_bar.set("theme_override_styles/fill", style_red)
	else:
		# Verde para vida normal/alta
		health_bar.set("theme_override_styles/fill", style_green)
