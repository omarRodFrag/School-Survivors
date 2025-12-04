# Botón de ataque táctil para dispositivos móviles
# Permite al jugador atacar en una dirección específica tocando la pantalla
extends Control

# ============================================================================
# SEÑAL
# ============================================================================
signal attack_requested(direction: Vector2)  # Se emite con la dirección del ataque

# ============================================================================
# VARIABLES DE ESTADO
# ============================================================================
var touch_start_pos: Vector2  # Posición inicial del toque
var is_touching := false  # Indica si hay un toque activo
var touch_area_size := Vector2(120, 120)  # Tamaño del área táctil del botón

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
@onready var button_label: Label = $ButtonLabel

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar tamaño mínimo del botón
	custom_minimum_size = touch_area_size
	
	# Posicionar en esquina inferior derecha de la pantalla
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -touch_area_size.x - 20
	offset_right = -20
	offset_top = -touch_area_size.y - 20
	offset_bottom = -20
	
	# Configurar texto del label
	if button_label:
		button_label.text = "ATAQUE"
		button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Solo visible en dispositivos móviles
	var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	visible = is_mobile

# ============================================================================
# ENTRADA TÁCTIL
# ============================================================================
func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Detectar toque en el área del botón
	if event is InputEventScreenTouch:
		var touch_pos = event.position
		
		# Verificar si el toque está dentro del área del botón
		if get_global_rect().has_point(touch_pos):
			if event.pressed:
				# Iniciar toque: guardar posición y mostrar feedback visual
				is_touching = true
				touch_start_pos = touch_pos
				modulate = Color(0.7, 0.7, 0.7, 1.0)  # Oscurecer para feedback
			else:
				# Finalizar toque: calcular dirección y atacar
				if is_touching:
					# Calcular dirección desde el jugador hacia el punto tocado
					var world = get_tree().current_scene
					if world:
						var player = world.get_node_or_null("personaje_Omar")
						if player:
							var direction = (touch_pos - player.global_position).normalized()
							# Si la dirección es cero (toque muy cerca del jugador), usar dirección por defecto
							if direction == Vector2.ZERO:
								direction = Vector2.UP
							attack_requested.emit(direction)
					is_touching = false
					# Restaurar color normal
					modulate = Color.WHITE
	
	# Mantener feedback visual mientras se arrastra
	elif event is InputEventScreenDrag:
		if is_touching and get_global_rect().has_point(event.position):
			# Mantener feedback visual mientras se arrastra
			pass
