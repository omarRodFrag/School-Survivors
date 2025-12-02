class_name HealthComponent extends Node2D

signal death()
signal health_changed(current_health: int, max_health: int)

@export var progress_bar : ProgressBar
@export var current_health := 100
@export var max_health := 100


func _ready() -> void:
	update_health_bar()

func update_health_bar():
	if progress_bar:
		# Configurar el max_value del ProgressBar si no está configurado
		if progress_bar.max_value == 100.0 and max_health != 100:
			progress_bar.max_value = max_health
		progress_bar.value = current_health
	# Emitir señal de cambio de vida
	health_changed.emit(current_health, max_health)

func receive_damage(amount : int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_health_bar()
	if current_health <=0:
		on_death()

func apply_health(amount : int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_health_bar()
	
func on_death():
	death.emit()
