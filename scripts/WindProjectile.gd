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
	_update_visual()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Ignorar el player
	if body is Player:
		return

	# Si es un CharacterBody2D, verificar si es un enemigo
	if body is CharacterBody2D:
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

		# Si encontramos HealthComponent, es un enemigo -> procesar daño
		if hc != null:
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
				# Registrar estadísticas antes de emitir señal
				if GameStats:
					if body is Boss:
						GameStats.add_boss_kill()
					elif body is Enemy:
						GameStats.add_slime_kill()
					elif body is Orc:
						GameStats.add_orc_kill()
				
				if body is Boss:
					body.boss_killed.emit()
				elif body is Enemy or body is Orc:
					body.enemy_killed.emit()

			# destruir si no atraviesa
			if not pierce:
				queue_free()
			return
	
	# Si llegamos aquí, NO es un enemigo (pared, obstáculo, TileMap, etc.)
	# Destruir el proyectil inmediatamente
	queue_free()

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	_update_visual()
	
# --- NUEVO: rotación correcta ---
func _update_visual() -> void:
	# Tu sprite mira a la izquierda, así que la rotación base debe compensarse sumando PI
	rotation = direction.angle() + PI
