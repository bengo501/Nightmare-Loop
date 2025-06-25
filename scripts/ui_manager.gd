# ===============================
# UIManager.gd
# ===============================
extends Node

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

# Referências para cenas de UI
var ui_scenes := {
	"main_menu": preload("res://scenes/ui/main_menu.tscn"),
	"pause_menu": preload("res://scenes/ui/pause_menu.tscn"),
	"options_menu": preload("res://scenes/ui/options_menu.tscn"),
	"game_over": preload("res://scenes/ui/game_over.tscn"),
	"item_menu": preload("res://scenes/ui/ItemMenu.tscn"),
	"hud": preload("res://scenes/ui/hud.tscn"),
	"skill_tree": preload("res://scenes/ui/skill_tree.tscn"),
	"stage_intro": preload("res://scenes/ui/stage_intro.tscn")
}

# Gerenciamento de instâncias
var active_ui := {}

var hud_instance = null       # Referência específica para a HUD
var stage_intro_instance = null  # Referência específica para a introdução de estágio

@onready var state_manager = get_node("/root/GameStateManager")
@onready var scene_manager = get_node("/root/SceneManager")

func _ready():
	state_manager.connect("state_changed", _on_state_changed)
	scene_manager.connect("scene_changed", _on_scene_changed)
	if state_manager.current_state == state_manager.GameState.PLAYING:
		show_ui("hud")

func _on_scene_changed(_scene_path: String):
	# Limpa referências inválidas primeiro
	cleanup_invalid_references()
	
	# Limpa todas as UIs ao mudar de cena
	hide_all_ui()
	
	# Se estiver no estado PLAYING, mostra a HUD
	if state_manager.current_state == state_manager.GameState.PLAYING:
		show_ui("hud")

func _on_state_changed(new_state):
	hide_all_ui()
	match new_state:
		state_manager.GameState.MAIN_MENU:
			show_ui("main_menu")
		state_manager.GameState.PLAYING:
			show_ui("hud")
		state_manager.GameState.GAME_OVER:
			show_ui("game_over")
		state_manager.GameState.DIALOGUE:
			# Mantém a UI atual durante diálogos
			pass
		state_manager.GameState.INVENTORY:
			show_ui("item_menu")
		state_manager.GameState.SKILL_TREE:
			show_ui("skill_tree")

func show_ui(ui_name: String, data: Dictionary = {}):
	print("[UIManager] show_ui() chamado para: ", ui_name)
	
	# Remove instância anterior se existir
	if active_ui.has(ui_name):
		print("[UIManager] Removendo instância anterior de: ", ui_name)
		var old_instance = active_ui[ui_name]
		if old_instance != null and is_instance_valid(old_instance) and not old_instance.is_queued_for_deletion():
			old_instance.queue_free()
			print("[UIManager] Instância anterior de ", ui_name, " removida")
		else:
			print("[UIManager] Instância anterior de ", ui_name, " já foi liberada ou é inválida")
		active_ui.erase(ui_name)

	if ui_scenes.has(ui_name):
		print("[UIManager] Cena encontrada para: ", ui_name)
		var instance = ui_scenes[ui_name].instantiate()
		if instance:
			print("[UIManager] Instância criada para: ", ui_name)
			add_child(instance)
			active_ui[ui_name] = instance
			emit_signal("ui_opened", ui_name)
			print("[UIManager] UI ", ui_name, " criada com sucesso")

			if instance.has_method("setup"):
				instance.setup(data)
				
			# Special handling for specific UI types
			match ui_name:
				"hud":
					hud_instance = instance
					print("[UIManager] HUD instanciada e referenciada")
				"stage_intro":
					stage_intro_instance = instance
					print("[UIManager] Introdução de estágio instanciada e referenciada")
		else:
			print("[UIManager] ERRO: Falha ao instanciar UI ", ui_name)
	else:
		print("[UIManager] ERRO: UI não encontrada: ", ui_name)
		print("[UIManager] UIs disponíveis: ", ui_scenes.keys())

func hide_ui(ui_name: String):
	if active_ui.has(ui_name):
		var ui_instance = active_ui[ui_name]
		if ui_instance != null and is_instance_valid(ui_instance) and not ui_instance.is_queued_for_deletion():
			ui_instance.queue_free()
			print("[UIManager] UI ", ui_name, " removida com segurança")
		else:
			print("[UIManager] UI ", ui_name, " já foi liberada ou é inválida")
		
		emit_signal("ui_closed", ui_name)
		active_ui.erase(ui_name)
		
		# Clear specific references
		match ui_name:
			"hud":
				if hud_instance == ui_instance:
					hud_instance = null
			"stage_intro":
				if stage_intro_instance == ui_instance:
					stage_intro_instance = null

