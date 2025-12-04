# Componente de salud reutilizable
# Puede ser usado por jugador, enemigos y jefes para gestionar vida, daño y barras de salud
class_name HealthComponent extends Node2D

# ============================================================================
# SEÑALES
# ============================================================================
signal death()  # Se emite cuando la vida llega a 0
signal health_changed(current_health: int, max_health: int)  # Se emite cuando cambia la vida

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
@export var progress_bar : ProgressBar  # Barra de progreso opcional para mostrar vida
@export var current_health := 100  # Vida actual
@export var max_health := 100  # Vida máxima

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Actualizar la barra de salud con los valores iniciales
	update_health_bar()

# ============================================================================
# ACTUALIZACIÓN DE BARRA DE SALUD
# ============================================================================
# Actualiza la barra de progreso visual y emite señal de cambio
func update_health_bar():
	if progress_bar:
		# Configurar el valor máximo de la barra si no está configurado
		# Por defecto, las barras suelen tener max_value = 100
		if progress_bar.max_value == 100.0 and max_health != 100:
			progress_bar.max_value = max_health
		progress_bar.value = current_health
	
	# Emitir señal para que otros sistemas (como el HUD) sepan que cambió la vida
	health_changed.emit(current_health, max_health)

# ============================================================================
# SISTEMA DE DAÑO
# ============================================================================
# Recibe daño y actualiza la vida, emitiendo señales correspondientes
func receive_damage(amount : int):
	# Reducir vida asegurándose de que no baje de 0
	current_health = clamp(current_health - amount, 0, max_health)
	
	# Registrar daño recibido en GameStats (solo para el jugador)
	# Esto permite llevar estadísticas de cuánto daño recibió el jugador
	if GameStats and get_parent() is Player:
		GameStats.add_damage_taken(amount)
	
	# Actualizar la barra visual y notificar cambios
	update_health_bar()
	
	# Si la vida llegó a 0, emitir señal de muerte
	if current_health <= 0:
		on_death()

# ============================================================================
# SISTEMA DE CURA
# ============================================================================
# Aplica curación y actualiza la vida
func apply_health(amount : int):
	# Aumentar vida asegurándose de que no exceda la vida máxima
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_bar()

# ============================================================================
# GESTIÓN DE MUERTE
# ============================================================================
# Emite la señal de muerte para que otros sistemas reaccionen
func on_death():
	death.emit()
