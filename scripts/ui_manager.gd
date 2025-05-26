extends Node

# UI scenes dictionary
var ui_scenes = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"pause_menu": "res://scenes/ui/pause_menu.tscn",
	"options_menu": "res://scenes/ui/options_menu.tscn",
	"hud": "res://scenes/ui/hud.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"inventory": "res://scenes/ui/inventory.tscn",
	"credits": "res://scenes/ui/credits.tscn",
	"battle_ui": "res://scenes/ui/BattleUI.tscn",
	"skill_menu": "res://scenes/ui/SkillMenu.tscn",
	"item_menu": "res://scenes/ui/ItemMenu.tscn",
	"talk_menu": "res://scenes/ui/TalkMenu.tscn",
	"gifts_menu": "res://scenes/ui/GiftsMenu.tscn",
	"skill_tree": "res://scenes/ui/skill_tree.tscn"
}

# Current UI elements
var current_ui = null
var active_menus = []
var hud_instance = null
var options_menu_instance = null
var battle_ui_instance = null
var active_battle_menu = null  # Menu ativo durante a batalha (skill, item, talk)
var skill_tree_instance = null  # Instância da árvore de habilidades

# References to other managers
@onready var game_manager = get_node("/root/GameManager")
@onready var state_manager = get_node("/root/GameStateManager")

func _ready():
	# Connect to game manager signals
	game_manager.health_changed.connect(_on_health_changed)
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.level_up.connect(_on_level_up)
	game_manager.game_over.connect(_on_game_over)
	
	# Connect to state manager signals
	state_manager.state_changed.connect(_on_game_state_changed)
	
	# Cria a SkillTree no início
	_create_skill_tree()

# UI control functions
func show_ui(ui_name: String) -> void:
	if not ui_scenes.has(ui_name):
		push_error("UI scene not found: " + ui_name)
		return
	
	# Se já existe uma instância do menu de opções, apenas torna visível
	if ui_name == "options_menu" and options_menu_instance:
		options_menu_instance.show()
		return
		
	var ui_scene = load(ui_scenes[ui_name]).instantiate()
	add_child(ui_scene)
	active_menus.append(ui_scene)
	current_ui = ui_scene
	
	# Guarda referência do menu de opções
	if ui_name == "options_menu":
		options_menu_instance = ui_scene
	
	# Se for o menu de pause, esconde a HUD
	if ui_name == "pause_menu" and hud_instance:
		hud_instance.visible = false
	
	# Se for a tela de game over, esconde a HUD e conecta os botões
	if ui_name == "game_over":
		if hud_instance:
			hud_instance.visible = false
		if ui_scene.has_node("MenuContainer/RestartButton"):
			ui_scene.get_node("MenuContainer/RestartButton").pressed.connect(_on_game_over_restart)
		if ui_scene.has_node("MenuContainer/MainMenuButton"):
			ui_scene.get_node("MenuContainer/MainMenuButton").pressed.connect(_on_game_over_main_menu)
		if ui_scene.has_node("MenuContainer/QuitButton"):
			ui_scene.get_node("MenuContainer/QuitButton").pressed.connect(_on_game_over_quit)

func hide_ui(ui_name: String) -> void:
	# Se for o menu de opções e ele existe, apenas esconde
	if ui_name == "options_menu" and options_menu_instance:
		options_menu_instance.hide()
		return
	for menu in active_menus:
		if menu.name.to_lower() == ui_name.to_lower():
			menu.queue_free()
			active_menus.erase(menu)
			# Se for o menu de pause, mostra a HUD novamente
			if ui_name == "pause_menu" and hud_instance:
				hud_instance.visible = true
			break

func hide_all_ui() -> void:
	for menu in active_menus:
		menu.queue_free()
	active_menus.clear()
	current_ui = null
	options_menu_instance = null

# Signal handlers
func _on_health_changed(new_health: int) -> void:
	if current_ui and current_ui.has_method("update_health"):
		current_ui.update_health(new_health)

func _on_score_changed(new_score: int) -> void:
	if current_ui and current_ui.has_method("update_score"):
		current_ui.update_score(new_score)

func _on_level_up(new_level: int) -> void:
	if current_ui and current_ui.has_method("update_level"):
		current_ui.update_level(new_level)

func _on_game_over() -> void:
	show_ui("game_over")

func _on_game_state_changed(new_state: int) -> void:
	match new_state:
		state_manager.GameState.MAIN_MENU:
			hide_all_ui()
			show_ui("main_menu")
		state_manager.GameState.PLAYING:
			hide_all_ui()
			show_ui("hud")
			hud_instance = current_ui  # Guarda referência da HUD
		state_manager.GameState.PAUSED:
			show_ui("pause_menu")
		state_manager.GameState.GAME_OVER:
			show_ui("game_over")
		state_manager.GameState.INVENTORY:
			show_ui("inventory") 

# Funções dos botões da tela de game over
func _on_game_over_restart():
	get_node("/root/SceneManager").change_scene("world")
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.PLAYING)
	hide_ui("game_over")

