class_name HealthComponent extends Node2D

signal death()

@export var progress_bar : ProgressBar
@export var current_health := 100
@export var max_health := 100


func _ready() -> void:
	update_healt_bar()

func update_healt_bar():
	if progress_bar:
		progress_bar.value = current_health

func receive_damage(amount : int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_healt_bar()
	if current_health <=0:
		on_death()

func apply_health(amount : int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_healt_bar()
	
func on_death():
	death.emit()
