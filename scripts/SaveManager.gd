extends Node

const SAVE_FILE_PATH = "user://save_data.json"

var high_score: int = 0
var highest_level: int = 1

func _ready() -> void:
	load_data()

func save_data() -> void:
	var save_dict = {
		"high_score": high_score,
		"highest_level": highest_level
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)
		file.close()
		print("[SaveManager] Datos guardados: ", save_dict)
	else:
		print("[SaveManager] Error al guardar datos")

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] No existe archivo de guardado, usando valores por defecto")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_dict = json.data
			high_score = save_dict.get("high_score", 0)
			highest_level = save_dict.get("highest_level", 1)
			print("[SaveManager] Datos cargados: high_score=", high_score, ", highest_level=", highest_level)
		else:
			print("[SaveManager] Error al parsear JSON: ", json.get_error_message())
	else:
		print("[SaveManager] Error al abrir archivo de guardado")

func check_and_save_score(score: int, level: int) -> bool:
	var is_new_record = false
	
	if score > high_score:
		high_score = score
		is_new_record = true
	
	if level > highest_level:
		highest_level = level
	
	if is_new_record:
		save_data()
	
	return is_new_record

func get_high_score() -> int:
	return high_score

func get_highest_level() -> int:
	return highest_level
