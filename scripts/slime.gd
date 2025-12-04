# Script del enemigo básico (Slime)
# Implementa búsqueda del jugador, evasión de obstáculos y sistema de combate básico
class_name Enemy extends CharacterBody2D

# ============================================================================
# SEÑALES
# ============================================================================
signal enemy_killed  # Se emite cuando el enemigo es eliminado por el jugador

# ============================================================================
# ESTADÍSTICAS Y ESTADO
# ============================================================================
var move_speed := 30  # Velocidad de movimiento del enemigo
var attack_damage := 10  # Daño que causa al jugador al colisionar
var is_attack := false  # Indica si el enemigo está atacando
var in_attack_range := false  # Indica si está en rango del ataque del jugador

# ============================================================================
# CONFIGURACIÓN DE VIDA
# ============================================================================
@export var max_health_value: int = 40  # Vida máxima (configurable en editor)

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
var personaje_omar: CharacterBody2D = null  # Referencia al jugador
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent



# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar sistema de vida del enemigo
	health_component.max_health = max_health_value
	health_component.current_health = max_health_value
	health_component.update_health_bar()
	health_component.death.connect(on_death)  # Conectar señal de muerte
	
	# Buscar el jugador en la escena
	_find_player()
	
	# Conectar señal para recibir daño cuando el jugador termina su ataque
	if personaje_omar:
		personaje_omar.attack_finished.connect(verify_receive_damage)

# ============================================================================
# SISTEMA DE DIFICULTAD
# ============================================================================
# Aplica multiplicadores de dificultad para aumentar velocidad y vida según el nivel
func apply_difficulty(speed_multiplier: float, health_multiplier: float) -> void:
	move_speed = int(move_speed * speed_multiplier)
	max_health_value = int(max_health_value * health_multiplier)
	
	# Actualizar vida actual para reflejar los cambios
	if health_component:
		health_component.max_health = max_health_value
		health_component.current_health = max_health_value
		health_component.update_health_bar()

# ============================================================================
# BÚSQUEDA DEL JUGADOR
# ============================================================================
# Busca el jugador en el árbol de escenas de forma robusta
func _find_player() -> void:
	# Intentar encontrar el jugador primero en el padre
	var parent = get_parent()
	if parent:
		personaje_omar = parent.get_node_or_null("personaje_Omar")
		if not personaje_omar:
			# Si no está en el padre, buscar en toda la escena
			var scene_root = get_tree().current_scene
			if scene_root:
				personaje_omar = scene_root.get_node_or_null("personaje_Omar")

# ============================================================================
# MOVIMIENTO Y FÍSICA
# ============================================================================
func _physics_process(delta: float) -> void:
	# Solo moverse si no está atacando y el jugador existe
	if !is_attack and personaje_omar:
		sprite_animation.play("idle")

		# Calcular dirección hacia el jugador
		var move_directions = (personaje_omar.position - position).normalized()
		if move_directions:
			# Obtener dirección ajustada que evite obstáculos
			var adjusted_direction = _get_avoidance_direction(move_directions)
			velocity = adjusted_direction * move_speed
			
			# Voltear sprite según la dirección horizontal
			if adjusted_direction.x != 0:
				sprite_animation.flip_h = adjusted_direction.x < 0

		# Aplicar movimiento y detectar colisiones
		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() is Player:
			# Si colisiona con el jugador, causar daño
			var player = collision.get_collider()
			if player and player.has_node("Components/HealthComponent"):
				player.get_node("Components/HealthComponent").receive_damage(attack_damage)
			# El enemigo muere después de atacar (ataque suicida)
			on_death()

