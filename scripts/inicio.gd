extends Node2D

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/world.tscn")
	pass # Replace with function body.


func _on_texture_button_2_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
