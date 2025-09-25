extends Node2D

const SLIME = preload("uid://c61anvsnkj4dk")
const BOSS = preload("uid://cak370ffpdgv6")


@onready var personaje_omar: Player = $personaje_Omar
@onready var timer_spawn_slime: Timer = $TimerSpawnSlime

var timerSlime := 3.0
var slime_kills := 0

func _ready() -> void:
	timer_spawn_slime.timeout.connect(spawn_slime)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

func spawn_slime():
	var slime = SLIME.instantiate()
	var random_angle : float = randf() * PI * 2
	var spawn_distance : float = randf_range(270, 300)
	var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	slime.position = spawn_offset + personaje_omar.position
	add_child(slime)

# Se llama desde Enemy.verify_receive_damage() cuando muere por ataque del jugador
func _on_slime_killed_by_player():
	slime_kills += 1
	if slime_kills >= 4:
		spawn_boss()

func spawn_boss():
	var boss = BOSS.instantiate()
	boss.position = personaje_omar.position + Vector2(0, -200)
	add_child(boss)
	
