# Sistema de efectos visuales para botones del menú
# Agrega efectos de hover y presión a todos los botones hijos
extends Node

# ============================================================================
# CONFIGURACIÓN DE EFECTOS
# ============================================================================
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)  # Escala al pasar el mouse (5% más grande)
@export var pressed_scale: Vector2 = Vector2(0.95, 0.95)  # Escala al presionar (5% más pequeño)

# ============================================================================
# CONFIGURACIÓN DE BOTONES
# ============================================================================
func _ready():
	# Configurar efectos visuales para todos los botones hijos
	for btn in get_children():
		if btn is TextureButton:
			# Conectar señales de mouse para efectos interactivos
			btn.connect("mouse_entered", Callable(self, "_on_mouse_entered").bind(btn))
			btn.connect("mouse_exited", Callable(self, "_on_mouse_exited_or_released").bind(btn))
			btn.connect("pressed", Callable(self, "_on_pressed").bind(btn))
			# Guardar escala original para poder restaurarla
			btn.set_meta("original_scale", btn.scale)

# ============================================================================
# CALLBACKS DE EFECTOS
# ============================================================================
# Efecto cuando el mouse entra al área del botón
func _on_mouse_entered(btn):
	btn.scale = hover_scale

# Efecto cuando el mouse sale del área o se suelta el botón
func _on_mouse_exited_or_released(btn):
	# Restaurar escala original guardada
	btn.scale = btn.get_meta("original_scale")

# Efecto cuando se presiona el botón
func _on_pressed(btn):
	btn.scale = pressed_scale
