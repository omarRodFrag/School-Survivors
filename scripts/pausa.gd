# Sistema de pausa del juego
# Permite pausar y reanudar el juego con una tecla, mostrando/ocultando elementos de la interfaz
extends CanvasLayer

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
@onready var salir_boton: TextureButton = $Salir_Boton

# ============================================================================
# CONFIGURACIÓN DE EFECTOS DE BOTONES
# ============================================================================
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)  # Escala al pasar el mouse
@export var pressed_scale: Vector2 = Vector2(0.95, 0.95)  # Escala al presionar

# ============================================================================
# DETECCIÓN DE PAUSA
# ============================================================================
func _physics_process(_delta: float) -> void:
	# Detectar cuando se presiona la tecla de pausa (configurada en Input Map)
	if Input.is_action_just_pressed("Pausa"):
		# Alternar estado de pausa del juego
		get_tree().paused = not get_tree().paused
		
		# Mostrar/ocultar elementos de la interfaz de pausa
		$ColorRect.visible = not $ColorRect.visible
		$TextureRect.visible = not $TextureRect.visible
		$Salir_Boton.visible = not $Salir_Boton.visible

# ============================================================================
# CONFIGURACIÓN DE EFECTOS EN BOTONES
# ============================================================================
func _ready():
	# Configurar efectos visuales para todos los botones de la escena
	for btn in get_children():
		if btn is TextureButton:
			# Conectar señales de mouse para efectos de hover y presión
			btn.connect("mouse_entered", Callable(self, "_on_mouse_entered").bind(btn))
			btn.connect("mouse_exited", Callable(self, "_on_mouse_exited_or_released").bind(btn))
			btn.connect("pressed", Callable(self, "_on_pressed").bind(btn))
			# Guardar escala original para restaurarla
			btn.set_meta("original_scale", btn.scale)

# Efecto cuando el mouse entra al botón
func _on_mouse_entered(btn):
	btn.scale = hover_scale

# Efecto cuando el mouse sale o se suelta el botón
func _on_mouse_exited_or_released(btn):
	btn.scale = btn.get_meta("original_scale")

# Efecto cuando se presiona el botón
func _on_pressed(btn):
	btn.scale = pressed_scale

# ============================================================================
# ACCIÓN DEL BOTÓN SALIR
# ============================================================================
func _on_salir_boton_pressed() -> void:
	get_tree().quit()
