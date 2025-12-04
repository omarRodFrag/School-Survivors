# Pantalla de Game Over
# Se muestra cuando el jugador muere, mostrando puntuación, récord y opciones de reinicio
extends CanvasLayer

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
var color_rect: ColorRect
var center_container: CenterContainer
var score_label: Label
var high_score_label: Label
var new_record_label: Label
var retry_button: Button
var menu_button: Button

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Obtener referencias de nodos de forma segura usando get_node_or_null
	color_rect = get_node_or_null("ColorRect")
	center_container = get_node_or_null("CenterContainer")
	score_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/ScoreLabel")
	high_score_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HighScoreLabel")
	new_record_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/NewRecordLabel")
	retry_button = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HBoxButtons/RetryButton")
	menu_button = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HBoxButtons/MenuButton")

# ============================================================================
# MOSTRAR PANTALLA DE GAME OVER
# ============================================================================
func show_game_over(final_score: int, final_level: int) -> void:
	# Verificar que SaveManager existe
	if not SaveManager:
		push_error("[GameOver] Error: SaveManager no encontrado")
		return
	
	# Obtener high score antes de verificar si es nuevo récord
	var high_score = SaveManager.get_high_score()
	
	# Verificar y guardar si es nuevo récord
	var is_new_record = SaveManager.check_and_save_score(final_score, final_level)
	
	# Actualizar labels con la información
	if score_label:
		score_label.text = "Puntuación: %d" % final_score
	if high_score_label:
		high_score_label.text = "Mejor Puntuación: %d" % high_score
	
	# Mostrar mensaje de nuevo récord si aplica
	if is_new_record:
		if new_record_label:
			new_record_label.visible = true
		if high_score_label:
			# Actualizar con el nuevo récord
			high_score_label.text = "Mejor Puntuación: %d" % final_score
	else:
		if new_record_label:
			new_record_label.visible = false
	
	# Mostrar la pantalla de game over
	if color_rect:
		color_rect.visible = true
	if center_container:
		center_container.visible = true
	
	# Pausar el juego para que el jugador pueda ver los resultados
	get_tree().paused = true

# ============================================================================
# NAVEGACIÓN
# ============================================================================
# Botón "Reintentar": Reinicia la escena actual
func _on_retry_button_pressed() -> void:
	# Verificar que ScoreManager existe
	if not ScoreManager:
		push_error("[GameOver] Error: ScoreManager no encontrado")
		return
	
	# Despausar el juego y reiniciar todo
	get_tree().paused = false
	ScoreManager.reset()
	get_tree().reload_current_scene()

# Botón "Menú": Vuelve al menú principal
func _on_menu_button_pressed() -> void:
	# Verificar que ScoreManager existe
	if not ScoreManager:
		push_error("[GameOver] Error: ScoreManager no encontrado")
		return
	
	# Despausar y volver al menú principal
	get_tree().paused = false
	ScoreManager.reset()
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
