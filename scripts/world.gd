extends Node2D

const SLIME = preload("uid://c61anvsnkj4dk")
@onready var personaje_omar: Player = $personaje_Omar
@onready var timer_spawn_slime: Timer = $TimerSpawnSlime
var timerSlime := 3

func _ready() -> void:
	timer_spawn_slime.timeout.connect(spawn_slime)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

func spawn_slime():
	var slime = SLIME.instantiate()
	
	var random_angle : float = randf()*PI*2
	var spawn_distance : float = randf_range(270, 300)
	var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle))*spawn_distance
	slime.position = spawn_offset + personaje_omar.position
	add_child(slime)
	
