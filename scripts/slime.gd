class_name Enemy extends CharacterBody2D

signal enemy_killed

var move_speed := 30
var attack_damage := 10
var is_attack := false
var in_attack_range := false

# Configuración de vida
@export var max_health_value: int = 40


var personaje_omar: CharacterBody2D = null
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent



func _ready() -> void:
	# Configurar vida máxima del slime
	health_component.max_health = max_health_value
	health_component.current_health = max_health_value
	health_component.update_health_bar()
	health_component.death.connect(on_death)
	# Buscar el jugador de forma más robusta
	_find_player()
	if personaje_omar:
		personaje_omar.attack_finished.connect(verify_receive_damage)

# Función para aplicar multiplicadores de dificultad
func apply_difficulty(speed_multiplier: float, health_multiplier: float) -> void:
	move_speed = int(move_speed * speed_multiplier)
	max_health_value = int(max_health_value * health_multiplier)
	# Actualizar vida actual también
	if health_component:
		health_component.max_health = max_health_value
		health_component.current_health = max_health_value
		health_component.update_health_bar()

func _find_player() -> void:
	# Intentar encontrar el jugador en el árbol
	var parent = get_parent()
	if parent:
		personaje_omar = parent.get_node_or_null("personaje_Omar")
		if not personaje_omar:
			# Buscar en toda la escena
			var scene_root = get_tree().current_scene
			if scene_root:
				personaje_omar = scene_root.get_node_or_null("personaje_Omar")

func _physics_process(delta: float) -> void:
	if !is_attack and personaje_omar:
		sprite_animation.play("idle")

		var move_directions = (personaje_omar.position - position).normalized()
		if move_directions:
			# Obtener dirección ajustada con evasión de obstáculos
			var adjusted_direction = _get_avoidance_direction(move_directions)
			velocity = adjusted_direction * move_speed
			if adjusted_direction.x != 0:
				sprite_animation.flip_h = adjusted_direction.x < 0

		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() is Player:
			# daña al jugador
			var player = collision.get_collider()
			if player and player.has_node("Components/HealthComponent"):
				player.get_node("Components/HealthComponent").receive_damage(attack_damage)
			# muere el slime
			on_death()

# Función para obtener dirección que evite obstáculos
func _get_avoidance_direction(target_direction: Vector2) -> Vector2:
	var ray_distance = 40.0
	var space_state = get_world_2d().direct_space_state
	
	# Raycast hacia el objetivo para detectar obstáculos
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + target_direction * ray_distance)
	query.collision_mask = 1  # Layer 1 es el TileMap
	query.exclude = [self]  # Excluir el propio enemigo
	
	var result = space_state.intersect_ray(query)
	
	# Si no hay obstáculo, seguir dirección original
	if not result:
		return target_direction
	
	var collider = result.get("collider")
	# Si el obstáculo no es estático, ignorarlo (puede ser otro enemigo)
	if collider:
		if not (collider is TileMapLayer or collider is StaticBody2D):
			# Verificar si es un objeto estático con CollisionShape2D
			if not (collider.has_node("CollisionShape2D") and not (collider is CharacterBody2D)):
				return target_direction
	
	# Hay un obstáculo, intentar direcciones alternativas
	var alternative_directions = [
		Vector2(-target_direction.y, target_direction.x),  # 90 grados izquierda
		Vector2(target_direction.y, -target_direction.x),  # 90 grados derecha
		Vector2(-target_direction.x, -target_direction.y), # 180 grados (reverso)
		Vector2(target_direction.y, target_direction.x),   # Diagonal izquierda
		Vector2(-target_direction.y, -target_direction.x)  # Diagonal derecha
	]
	
	# Probar direcciones alternativas
	for alt_dir in alternative_directions:
		query = PhysicsRayQueryParameters2D.create(global_position, global_position + alt_dir.normalized() * ray_distance)
		query.collision_mask = 1
		query.exclude = [self]
		result = space_state.intersect_ray(query)
		
		if not result:
			# Encontramos una dirección libre, combinar con dirección original (70% hacia jugador, 30% evasión)
			return (target_direction * 0.7 + alt_dir.normalized() * 0.3).normalized()
		else:
			# Verificar si el obstáculo es realmente un bloqueo
			collider = result.get("collider")
			if collider:
				if not (collider is TileMapLayer or collider is StaticBody2D):
					if not (collider.has_node("CollisionShape2D") and not (collider is CharacterBody2D)):
						# No es un bloqueo real, usar esta dirección
						return (target_direction * 0.7 + alt_dir.normalized() * 0.3).normalized()
	
	# No encontramos dirección libre, intentar perpendicular al obstáculo
	var normal = result.get("normal", Vector2.ZERO)
	if normal != Vector2.ZERO:
		var avoid_direction = Vector2(-normal.y, normal.x)  # Perpendicular al normal
		return (target_direction * 0.5 + avoid_direction * 0.5).normalized()
	
	# Si todo falla, seguir dirección original (el enemigo se quedará atorado pero al menos intentará)
	return target_direction
		
func verify_receive_damage():
	if in_attack_range and personaje_omar:
		health_component.receive_damage(personaje_omar.attack_damage)
		# Solo si muere por ataque del jugador, emitimos señal
		if health_component.current_health <= 0:
			# Registrar estadística antes de emitir señal
			if GameStats:
				GameStats.add_slime_kill()
			enemy_killed.emit()

func on_death():
	queue_free()
