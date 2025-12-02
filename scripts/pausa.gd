extends CanvasLayer
@onready var salir_boton: TextureButton = $Salir_Boton

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pausa"):
		get_tree().paused = not get_tree().paused
		$ColorRect.visible = not $ColorRect.visible
		$TextureRect.visible = not $TextureRect.visible
		$Salir_Boton.visible = not $Salir_Boton.visible

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


func _on_salir_boton_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
