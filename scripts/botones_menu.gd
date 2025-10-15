extends Node

@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var pressed_scale: Vector2 = Vector2(0.95, 0.95)

func _ready():
	for btn in get_children():
		if btn is TextureButton:
			btn.connect("mouse_entered", Callable(self, "_on_mouse_entered").bind(btn))
			btn.connect("mouse_exited", Callable(self, "_on_mouse_exited_or_released").bind(btn))
			btn.connect("pressed", Callable(self, "_on_pressed").bind(btn))
			btn.set_meta("original_scale", btn.scale)

func _on_mouse_entered(btn):
	btn.scale = hover_scale

func _on_mouse_exited_or_released(btn):
	# Simula hover o released
	btn.scale = btn.get_meta("original_scale")

func _on_pressed(btn):
	btn.scale = pressed_scale
