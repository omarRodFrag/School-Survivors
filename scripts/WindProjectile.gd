# Proyectil de viento disparado por el jugador
# Se mueve en línea recta, causa daño a enemigos y tiene knockback
extends Area2D

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
@export var speed: float = 30.0  # Velocidad del proyectil
@export var damage: int = 50  # Daño que causa a los enemigos
@export var lifetime: float = 1.0  # Tiempo de vida antes de desaparecer
@export var knockback_strength: float = 160.0  # Fuerza del empuje (knockback)
@export var pierce: bool = false  # Si es true, puede atravesar múltiples enemigos

# ============================================================================
# VARIABLES DE ESTADO
# ============================================================================
var direction: Vector2 = Vector2.RIGHT  # Dirección de movimiento
var time_left: float  # Tiempo restante antes de desaparecer

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	time_left = lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))
	_update_visual()  # Actualizar rotación visual según la dirección

# ============================================================================
# MOVIMIENTO Y FÍSICA
# ============================================================================
func _physics_process(delta: float) -> void:
	# Mover el proyectil en la dirección configurada
	position += direction * speed * delta
	
	# Reducir tiempo de vida
	time_left -= delta
	if time_left <= 0.0:
		queue_free()  # Desaparecer cuando se acaba el tiempo

# ============================================================================
# DETECCIÓN DE COLISIONES
# ============================================================================
func _on_body_entered(body: Node) -> void:
	# Ignorar colisiones con el jugador (no debe dañarse a sí mismo)
	if body is Player:
		return

	# Verificar si el cuerpo es un enemigo (tiene HealthComponent)
	if body is CharacterBody2D:
		# Buscar el HealthComponent de forma segura
		var hc = null
		
		# Método 1: Buscar nodo hijo Components/HealthComponent
		if body.has_node("Components/HealthComponent"):
			hc = body.get_node("Components/HealthComponent")
		else:
			# Método 2: Intentar leer propiedad health_component directamente
			var maybe = body.get("health_component")
			if maybe != null:
				hc = maybe

		# Si encontramos HealthComponent, es un enemigo -> aplicar daño
		if hc != null:
			# Aplicar daño al enemigo
			hc.receive_damage(damage)

			# Calcular dirección de knockback (alejarse del proyectil)
			var kb_dir = (body.global_position - global_position).normalized()

			# Aplicar knockback: preferir método explícito si existe
			if body.has_method("apply_knockback"):
				body.apply_knockback(kb_dir * knockback_strength)
			else:
				# Fallback: modificar velocidad directamente si tiene esa propiedad
				var vel = body.get("velocity")
				if typeof(vel) == TYPE_VECTOR2:
					# Obtener masa si existe (para knockback más realista)
					var mass = 1.0
					var m = body.get("mass")
					if m != null:
						mass = float(m)
					body.set("velocity", vel + kb_dir * (knockback_strength / max(mass, 1.0)))

			# Si el enemigo muere, registrar estadística y emitir señal
			if hc.current_health <= 0:
				# Registrar estadística según el tipo de enemigo
				if GameStats:
					if body is Boss:
						GameStats.add_boss_kill()
					elif body is Enemy:
						GameStats.add_slime_kill()
					elif body is Orc:
						GameStats.add_orc_kill()
				
				# Emitir señal correspondiente para notificar al mundo
				if body is Boss:
					body.boss_killed.emit()
				elif body is Enemy or body is Orc:
					body.enemy_killed.emit()

			# Destruir el proyectil si no atraviesa (pierce = false)
			if not pierce:
				queue_free()
			return
	
	# Si llegamos aquí, NO es un enemigo (pared, obstáculo, TileMap, etc.)
	# Destruir el proyectil inmediatamente al colisionar
	queue_free()

# ============================================================================
# CONFIGURACIÓN DE DIRECCIÓN
# ============================================================================
# Establece la dirección del proyectil y actualiza la rotación visual
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	_update_visual()

# ============================================================================
# ACTUALIZACIÓN VISUAL
# ============================================================================
# Actualiza la rotación del sprite según la dirección
# El sprite mira a la izquierda por defecto, por eso se suma PI para compensar
func _update_visual() -> void:
	rotation = direction.angle() + PI
