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

	# Notificar al spawner si murió (manteniendo tu flujo actual)
	if hc.current_health <= 0:
		var p = body.get_parent()
		if p:
			if p.has_method("_on_slime_killed_by_player"):
				p._on_slime_killed_by_player()
			elif p.has_method("_on_boss_killed_by_player"):
				p._on_boss_killed_by_player()

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
