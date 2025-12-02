# WindProjectile.gd (robusto — sin has_variable)
extends Area2D

@export var speed: float = 30.0
@export var damage: int = 50
@export var lifetime: float = 1.0
@export var knockback_strength: float = 160.0
@export var pierce: bool = false

var direction: Vector2 = Vector2.RIGHT
var time_left: float


func _ready() -> void:
	time_left = lifetime
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	_update_visual()

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	
	# Verificar colisión con TileMap usando raycast antes de mover
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + movement)
	query.collision_mask = 1  # Layer 1 es el TileMap
	query.exclude = [self]  # Excluir el propio proyectil
	
	var result = space_state.intersect_ray(query)
	if result:
		# Colisión detectada con TileMap u objeto estático - destruir proyectil
		queue_free()
		return
	
	position += movement
	time_left -= delta
	if time_left <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Ignorar el player
	if body is Player:
		return
	
	# Detectar colisión con paredes/objetos estáticos (TileMapLayer, StaticBody2D, etc.)
	if body is TileMapLayer or body is StaticBody2D:
		# Colisión con pared/objeto estático - destruir proyectil sin dañar
		queue_free()
		return
	
	# Verificar si tiene CollisionShape2D pero no es CharacterBody2D (puede ser un objeto estático)
	if body.has_node("CollisionShape2D") and not (body is CharacterBody2D):
		# Posible objeto estático - destruir proyectil
		queue_free()
		return

	# Nos interesan solo CharacterBody2D (tus enemigos)
	if not (body is CharacterBody2D):
		return

	# --- Buscar el HealthComponent de forma segura ---
	var hc = null
	# 1) Si el enemigo tiene un nodo hijo Components/HealthComponent
	if body.has_node("Components/HealthComponent"):
		hc = body.get_node("Components/HealthComponent")
	else:
		# 2) Intentamos leer una propiedad/script variable llamada health_component (si existe)
		# usar body.get("health_component") -> devuelve null si no existe la propiedad
		# (get acepta 1 argumento en Godot 4)
		var maybe = body.get("health_component")
		if maybe != null:
			hc = maybe

	# Si no encontramos HealthComponent -> no hacemos nada
	if hc == null:
		return

	# Aplicar daño
	hc.receive_damage(damage)

	# calcular dirección de knockback
	var kb_dir = (body.global_position - global_position).normalized()

	# aplicar knockback: preferimos método explícito en el enemigo
	if body.has_method("apply_knockback"):
		body.apply_knockback(kb_dir * knockback_strength)
	else:
		# fallback: si el cuerpo tiene una propiedad 'velocity' (y es Vector2), la modificamos
		var vel = body.get("velocity")
		if typeof(vel) == TYPE_VECTOR2:
			# obtener mass si existe
			var mass = 1.0
			var m = body.get("mass")
			if m != null:
				# intentar convertir a float si es posible
				mass = float(m)
			body.set("velocity", vel + kb_dir * (knockback_strength / max(mass, 1.0)))

	# Emitir señal del enemigo si murió por el proyectil
	if hc.current_health <= 0:
		if body is Boss:
			body.boss_killed.emit()
		elif body is Enemy or body is Orc:
			body.enemy_killed.emit()

	# destruir si no atraviesa
	if not pierce:
		queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	_update_visual()
	
# --- NUEVO: rotación correcta ---
func _update_visual() -> void:
	# Tu sprite mira a la izquierda, así que la rotación base debe compensarse sumando PI
	rotation = direction.angle() + PI

# Detectar colisiones con áreas (TileMapLayer puede generar esta señal)
func _on_area_entered(area: Area2D) -> void:
	# Detectar si colisionamos con el área del TileMap o un área estática
	# Si es un TileMapLayer o un área con física estática, destruir proyectil
	if area.get_parent() is TileMapLayer:
		queue_free()
		return
	
	# Si el área tiene CollisionShape2D pero no es del jugador ni un enemigo, asumir que es estático
	if area.has_node("CollisionShape2D"):
		# Verificar que no sea un área del jugador o enemigo
		var parent = area.get_parent()
		if not (parent is Player or parent is CharacterBody2D):
			queue_free()
			return
