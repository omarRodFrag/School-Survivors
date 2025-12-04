# Script del jugador principal
# Gestiona movimiento, ataque, proyectiles, vida y compatibilidad móvil/PC
class_name Player extends CharacterBody2D

# ============================================================================
# ESTADÍSTICAS BÁSICAS
# ============================================================================
var move_speed := 150  # Velocidad de movimiento del jugador
var attack_damage := 50  # Daño base del ataque cuerpo a cuerpo
var is_attack := false  # Indica si el jugador está ejecutando un ataque
var is_dead := false  # Indica si el jugador está muerto

# ============================================================================
# SEÑALES
# ============================================================================
signal attack_finished  # Se emite cuando termina la animación de ataque

# ============================================================================
# CONFIGURACIÓN DE VIDA
# ============================================================================
@export var max_health_value: int = 100  # Vida máxima del jugador (configurable en editor)

# ============================================================================
# SISTEMA DE ATAQUE Y COOLDOWN
# ============================================================================
@export var attack_cooldown: float = 0.3  # Tiempo entre ataques (configurable en editor)
var can_attack: bool = true  # Indica si el jugador puede atacar (no está en cooldown)

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
@onready var cam = $Camera2D
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent
var attack_cooldown_timer: Timer = null  # Timer para el cooldown de ataque

# ============================================================================
# CONTROLES TÁCTILES PARA MÓVIL
# ============================================================================
var is_mobile := false  # Indica si el juego está corriendo en dispositivo móvil
var joystick_direction := Vector2.ZERO  # Dirección actual del joystick virtual
var virtual_joystick: Node = null  # Referencia al joystick virtual
var touch_attack_button: Node = null  # Referencia al botón de ataque táctil

# ============================================================================
# CONFIGURACIÓN DE PROYECTILES (WindProjectile)
# ============================================================================
@export var WindProjectileScene: PackedScene = preload("uid://ca51t7je6qlgt")
@export var projectile_offset := 20.0  # Distancia desde el jugador donde aparece el proyectil
@export var projectile_speed := 300.0  # Velocidad del proyectil
@export var projectile_damage := 50  # Daño del proyectil

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Configurar sistema de vida del jugador
	health_component.max_health = max_health_value
	health_component.current_health = max_health_value
	health_component.update_health_bar()
	health_component.death.connect(on_death)  # Conectar señal de muerte
	
	# Configurar timer de cooldown de ataque
	# Buscar si ya existe un timer, o crear uno nuevo dinámicamente
	attack_cooldown_timer = get_node_or_null("AttackCooldownTimer")
	if not attack_cooldown_timer:
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.name = "AttackCooldownTimer"
		add_child(attack_cooldown_timer)
	
	# Configurar propiedades del timer
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true  # El timer se ejecuta una sola vez
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_finished)
	
	# Detectar si el juego está corriendo en dispositivo móvil
	is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	
	# Configurar controles táctiles si es necesario
	if is_mobile:
		# Esperar un frame para que el HUD esté completamente inicializado
		call_deferred("_setup_mobile_controls")

# ============================================================================
# CONFIGURACIÓN DE CONTROLES MÓVILES
# ============================================================================
func _setup_mobile_controls() -> void:
	# Buscar controles táctiles en el HUD de la escena
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		virtual_joystick = hud.get_node_or_null("VirtualJoystick")
		touch_attack_button = hud.get_node_or_null("TouchAttackButton")
		
		# Conectar señales del joystick virtual y botón de ataque
		if virtual_joystick and virtual_joystick.has_signal("joystick_input"):
			virtual_joystick.joystick_input.connect(_on_joystick_input)
		if touch_attack_button and touch_attack_button.has_signal("attack_requested"):
			touch_attack_button.attack_requested.connect(_on_touch_attack)

# Recibe la dirección del joystick virtual y la almacena para usar en el movimiento
func _on_joystick_input(value: Vector2) -> void:
	joystick_direction = value

# Maneja el ataque táctil: ataca hacia la dirección especificada
func _on_touch_attack(direction: Vector2) -> void:
	if can_attack and not is_dead:
		attack_towards_direction(direction)

# ============================================================================
# ENTRADA DE USUARIO
# ============================================================================
func _input(event: InputEvent) -> void:
	# Ignorar input si el jugador está muerto
	if is_dead:
		return
	
	# En móvil, el ataque se maneja con el botón táctil (no usar mouse)
	if is_mobile:
		return
	
	# En PC, usar clic izquierdo del mouse para atacar
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				attack()

# ============================================================================
# MOVIMIENTO Y FÍSICA
# ============================================================================
func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	# Solo permitir movimiento si no está atacando
	if !is_attack:
		var move_direction := Vector2.ZERO
		
		# Obtener dirección de movimiento según la plataforma
		# Móvil: usar joystick virtual | PC: usar teclado (WASD/flechas)
		if is_mobile and virtual_joystick:
			move_direction = joystick_direction
		else:
			move_direction = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		
		# Aplicar movimiento si hay dirección
		if move_direction:
			velocity = move_direction * move_speed
			sprite_animation.play("walk")
			# Voltear sprite según la dirección horizontal
			if move_direction.x != 0:
				sprite_animation.flip_h = move_direction.x > 0
				# Voltear también el área de ataque para mantener consistencia
				$AreaAttack.scale.x = -1 if move_direction.x > 0 else 1
		else:
			# Si no hay movimiento, desacelerar suavemente y reproducir animación idle
			velocity = velocity.move_toward(Vector2.ZERO, move_speed)
			sprite_animation.play("idle")
		
		move_and_slide()  # Aplicar movimiento usando CharacterBody2D

