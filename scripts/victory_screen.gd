# Pantalla de Victoria
# Se muestra cuando el jugador completa todos los niveles
# Muestra puntuación final, tiempo de juego y estadísticas completas
extends CanvasLayer

# ============================================================================
# REFERENCIAS A NODOS
# ============================================================================
var color_rect: ColorRect
var center_container: CenterContainer
var title_label: Label
var score_label: Label
var time_label: Label
var stats_container: VBoxContainer
var slimes_label: Label
var orcs_label: Label
var bosses_label: Label
var damage_label: Label
var levels_label: Label
var menu_button: Button

# ============================================================================
# INICIALIZACIÓN
# ============================================================================
func _ready() -> void:
	# Obtener referencias de nodos de forma segura
	color_rect = get_node_or_null("ColorRect")
	center_container = get_node_or_null("CenterContainer")
	
	if center_container:
		var panel = center_container.get_node_or_null("VBoxContainer/Panel/VBoxContent")
		if panel:
			title_label = panel.get_node_or_null("TitleLabel")
			score_label = panel.get_node_or_null("ScoreLabel")
			time_label = panel.get_node_or_null("TimeLabel")
			stats_container = panel.get_node_or_null("StatsContainer")
			
			# Obtener labels de estadísticas
			if stats_container:
				slimes_label = stats_container.get_node_or_null("SlimesLabel")
				orcs_label = stats_container.get_node_or_null("OrcsLabel")
				bosses_label = stats_container.get_node_or_null("BossesLabel")
				damage_label = stats_container.get_node_or_null("DamageLabel")
				levels_label = stats_container.get_node_or_null("LevelsLabel")
			
			# Configurar botón de menú
			menu_button = panel.get_node_or_null("MenuButton")
			if menu_button:
				# Evitar dobles conexiones
				if menu_button.pressed.is_connected(_on_menu_button_pressed):
					menu_button.pressed.disconnect(_on_menu_button_pressed)
				menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Ocultar la pantalla inicialmente
	if color_rect: color_rect.visible = false
	if center_container: center_container.visible = false

# ============================================================================
# MOSTRAR PANTALLA DE VICTORIA
# ============================================================================
func show_victory(final_score: int, stats: Dictionary) -> void:
	print("[VictoryScreen] show_victory llamado con score: ", final_score)
	
	# Intentar guardar récord si SaveManager está disponible
	# Los autoloads en Godot 4 están disponibles globalmente
	if has_node("/root/SaveManager"):
		var save_mgr = get_node("/root/SaveManager")
		if save_mgr:
			var _is_new_record = save_mgr.check_and_save_score(final_score, ScoreManager.MAX_LEVEL)
			print("[VictoryScreen] Récord guardado (si aplica)")
	else:
		# Intentar acceso directo (autoload está disponible globalmente)
		if SaveManager:
			var _is_new_record = SaveManager.check_and_save_score(final_score, ScoreManager.MAX_LEVEL)
			print("[VictoryScreen] Récord guardado (si aplica) via acceso directo")
		else:
			print("[VictoryScreen] Advertencia: SaveManager no disponible, continuando sin guardar récord")
	
	# Actualizar título de victoria
	if title_label:
		title_label.text = "¡FELICIDADES! ¡GANASTE!"
	
	# Actualizar puntuación final
	if score_label:
		score_label.text = "Puntuación Final: %d" % final_score
	
	# Actualizar tiempo de juego formateado
	if time_label and stats.has("play_time"):
		var time_formatted = GameStats.format_time(stats.get("play_time", 0.0))
		time_label.text = "Tiempo Total: %s" % time_formatted
	
	# Actualizar todas las estadísticas si están disponibles
	if stats_container:
		if slimes_label and stats.has("slimes_killed"):
			slimes_label.text = "Slimes Eliminados: %d" % stats.get("slimes_killed", 0)
		
		if orcs_label and stats.has("orcs_killed"):
			orcs_label.text = "Orcos Eliminados: %d" % stats.get("orcs_killed", 0)
		
		if bosses_label and stats.has("bosses_killed"):
			bosses_label.text = "Jefes Eliminados: %d" % stats.get("bosses_killed", 0)
		
		if damage_label and stats.has("total_damage_taken"):
			damage_label.text = "Daño Recibido: %d" % stats.get("total_damage_taken", 0)
		
		if levels_label and stats.has("levels_completed"):
			levels_label.text = "Niveles Completados: %d" % stats.get("levels_completed", 0)
	
	# Mostrar la pantalla (esto siempre se ejecuta, incluso si SaveManager falla)
	if color_rect: 
		color_rect.visible = true
		print("[VictoryScreen] ColorRect visible: ", color_rect.visible)
	if center_container: 
		center_container.visible = true
		print("[VictoryScreen] CenterContainer visible: ", center_container.visible)
	
	# Pausar el juego para que el jugador pueda ver los resultados
	get_tree().paused = true
	print("[VictoryScreen] Juego pausado. Pantalla de victoria mostrada.")

# ============================================================================
# NAVEGACIÓN
# ============================================================================
# Botón "Menú": Vuelve al menú principal y resetea todo
func _on_menu_button_pressed() -> void:
	# Despausar el juego
	get_tree().paused = false
	
	# Resetear managers (acceso directo ya que son autoloads)
	if ScoreManager:
		ScoreManager.reset()
	if GameStats:
		GameStats.reset_stats()
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://escenas/inicio.tscn")