func _on_game_over_main_menu():
	get_node("/root/SceneManager").change_scene("main_menu")
	get_node("/root/GameStateManager").change_state(get_node("/root/GameStateManager").GameState.MAIN_MENU)
	hide_ui("game_over")

func _on_game_over_quit():
	get_tree().quit() 

# Funções específicas para menus de batalha
func show_battle_menu(menu_name: String) -> void:
	if not ui_scenes.has(menu_name):
		push_error("Menu de batalha não encontrado: " + menu_name)
		return
	
	# Fecha o menu ativo se existir
	if active_battle_menu:
		active_battle_menu.queue_free()
	
	# Instancia o novo menu
	var menu_scene = load(ui_scenes[menu_name]).instantiate()
	battle_ui_instance.add_child(menu_scene)
	active_battle_menu = menu_scene
	
	# Conecta os sinais específicos do menu
	match menu_name:
		"skill_menu":
			if menu_scene.has_signal("skill_selected"):
				menu_scene.skill_selected.connect(_on_skill_selected)
		"item_menu":
			if menu_scene.has_signal("item_selected"):
				menu_scene.item_selected.connect(_on_item_selected)
		"talk_menu":
			if menu_scene.has_signal("talk_option_selected"):
				menu_scene.talk_option_selected.connect(_on_talk_option_selected)
		"gifts_menu":
			if menu_scene.has_signal("gift_selected"):
				menu_scene.gift_selected.connect(_on_gift_selected)
	
	# Mostra o menu
	menu_scene.show_menu()

func hide_battle_menu() -> void:
	if active_battle_menu:
		active_battle_menu.queue_free()
		active_battle_menu = null

# Handlers para os sinais dos menus de batalha
func _on_skill_selected(skill_data):
	if battle_ui_instance and battle_ui_instance.has_signal("skill_selected"):
		battle_ui_instance.emit_signal("skill_selected", skill_data)
	hide_battle_menu()

func _on_item_selected(item_data):
	if battle_ui_instance and battle_ui_instance.has_signal("item_selected"):
		battle_ui_instance.emit_signal("item_selected", item_data)
	hide_battle_menu()

func _on_talk_option_selected(option_data):
	if battle_ui_instance and battle_ui_instance.has_signal("talk_option_selected"):
		battle_ui_instance.emit_signal("talk_option_selected", option_data)
	hide_battle_menu()

# Handler para o sinal do GiftsMenu
func _on_gift_selected(gift_id):
	if battle_ui_instance and battle_ui_instance.has_signal("gift_selected"):
		battle_ui_instance.emit_signal("gift_selected", gift_id)
	hide_battle_menu()

# Função para criar a SkillTree
func _create_skill_tree():
	if not skill_tree_instance:
		var skill_tree_resource = load(ui_scenes["skill_tree"])
		if not skill_tree_resource:
			push_error("SkillTree scene not found or failed to load: " + str(ui_scenes["skill_tree"]))
			return
		var skill_tree_scene = skill_tree_resource.instantiate()
		if not skill_tree_scene:
			push_error("Failed to instantiate SkillTree scene.")
			return
		add_child(skill_tree_scene)
		skill_tree_instance = skill_tree_scene
		
		# Conecta o sinal de upgrade
		if skill_tree_instance.has_signal("skill_upgraded"):
			skill_tree_instance.skill_upgraded.connect(_on_skill_upgraded)
		
		# Carrega o progresso salvo
		load_skill_progress()

# Função para mostrar a árvore de habilidades
func show_skill_tree():
	if not skill_tree_instance:
		_create_skill_tree()
	if skill_tree_instance:
		skill_tree_instance.show()
		skill_tree_instance.raise()
		skill_tree_instance.set_process_input(true)
		skill_tree_instance.set_process(true)
		skill_tree_instance.set_process_unhandled_input(true)
		skill_tree_instance.set_process_unhandled_key_input(true)

# Handler para o sinal de upgrade de habilidade
func _on_skill_upgraded(skill_data):
	# Aqui você pode implementar a lógica para aplicar o upgrade da habilidade
	# Por exemplo, atualizar os dados do jogador ou salvar o progresso
	print("Habilidade atualizada: ", skill_data.name, " para nível ", skill_data.level)
	
	# Se houver um jogador ativo, atualiza suas habilidades
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("update_skill"):
		player.update_skill(skill_data)
	
	# Salva o progresso das habilidades
	save_skill_progress()

# Função para salvar o progresso das habilidades
func save_skill_progress():
	if skill_tree_instance:
		var save_data = {
			"skills": skill_tree_instance.available_skills
		}
		# Aqui você pode implementar a lógica para salvar os dados
		# Por exemplo, usando o sistema de save do jogo
		print("Progresso das habilidades salvo")

# Função para carregar o progresso das habilidades
func load_skill_progress():
	if skill_tree_instance:
		# Aqui você pode implementar a lógica para carregar os dados
		# Por exemplo, usando o sistema de save do jogo
		print("Progresso das habilidades carregado") 
