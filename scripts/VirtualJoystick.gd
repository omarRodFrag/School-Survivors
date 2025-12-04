# Joystick virtual para dispositivos móviles
# Permite controlar el movimiento del jugador con el dedo en pantalla
extends Control

# ============================================================================
# SEÑAL
# ============================================================================
signal joystick_input(value: Vector2)  # Se emite con la dirección del joystick (-1 a 1)

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
var is_pressed := false  # Indica si el joystick está siendo usado
var joystick_radius := 50.0  # Radio del joystick (área de movimiento)
var handle_radius := 20.0  # Radio del handle (botón central)
var deadzone := 0.2  # Zona muerta para evitar movimiento accidental

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
@onready var background: ColorRect = $Background  # Fondo circular del joystick
@onready var handle: ColorRect = $Handle  # Handle central que se mueve

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar tamaños del fondo y handle
	background.size = Vector2(joystick_radius * 2, joystick_radius * 2)
	background.position = -Vector2(joystick_radius, joystick_radius)
	handle.size = Vector2(handle_radius * 2, handle_radius * 2)
	handle.position = -Vector2(handle_radius, handle_radius)
	
	# Configurar pivote para hacer los elementos circulares
	background.set_pivot_offset(background.size / 2)
	handle.set_pivot_offset(handle.size / 2)
	
	# Solo visible en dispositivos móviles
	var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	visible = is_mobile

# ============================================================================
# ENTRADA TÁCTIL
# ============================================================================
func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Detectar toque inicial
	if event is InputEventScreenTouch:
		var touch_pos = event.position
		if event.pressed:
			# Verificar si el toque está dentro del área del joystick
			var local_pos = touch_pos - global_position
			if local_pos.length() <= joystick_radius * 2:
				is_pressed = true
				_update_handle_position(touch_pos)
		else:
			# Soltar: resetear joystick
			if is_pressed:
				is_pressed = false
				_reset_handle()
				joystick_input.emit(Vector2.ZERO)
	
	# Detectar arrastre mientras se mantiene presionado
	elif event is InputEventScreenDrag:
		if is_pressed:
			_update_handle_position(event.position)

# ============================================================================
# ACTUALIZACIÓN DEL HANDLE
# ============================================================================
# Actualiza la posición del handle y calcula el valor del joystick
func _update_handle_position(touch_pos: Vector2) -> void:
	var local_pos = touch_pos - global_position
	var distance = local_pos.length()
	
	# Limitar el handle al radio del joystick (no puede salirse del círculo)
	if distance > joystick_radius:
		local_pos = local_pos.normalized() * joystick_radius
	
	# Actualizar posición del handle
	handle.position = local_pos - Vector2(handle_radius, handle_radius)
	
	# Calcular valor del joystick normalizado (-1 a 1 en cada eje)
	var value = local_pos / joystick_radius
	
	# Aplicar deadzone para evitar movimiento accidental
	if value.length() < deadzone:
		value = Vector2.ZERO
	
	# Emitir señal con la dirección del joystick
	joystick_input.emit(value)

# ============================================================================
# RESET DEL JOYSTICK
# ============================================================================
# Regresa el handle a la posición central
func _reset_handle() -> void:
	handle.position = -Vector2(handle_radius, handle_radius)
