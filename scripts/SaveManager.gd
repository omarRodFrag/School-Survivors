# Gestor de guardado y récords
# Autoload singleton que gestiona el guardado y carga de datos persistentes
# Almacena récords como la puntuación más alta y nivel alcanzado
extends Node

# ============================================================================
# CONSTANTES
# ============================================================================
const SAVE_FILE_PATH = "user://save_data.json"  # Ruta del archivo de guardado

# ============================================================================
# VARIABLES DE ESTADO
# ============================================================================
var high_score: int = 0  # Puntuación más alta alcanzada
var highest_level: int = 1  # Nivel más alto alcanzado

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	load_data()  # Cargar datos guardados al iniciar

# ============================================================================
# SISTEMA DE GUARDADO
# ============================================================================
# Guarda los datos en un archivo JSON
func save_data() -> void:
	var save_dict = {
		"high_score": high_score,
		"highest_level": highest_level
	}
	
	# Abrir archivo para escritura
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)
		file.close()
	else:
		push_error("[SaveManager] Error al guardar datos")

# ============================================================================
# SISTEMA DE CARGA
# ============================================================================
# Carga los datos desde el archivo JSON
func load_data() -> void:
	# Verificar si el archivo existe
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return  # Si no existe, usar valores por defecto
	
	# Abrir archivo para lectura
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		# Parsear JSON
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_dict = json.data
			high_score = save_dict.get("high_score", 0)
			highest_level = save_dict.get("highest_level", 1)
		else:
			push_error("[SaveManager] Error al parsear JSON: " + json.get_error_message())
	else:
		push_error("[SaveManager] Error al abrir archivo de guardado")

# ============================================================================
# GESTIÓN DE RÉCORDS
# ============================================================================
# Verifica si hay un nuevo récord y lo guarda
# Retorna true si es un nuevo récord, false en caso contrario
func check_and_save_score(score: int, level: int) -> bool:
	var is_new_record = false
	
	# Verificar si la puntuación es mayor al récord anterior
	if score > high_score:
		high_score = score
		is_new_record = true
	
	# Actualizar nivel más alto alcanzado
	if level > highest_level:
		highest_level = level
	
	# Guardar solo si hay un nuevo récord
	if is_new_record:
		save_data()
	
	return is_new_record

# ============================================================================
# GETTERS
# ============================================================================
# Obtiene la puntuación más alta guardada
func get_high_score() -> int:
	return high_score

# Obtiene el nivel más alto alcanzado
func get_highest_level() -> int:
	return highest_level
