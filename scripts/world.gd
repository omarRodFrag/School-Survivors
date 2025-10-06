# res://world.gd
extends Node2D

const SLIME = preload("uid://c61anvsnkj4dk")
const BOSS = preload("uid://cak370ffpdgv6")
const ORC = preload("uid://ucpxyend4m2x")

# Música
const MUSICA_FONDO = preload("res://assets/sonidos/musica_fondo.mp3")
const MUSICA_BOSS = preload("res://assets/sonidos/musica_boss.mp3")

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var personaje_omar: Player = $personaje_Omar
@onready var timer_spawn_slime: Timer = $TimerSpawnSlime
@onready var hud: Node = $HUD

var timerSlime := 3.0

# Estado de nivel local
var kills_local_this_level := 0
var boss_spawned_this_level := false
var spawned_boss : Node = null

func _ready() -> void:
	timer_spawn_slime.timeout.connect(spawn_enemy)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

	ScoreManager.connect("level_changed", Callable(self, "_on_level_changed"))
	ScoreManager.connect("kills_changed", Callable(self, "_on_kills_changed"))

	_update_for_level(ScoreManager.level)
	_on_level_changed(ScoreManager.level)

	# Inicia música de fondo normal
	music_player.stream = MUSICA_FONDO
	music_player.play()

func spawn_enemy() -> void:
	if not personaje_omar:
		return
	var enemy_scene = ORC if randf() < 0.3 else SLIME  # 30% chance de Orco, 70% Slime
	var enemy = enemy_scene.instantiate()
	var random_angle : float = randf() * PI * 2
	var spawn_distance : float = randf_range(270, 300)
	var spawn_offset : Vector2 = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	enemy.position = spawn_offset + personaje_omar.position
	add_child(enemy)

func _on_slime_killed_by_player() -> void:
	ScoreManager.add_points(10)
	kills_local_this_level += 1
	ScoreManager.emit_signal("kills_changed", kills_local_this_level, ScoreManager.kills_to_next_level)

	if not boss_spawned_this_level and kills_local_this_level >= ScoreManager.kills_to_next_level:
		_spawn_boss_for_level()

func _spawn_boss_for_level() -> void:
	if spawned_boss and spawned_boss.is_inside_tree():
		return
	var boss = BOSS.instantiate()
	var offset_x = randf_range(-150, 150)
	boss.position = personaje_omar.position + Vector2(offset_x, -200)
	add_child(boss)
	spawned_boss = boss
	boss_spawned_this_level = true
	if hud:
		hud.show_boss_incoming()

	# Cambia a música del boss
	music_player.stream = MUSICA_BOSS
	music_player.play()

func _on_boss_killed_by_player() -> void:
	ScoreManager.add_points(200)
	ScoreManager.complete_level()

	if hud:
		hud.show_level_completed()

	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	_clear_enemies()
	
	# Vuelve a música normal
	music_player.stream = MUSICA_FONDO
	music_player.play()

func _on_level_changed(new_level: int) -> void:
	_update_for_level(new_level)
	kills_local_this_level = 0
	boss_spawned_this_level = false
	spawned_boss = null
	_clear_enemies()

func _on_kills_changed(kills_this_level: int, kills_to_next_level: int) -> void:
	pass  # No usado directamente

func _update_for_level(level:int) -> void:
	timerSlime = max(0.5, 3.0 - (level - 1) * 0.35)
	timer_spawn_slime.wait_time = timerSlime
	timer_spawn_slime.start()

func _clear_enemies() -> void:
	for child in get_children():
		if child is Player:
			continue
		if child is Timer:
			continue
		if child.has_node("Components") and child != personaje_omar:
			child.queue_free()

# DEBUG (temporal)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_X:
			ScoreManager.add_points(50)
		elif event.keycode == Key.KEY_B:
			_spawn_boss_for_level()