func hide_all_ui():
	var ui_names = active_ui.keys().duplicate()  # Cria uma cópia para evitar modificação durante iteração
	for ui_name in ui_names:
		hide_ui(ui_name)

func cleanup_invalid_references():
	"""
	Limpa referências inválidas ou liberadas
	"""
	print("[UIManager] Limpando referências inválidas")
	
	# Limpa referência da HUD se inválida
	if hud_instance != null and (not is_instance_valid(hud_instance) or hud_instance.is_queued_for_deletion()):
		print("[UIManager] Limpando referência inválida da HUD")
		hud_instance = null
	
	# Limpa referência da stage_intro se inválida
	if stage_intro_instance != null and (not is_instance_valid(stage_intro_instance) or stage_intro_instance.is_queued_for_deletion()):
		print("[UIManager] Limpando referência inválida da stage_intro")
		stage_intro_instance = null
	
	# Limpa instâncias inválidas do dicionário active_ui
	var invalid_keys = []
	for ui_name in active_ui.keys():
		var instance = active_ui[ui_name]
		if instance == null or not is_instance_valid(instance) or instance.is_queued_for_deletion():
			invalid_keys.append(ui_name)
	
	for key in invalid_keys:
		print("[UIManager] Removendo instância inválida: ", key)
		active_ui.erase(key)

# Chamado por UI interativa para mudar cena
func request_scene_change(scene_name: String):
	scene_manager.change_scene(scene_name)

func request_map_change(map_name: String):
	scene_manager.change_map(map_name)

# Função específica para mostrar introdução de estágio
func show_stage_intro(stage_name: String = "estagio1"):
	"""
	Mostra a introdução do estágio especificado
	"""
	print("[UIManager] Solicitando exibição da introdução do estágio: ", stage_name)
	
	# Cria a instância se não existir ou se for inválida
	if stage_intro_instance == null or not is_instance_valid(stage_intro_instance) or stage_intro_instance.is_queued_for_deletion():
		print("[UIManager] Criando nova instância de stage_intro")
		show_ui("stage_intro")
	else:
		print("[UIManager] Instância de stage_intro já existe e é válida")
	
	# Aguarda um frame para garantir que foi criada
	call_deferred("_show_stage_intro_deferred", stage_name)

func _show_stage_intro_deferred(stage_name: String):
	"""
	Função auxiliar para mostrar a introdução após um frame
	"""
	print("[UIManager] _show_stage_intro_deferred() executado com estágio: ", stage_name)
	print("[UIManager] stage_intro_instance válido: ", stage_intro_instance != null and is_instance_valid(stage_intro_instance))
	
	# Mostra a introdução
	if stage_intro_instance != null and is_instance_valid(stage_intro_instance) and not stage_intro_instance.is_queued_for_deletion():
		print("[UIManager] Instância válida encontrada")
		if stage_intro_instance.has_method("show_stage_intro"):
			print("[UIManager] Método show_stage_intro encontrado, chamando...")
			stage_intro_instance.show_stage_intro(stage_name)
			print("[UIManager] Introdução de estágio iniciada")
		else:
			print("[UIManager] ERRO: Método show_stage_intro não encontrado na instância")
	else:
		print("[UIManager] ERRO: Não foi possível criar ou acessar a instância de introdução de estágio")

func hide_stage_intro():
	"""
	Esconde a introdução do estágio
	"""
	print("[UIManager] hide_stage_intro() chamado")
	
	if stage_intro_instance != null and is_instance_valid(stage_intro_instance) and not stage_intro_instance.is_queued_for_deletion():
		if stage_intro_instance.has_method("hide_stage_intro"):
			stage_intro_instance.hide_stage_intro()
			print("[UIManager] Método hide_stage_intro chamado na instância")
		else:
			print("[UIManager] AVISO: Método hide_stage_intro não encontrado, forçando remoção")
	else:
		print("[UIManager] stage_intro_instance não é válida ou já foi liberada")
	
	# Remove a UI independentemente
	hide_ui("stage_intro")
