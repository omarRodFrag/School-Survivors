class_name Player extends CharacterBody2D

var move_speed := 150
var attack_damage := 50
var is_attack := false
var is_dead := false

signal attack_finished

# Configuración de vida
@export var max_health_value: int = 100

# Configuración de cooldown de ataque
@export var attack_cooldown: float = 0.3
var can_attack: bool = true

@onready var cam = $Camera2D
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent
var attack_cooldown_timer: Timer = null

# ---------- NUEVO: preload de la ráfaga ----------
@export var WindProjectileScene: PackedScene = preload("uid://ca51t7je6qlgt")
@export var projectile_offset := 20.0
@export var projectile_speed := 300.0
@export var projectile_damage := 50
# -------------------------------------------------

func _ready() -> void:
	# Configurar vida máxima del jugador
	health_component.max_health = max_health_value
	health_component.current_health = max_health_value
	health_component.update_health_bar()
	health_component.death.connect(on_death)
	
	# Configurar timer de cooldown (crear dinámicamente si no existe)
	attack_cooldown_timer = get_node_or_null("AttackCooldownTimer")
	if not attack_cooldown_timer:
		# Crear timer si no existe
		attack_cooldown_timer = Timer.new()
		attack_cooldown_timer.name = "AttackCooldownTimer"
		add_child(attack_cooldown_timer)
	
	attack_cooldown_timer.wait_time = attack_cooldown
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_finished)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				attack()

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if !is_attack:
		var move_direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		if move_direction:
			velocity = move_direction * move_speed
			sprite_animation.play("walk")
			if move_direction.x != 0:
				sprite_animation.flip_h = move_direction.x > 0
				$AreaAttack.scale.x = -1 if move_direction.x > 0 else 1
		else:
			velocity = velocity.move_toward(Vector2.ZERO,move_speed)
			sprite_animation.play("idle")
		
		move_and_slide()

func on_death():
	if is_dead:
		return
	is_dead = true
	sprite_animation.play("death")
	velocity = Vector2.ZERO
	set_physics_process(false)

func attack():
	if is_dead or not can_attack:
		return
	can_attack = false
	sprite_animation.play("attack")
	is_attack = true
	# Spawnear la ráfaga aquí (si quieres sincronizar a frame, ver nota abajo)
	spawn_wind()
	# Iniciar cooldown
	if attack_cooldown_timer:
		attack_cooldown_timer.start()

func _on_attack_cooldown_finished() -> void:
	can_attack = true

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite_animation.animation == "attack":
		is_attack = false
		attack_finished.emit()
	elif sprite_animation.animation == "death":
		_show_game_over()

func _on_area_attack_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Enemy or body is Boss or body is Orc:
		body.in_attack_range = true

func _on_area_attack_body_exited(body: Node2D) -> void:
	if body is Enemy or body is Boss or body is Orc:
		body.in_attack_range = false

# ---------- NUEVO: función para crear el proyectil ----------
func spawn_wind() -> void:
	# calcula dirección hacia el mouse (top-down): si quieres otro método, cámbialo
	var dir := (get_global_mouse_position() - global_position).normalized()
	if dir == Vector2.ZERO:
		# fallback: usa la orientación horizontal del sprite
		dir = Vector2.RIGHT if sprite_animation.flip_h == false else Vector2.LEFT

	var inst = WindProjectileScene.instantiate()
	# posicion frontal para no golpear al propio jugador
	inst.global_position = global_position + dir * projectile_offset
	inst.direction = dir
	inst.speed = projectile_speed
	inst.damage = projectile_damage
	# si quieres que atraviese: inst.pierce = true
	get_tree().current_scene.add_child(inst)
# ---------------------------------------------------------

func _show_game_over() -> void:
	# Buscar la escena de Game Over en el árbol
	var world = get_tree().current_scene
	if world:
		var game_over = world.get_node_or_null("GameOver")
		if game_over:
			var final_score = ScoreManager.score
			var final_level = ScoreManager.level
			game_over.show_game_over(final_score, final_level)
		else:
			# Fallback: solo pausar si no se encuentra la escena
			push_error("GameOver scene not found")
			get_tree().paused = true
# ---------------------------------------------------------