# ============================================================================
# SISTEMA DE EVASIÓN DE OBSTÁCULOS
# ============================================================================
# Calcula una dirección que evite obstáculos mientras intenta acercarse al jugador
# Usa raycasts para detectar paredes y busca rutas alternativas
func _get_avoidance_direction(target_direction: Vector2) -> Vector2:
	var ray_distance = 40.0  # Distancia del raycast para detectar obstáculos
	var space_state = get_world_2d().direct_space_state
	
	# Hacer raycast hacia la dirección objetivo para detectar obstáculos
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + target_direction * ray_distance)
	query.collision_mask = 1  # Layer 1 es el TileMap (paredes)
	query.exclude = [self]  # Excluir el propio enemigo del raycast
	
	var result = space_state.intersect_ray(query)
	
	# Si no hay obstáculo, seguir la dirección original hacia el jugador
	if not result:
		return target_direction
	
	# Verificar si el obstáculo detectado es realmente un bloqueo
	var collider = result.get("collider")
	# Si el obstáculo no es estático (como otro enemigo), ignorarlo
	if collider:
		if not (collider is TileMapLayer or collider is StaticBody2D):
			# Verificar si es un objeto estático con CollisionShape2D
			if not (collider.has_node("CollisionShape2D") and not (collider is CharacterBody2D)):
				return target_direction  # No es un bloqueo real, seguir adelante
	
	# Hay un obstáculo real, intentar direcciones alternativas
	# Estas direcciones son variaciones de la dirección original (90°, 180°, diagonales)
	var alternative_directions = [
		Vector2(-target_direction.y, target_direction.x),  # 90 grados izquierda
		Vector2(target_direction.y, -target_direction.x),  # 90 grados derecha
		Vector2(-target_direction.x, -target_direction.y), # 180 grados (reverso)
		Vector2(target_direction.y, target_direction.x),   # Diagonal izquierda
		Vector2(-target_direction.y, -target_direction.x)  # Diagonal derecha
	]
	
	# Probar cada dirección alternativa para encontrar una ruta libre
	for alt_dir in alternative_directions:
		query = PhysicsRayQueryParameters2D.create(global_position, global_position + alt_dir.normalized() * ray_distance)
		query.collision_mask = 1
		query.exclude = [self]
		result = space_state.intersect_ray(query)
		
		if not result:
			# Encontramos una dirección libre, combinar con dirección original
			# 70% hacia el jugador, 30% evasión para mantener el objetivo
			return (target_direction * 0.7 + alt_dir.normalized() * 0.3).normalized()
		else:
			# Verificar si este obstáculo alternativo es realmente un bloqueo
			collider = result.get("collider")
			if collider:
				if not (collider is TileMapLayer or collider is StaticBody2D):
					if not (collider.has_node("CollisionShape2D") and not (collider is CharacterBody2D)):
						# No es un bloqueo real, usar esta dirección
						return (target_direction * 0.7 + alt_dir.normalized() * 0.3).normalized()
	
	# Si no encontramos dirección libre, intentar moverse perpendicular al obstáculo
	var normal = result.get("normal", Vector2.ZERO)
	if normal != Vector2.ZERO:
		var avoid_direction = Vector2(-normal.y, normal.x)  # Perpendicular al normal
		# Combinar 50% hacia jugador, 50% evasión
		return (target_direction * 0.5 + avoid_direction * 0.5).normalized()
	
	# Si todo falla, seguir dirección original (el enemigo se quedará atorado pero al menos intentará)
	return target_direction
		
# ============================================================================
# SISTEMA DE DAÑO Y MUERTE
# ============================================================================
# Verifica si el enemigo debe recibir daño del ataque del jugador
func verify_receive_damage():
	# Solo recibir daño si está en rango del ataque del jugador
	if in_attack_range and personaje_omar:
		health_component.receive_damage(personaje_omar.attack_damage)
		
		# Solo si muere por este ataque, emitir señal y registrar estadística
		if health_component.current_health <= 0:
			# Registrar estadística de enemigo eliminado
			if GameStats:
				GameStats.add_slime_kill()
			enemy_killed.emit()  # Notificar que fue eliminado (para puntos y progreso)

# Elimina el enemigo de la escena
func on_death():
	queue_free()
