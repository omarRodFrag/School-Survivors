extends Node

var play_time: float = 0.0
var slimes_killed: int = 0
var orcs_killed: int = 0
var bosses_killed: int = 0
var total_damage_taken: int = 0
var levels_completed: int = 0

func _ready() -> void:
	reset_stats()

func _process(delta: float) -> void:
	play_time += delta

func reset_stats() -> void:
	play_time = 0.0
	slimes_killed = 0
	orcs_killed = 0
	bosses_killed = 0
	total_damage_taken = 0
	levels_completed = 0

func add_slime_kill() -> void:
	slimes_killed += 1

func add_orc_kill() -> void:
	orcs_killed += 1

func add_boss_kill() -> void:
	bosses_killed += 1

func add_damage_taken(amount: int) -> void:
	total_damage_taken += amount

func add_level_completed() -> void:
	levels_completed += 1

func get_play_time() -> float:
	return play_time

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func get_all_stats() -> Dictionary:
	return {
		"play_time": play_time,
		"slimes_killed": slimes_killed,
		"orcs_killed": orcs_killed,
		"bosses_killed": bosses_killed,
		"total_damage_taken": total_damage_taken,
		"levels_completed": levels_completed
	}
