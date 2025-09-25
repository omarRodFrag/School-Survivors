class_name Player extends CharacterBody2D

var move_speed := 150
var attack_damage := 50
var is_attack := false
var is_dead := false        # nuevo: marca si el jugador está muerto

signal attack_finished

@onready var cam = $Camera2D
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent

func _ready() -> void:
	health_component.death.connect(on_death)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				attack()
				
func _physics_process(delta: float) -> void:
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
	# Se llama cuando HealthComponent emite death
	if is_dead:
		return # prevenir llamadas dobles
	is_dead = true

	# reproducir animación de muerte
	sprite_animation.play("death")

	# detener movimiento físico (ya no queremos que siga moviéndose)
	velocity = Vector2.ZERO
	set_physics_process(false) # deshabilita _physics_process
	# NO pauseamos aquí — esperamos a que termine la animación

func attack():
	if is_dead:
		return
	sprite_animation.play("attack")
	is_attack = true
	
func _on_animated_sprite_2d_animation_finished() -> void:
	# Esta función se dispara cuando termina cualquier animación del AnimatedSprite2D
	# Verificamos cuál terminó y actuamos en consecuencia.
	if sprite_animation.animation == "attack":
		is_attack = false
		attack_finished.emit()
	elif sprite_animation.animation == "death":
		print("game over")
		# Aquí sí: la animación de muerte ya acabó -> pausar el juego
		get_tree().paused = true

func _on_area_attack_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Enemy:
		body.in_attack_range = true
	elif body is Boss:
		body.in_attack_range = true

func _on_area_attack_body_exited(body: Node2D) -> void:
	if body is Enemy:
		body.in_attack_range = false
	elif body is Boss:
		body.in_attack_range = false