# ============================================================================
# GESTIÓN DE MUERTE
# ============================================================================
func on_death():
	# Evitar ejecutar múltiples veces
	if is_dead:
		return
	is_dead = true
	sprite_animation.play("death")
	velocity = Vector2.ZERO  # Detener movimiento
	set_physics_process(false)  # Desactivar física para evitar movimiento después de morir

# ============================================================================
# SISTEMA DE ATAQUE
# ============================================================================
# Ataque básico: dispara proyectil hacia la dirección del mouse (PC) o joystick (móvil)
func attack():
	if is_dead or not can_attack:
		return
	can_attack = false
	sprite_animation.play("attack")
	is_attack = true
	# Disparar proyectil de viento
	spawn_wind()
	# Iniciar cooldown para limitar la frecuencia de ataques
	if attack_cooldown_timer:
		attack_cooldown_timer.start()

# Ataque hacia una dirección específica (usado principalmente en móvil)
func attack_towards_direction(direction: Vector2) -> void:
	if is_dead or not can_attack:
		return
	can_attack = false
	sprite_animation.play("attack")
	is_attack = true
	
	# Crear y configurar el proyectil
	var inst = WindProjectileScene.instantiate()
	inst.global_position = global_position + direction * projectile_offset
	inst.direction = direction
	inst.speed = projectile_speed
	inst.damage = projectile_damage
	get_tree().current_scene.add_child(inst)
	
	# Orientar el sprite del jugador hacia la dirección del ataque
	if direction.x != 0:
		sprite_animation.flip_h = direction.x > 0
		$AreaAttack.scale.x = -1 if direction.x > 0 else 1
	
	# Iniciar cooldown
	if attack_cooldown_timer:
		attack_cooldown_timer.start()

# Permite atacar nuevamente cuando termina el cooldown
func _on_attack_cooldown_finished() -> void:
	can_attack = true

# ============================================================================
# CALLBACKS DE ANIMACIÓN Y ÁREAS
# ============================================================================
# Se llama cuando termina una animación del sprite
func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite_animation.animation == "attack":
		# Permitir movimiento nuevamente después del ataque
		is_attack = false
		attack_finished.emit()  # Notificar a enemigos que el ataque terminó
	elif sprite_animation.animation == "death":
		# Mostrar pantalla de game over cuando termina la animación de muerte
		_show_game_over()

# Detectar cuando un enemigo entra al área de ataque cuerpo a cuerpo
func _on_area_attack_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	# Marcar que el enemigo está en rango para recibir daño del ataque cuerpo a cuerpo
	if body is Enemy or body is Boss or body is Orc:
		body.in_attack_range = true

# Detectar cuando un enemigo sale del área de ataque
func _on_area_attack_body_exited(body: Node2D) -> void:
	if body is Enemy or body is Boss or body is Orc:
		body.in_attack_range = false

# ============================================================================
# SISTEMA DE PROYECTILES
# ============================================================================
# Crea y dispara un proyectil de viento (WindProjectile)
func spawn_wind() -> void:
	var dir := Vector2.ZERO
	
	# Determinar dirección del proyectil según la plataforma
	if is_mobile:
		# En móvil: usar dirección del joystick o dirección por defecto
		if joystick_direction != Vector2.ZERO:
			dir = joystick_direction
		else:
			# Si no hay input del joystick, usar la orientación actual del sprite
			dir = Vector2.RIGHT if sprite_animation.flip_h == false else Vector2.LEFT
	else:
		# En PC: apuntar hacia la posición del mouse
		dir = (get_global_mouse_position() - global_position).normalized()
		if dir == Vector2.ZERO:
			# Fallback: usar orientación horizontal del sprite si el mouse está muy cerca
			dir = Vector2.RIGHT if sprite_animation.flip_h == false else Vector2.LEFT

	# Crear instancia del proyectil y configurarlo
	var inst = WindProjectileScene.instantiate()
	# Posicionar el proyectil frente al jugador para evitar golpearlo
	inst.global_position = global_position + dir * projectile_offset
	inst.direction = dir
	inst.speed = projectile_speed
	inst.damage = projectile_damage
	# Nota: para proyectiles que atraviesen enemigos, usar: inst.pierce = true
	get_tree().current_scene.add_child(inst)

# ============================================================================
# GESTIÓN DE GAME OVER
# ============================================================================
func _show_game_over() -> void:
	# Buscar la escena de Game Over en el árbol de escenas
	var world = get_tree().current_scene
	if world:
		var game_over = world.get_node_or_null("GameOver")
		if game_over:
			# Mostrar pantalla de game over con puntuación y nivel final
			var final_score = ScoreManager.score
			var final_level = ScoreManager.level
			game_over.show_game_over(final_score, final_level)
		else:
			# Fallback: pausar el juego si no se encuentra la escena de game over
			push_error("GameOver scene not found")
			get_tree().paused = true
