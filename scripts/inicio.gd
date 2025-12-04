# Script del menú principal de inicio
# Gestiona la navegación desde el menú principal al juego y salida
extends Node2D

# ============================================================================
# NAVEGACIÓN DEL MENÚ
# ============================================================================
# Botón "Jugar": Inicia el juego cambiando a la escena del mundo
func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/world.tscn")

# Botón "Salir": Cierra la aplicación
func _on_texture_button_2_pressed() -> void:
	get_tree().quit()
