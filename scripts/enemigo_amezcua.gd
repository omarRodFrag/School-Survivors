class_name Boss extends CharacterBody2D

var move_speed := 80
var attack_damage := 75
var is_attack := false
var in_attack_range := false
var is_dead := false

@onready var personaje_omar: CharacterBody2D = $"../personaje_Omar"
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent


func _ready() -> void:
	health_component.death.connect(on_death)
	if personaje_omar:
		personaje_omar.attack_finished.connect(verify_receive_damage)
	

func _physics_process(delta: float) -> void:
	if !is_attack and personaje_omar:
		sprite_animation.play("walk")

		var move_directions = (personaje_omar.position - position).normalized()
		if move_directions:
			velocity = move_directions * move_speed
			sprite_animation.play("walk")
			if move_directions.x != 0:
				sprite_animation.flip_h = move_directions.x <  0
				$AreaAttack.scale.x = -1 if move_directions.x <  0 else 1
		else:
			velocity = velocity.move_toward(Vector2.ZERO,move_speed)
			sprite_animation.play("idle")
		move_and_slide()

func attack():
	sprite_animation.play("attack")
	is_attack = true

func _on_area_attack_body_entered(body: Node2D) -> void:
	if body is Player:
		attack()

func _on_area_attack_body_exited(body: Node2D) -> void:
	if body is Player:
		is_attack = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite_animation.animation == "attack":
		personaje_omar.health_component.receive_damage(attack_damage)
		if is_attack:
			attack() # Replace with function body.

func verify_receive_damage():
	if in_attack_range:
		health_component.receive_damage(personaje_omar.attack_damage)
		if health_component.current_health <= 0:
			# Notificamos al world que matamos al boss
			get_parent()._on_boss_killed_by_player()

func on_death():
	queue_free()
