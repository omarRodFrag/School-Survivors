extends CanvasLayer

var color_rect: ColorRect
var center_container: CenterContainer
var score_label: Label
var high_score_label: Label
var new_record_label: Label
var retry_button: Button
var menu_button: Button

func _ready() -> void:
	# Obtener referencias de forma segura
	color_rect = get_node_or_null("ColorRect")
	center_container = get_node_or_null("CenterContainer")
	score_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/ScoreLabel")
	high_score_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HighScoreLabel")
	new_record_label = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/NewRecordLabel")
	retry_button = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HBoxButtons/RetryButton")
	menu_button = get_node_or_null("CenterContainer/VBoxContainer/Panel/VBoxContent/HBoxButtons/MenuButton")

func show_game_over(final_score: int, final_level: int) -> void:
	# Verificar que SaveManager existe
	if not SaveManager:
		print("[GameOver] Error: SaveManager no encontrado")
		return
	
	# Obtener high score antes de verificar si es nuevo récord
	var high_score = SaveManager.get_high_score()
	# Verificar y guardar si es nuevo récord
	var is_new_record = SaveManager.check_and_save_score(final_score, final_level)
	
	# Actualizar labels si existen
	if score_label:
		score_label.text = "Puntuación: %d" % final_score
	if high_score_label:
		high_score_label.text = "Mejor Puntuación: %d" % high_score
	
	# Mostrar mensaje de nuevo récord si aplica
	if is_new_record:
		if new_record_label:
			new_record_label.visible = true
		if high_score_label:
			high_score_label.text = "Mejor Puntuación: %d" % final_score
	else:
		if new_record_label:
			new_record_label.visible = false
	
	# Mostrar la pantalla
	if color_rect:
		color_rect.visible = true
	if center_container:
		center_container.visible = true
	
	# Pausar el juego
	get_tree().paused = true

func _on_retry_button_pressed() -> void:
	# Verificar que ScoreManager existe
	if not ScoreManager:
		print("[GameOver] Error: ScoreManager no encontrado")
		return
	
	# Despausar y reiniciar
	get_tree().paused = false
	ScoreManager.reset()
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	# Verificar que ScoreManager existe
	if not ScoreManager:
		print("[GameOver] Error: ScoreManager no encontrado")
		return
	
	# Despausar y volver al menú
	get_tree().paused = false
	ScoreManager.reset()
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
