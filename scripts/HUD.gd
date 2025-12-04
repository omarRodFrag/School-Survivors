# res://ui/HUD.gd
# Interfaz de usuario principal (Heads-Up Display)
# Muestra puntuación, nivel, progreso y mensajes temporales al jugador
extends CanvasLayer

# ============================================================================
# REFERENCIAS A NODOS DE LA INTERFAZ
# ============================================================================
@onready var label_score: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelScore
@onready var label_level: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelLevel
@onready var label_kills: Label = $MarginContainer/VBoxContainer/Panel/VBoxContent/LabelKills
@onready var message_label: Label = $MessageCenterContainer/MessagePanel/MessageLabel
@onready var message_panel: Panel = $MessageCenterContainer/MessagePanel
@onready var _msg_timer: Timer = Timer.new()

# ============================================================================
# VARIABLES DE CONFIGURACIÓN
# ============================================================================
var message_duration := 2.0  # Duración predeterminada de los mensajes
var _score_manager: Node = null  # Referencia al ScoreManager

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar timer para mensajes temporales
	_msg_timer.one_shot = true
	add_child(_msg_timer)
	_msg_timer.connect("timeout", Callable(self, "_on_message_timeout"))

	# Verificar que las labels existan (debug)
	if not label_score:
		print("[HUD] label_score no encontrado")
	if not label_level:
		print("[HUD] label_level no encontrado")
	if not label_kills:
		print("[HUD] label_kills no encontrado")
	if not message_label:
		print("[HUD] message_label no encontrado")

	# Inicializar textos con valores por defecto
	label_score.text = "Puntos: 0"
	label_level.text = "Nivel: 1"
	label_kills.text = "Progreso: 0 / 10"
	
	# Ocultar panel de mensajes inicialmente
	if message_panel:
		message_panel.visible = false
	if message_label:
		message_label.visible = false

	# Conectar al ScoreManager de forma robusta (autoload)
	if Engine.has_singleton("ScoreManager"):
		_score_manager = ScoreManager
		print("[HUD] ScoreManager encontrado via Engine.has_singleton")
	else:
		_score_manager = get_node_or_null("/root/ScoreManager")
		if _score_manager:
			print("[HUD] ScoreManager encontrado en /root/ScoreManager")
		else:
			print("[HUD] ScoreManager NO encontrado. Revisa Autoload (Project -> Project Settings -> Autoload).")

	# Conectar señales del ScoreManager para actualizar el HUD automáticamente
	if _score_manager:
		_score_manager.connect("score_changed", Callable(self, "_on_score_changed"))
		_score_manager.connect("level_changed", Callable(self, "_on_level_changed"))
		_score_manager.connect("kills_changed", Callable(self, "_on_kills_changed"))
		print("[HUD] Conectadas señales a ScoreManager")

		# Sincronizar valores iniciales en caso de que ScoreManager ya tuviera estado
		if "score" in _score_manager:
			_on_score_changed(_score_manager.score)
		if "level" in _score_manager:
			_on_level_changed(_score_manager.level)
	
	# Nota: Los controles táctiles se gestionan automáticamente en sus propios scripts

# ============================================================================
# CALLBACKS DE ACTUALIZACIÓN DEL HUD
# ============================================================================
# Actualiza la etiqueta de puntuación cuando cambia
func _on_score_changed(new_score: int) -> void:
	label_score.text = "Puntos: %d" % new_score

# Actualiza la etiqueta de nivel y muestra mensaje cuando cambia
func _on_level_changed(new_level: int) -> void:
	label_level.text = "Nivel: %d" % new_level
	
	# No mostrar mensaje de nivel si es el nivel máximo (se mostrará la pantalla de victoria después)
	if ScoreManager and new_level >= ScoreManager.MAX_LEVEL:
		return  # Es el nivel final, no mostrar mensaje
	
	_show_message("¡Nivel %d!" % new_level, 1.6)

# Actualiza la barra de progreso de kills
func _on_kills_changed(kills_this_level: int, kills_to_next_level: int) -> void:
	label_kills.text = "Progreso: %d / %d" % [kills_this_level, kills_to_next_level]

# ============================================================================
# SISTEMA DE MENSAJES TEMPORALES
# ============================================================================
# Muestra un mensaje temporal con animación de entrada y salida
func _show_message(text: String, duration: float = -1.0) -> void:
	if not message_label or not message_panel:
		return
		
	# Configurar duración del mensaje
	if duration > 0.0:
		_msg_timer.wait_time = duration
	else:
		_msg_timer.wait_time = message_duration
	
	message_label.text = text
	
	# Configurar estado inicial para animación (transparente y pequeño)
	message_panel.modulate.a = 0.0
	message_label.modulate.a = 0.0
	message_label.scale = Vector2(0.8, 0.8)
	message_panel.scale = Vector2(0.8, 0.8)
	message_panel.visible = true
	message_label.visible = true
	
	# Crear animación de entrada (fade in y scale up)
	var tween = create_tween()
	tween.set_parallel(true)  # Animar múltiples propiedades en paralelo
	tween.tween_property(message_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(message_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(message_panel, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	_msg_timer.start()  # Iniciar timer para ocultar después de la duración

# Se llama cuando el timer del mensaje termina, ejecuta animación de salida
func _on_message_timeout() -> void:
	# Animación de salida (fade out y scale down)
	if message_panel and message_label and message_panel.visible:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(message_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(message_label, "modulate:a", 0.0, 0.15)
		tween.tween_property(message_label, "scale", Vector2(0.8, 0.8), 0.15)
		tween.tween_property(message_panel, "scale", Vector2(0.8, 0.8), 0.15)
		# Ocultar después de la animación
		tween.tween_callback(func(): 
			message_panel.visible = false
			message_label.visible = false
		).set_delay(0.15)

# ============================================================================
# MENSAJES ESPECÍFICOS
# ============================================================================
# Muestra mensaje de jefe entrante
func show_boss_incoming() -> void:
	_show_message("¡Jefe incoming!", 2.0)

# Muestra mensaje de nivel completado
func show_level_completed() -> void:
	_show_message("¡Nivel completado!", 2.0)

# ============================================================================
# ACTUALIZACIÓN DE BARRA DE VIDA
# ============================================================================
# Función placeholder para actualizar barra de vida (compatibilidad futura)
func update_health_bar(_current_health: int, _max_health: int) -> void:
	# Esta función puede ser llamada desde world.gd si hay una barra de vida en el HUD
	# Por ahora solo la dejamos aquí por compatibilidad
	pass
