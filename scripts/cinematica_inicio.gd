# Script para la cinemática de inicio
# Reproduce un video y cambia a la escena del juego cuando termina
extends Node

# ============================================================================
# REFERENCIAS
# ============================================================================
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Conectar señal para detectar cuando el video termina
	if video_player:
		video_player.finished.connect(_on_video_finished)
		# Iniciar reproducción del video automáticamente
		video_player.play()
	else:
		# Si no hay VideoStreamPlayer, ir directo al juego (fallback)
		push_error("[CinematicaInicio] VideoStreamPlayer no encontrado")
		_on_video_finished()

# ============================================================================
# CUANDO TERMINA EL VIDEO
# ============================================================================
func _on_video_finished() -> void:
	# Cambiar a la escena del juego cuando termine el video
	get_tree().change_scene_to_file("res://escenas/world.tscn")

# ============================================================================
# OPCIONAL: PERMITIR SALTAR LA CINEMÁTICA
# ============================================================================
func _input(event: InputEvent) -> void:
	# Permitir saltar la cinemática con cualquier tecla o clic
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_on_video_finished()  # Saltar directamente al juego

