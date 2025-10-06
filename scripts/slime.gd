class_name Enemy extends CharacterBody2D

var move_speed := 30
var attack_damage := 10
var is_attack := false
var in_attack_range := false


@onready var personaje_omar: CharacterBody2D = $"../personaje_Omar"
@onready var sprite_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $Components/HealthComponent



func _ready() -> void:
	health_component.death.connect(on_death)
	if personaje_omar:
		personaje_omar.attack_finished.connect(verify_receive_damage)

func _physics_process(delta: float) -> void:
	if !is_attack and personaje_omar:
		sprite_animation.play("idle")

		var move_directions = (personaje_omar.position - position).normalized()
		if move_directions:
			velocity = move_directions * move_speed
			if move_directions.x != 0:
				sprite_animation.flip_h = move_directions.x < 0

		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() is Player:
			# daña al jugador
			var player = collision.get_collider()
			player.health_component.receive_damage(attack_damage)
			# muere el slime
			on_death()
		
func verify_receive_damage():
	if in_attack_range:
		health_component.receive_damage(personaje_omar.attack_damage)
		# Solo si muere por ataque del jugador, avisamos al spawner
		if health_component.current_health <= 0:
			get_parent()._on_slime_killed_by_player()

func on_death():
	queue_free()
