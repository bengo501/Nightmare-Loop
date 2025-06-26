extends Node3D

var player_inside = false
var player_ref: Node3D
var skill_tree_active = false
var original_camera: Camera3D = null
var first_interaction = true
var dialog_active = false

# Arquivo para salvar o estado da primeira interação
const SAVE_FILE = "user://tv_william_dialog_seen.save"

# Referências aos nós da TV
@onready var tv_camera = $TVCamera
@onready var skill_tree_ui = $SkillTreeUI
@onready var interaction_prompt = $InteractionPrompt

# Referências aos managers
@onready var ui_manager = get_node("/root/UIManager")
@onready var state_manager = get_node("/root/GameStateManager")
@onready var skill_manager = get_node("/root/SkillManager")

# Referência ao sistema de diálogo
var dialog_system_scene = preload("res://scenes/ui/dialog_system.tscn")

func _ready():
	# Carrega o estado da primeira interação
	load_dialog_state()
	
	# Conecta os sinais da área de interação
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	
	# Conecta os sinais da skill tree
	if skill_tree_ui:
		skill_tree_ui.connect("skill_upgraded", _on_skill_upgraded)
		skill_tree_ui.connect("skill_tree_closed", _on_skill_tree_closed)
		print("[TV] ✓ Conectado aos sinais da skill tree")
	else:
		print("[TV] ❌ SkillTreeUI não encontrado!")
	
	# Conecta aos sinais do SkillManager
	if skill_manager:
		skill_manager.skill_upgraded.connect(_on_skill_manager_upgraded)
		print("[TV] ✓ Conectado ao SkillManager")
	else:
		print("[TV] ❌ SkillManager não encontrado!")
	
	print("[TV] Sistema de TV-Skill Tree inicializado")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		
		if first_interaction:
			# Primeira vez - inicia diálogo automaticamente
			start_william_dialog()
		else:
			# Demais vezes - mostra prompt normal
			show_interaction_prompt()
		
		print("[TV] Jogador entrou na área da TV")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		
		# Só esconde o prompt se não estiver em diálogo
		if not dialog_active:
			hide_interaction_prompt()
		
		print("[TV] Jogador saiu da área da TV")

func _input(event):
	if player_inside and event.is_action_pressed("interact") and not skill_tree_active and not dialog_active:
		# Agora só ativa skill tree, pois o diálogo acontece automaticamente na primeira aproximação
		activate_skill_tree()
	elif skill_tree_active and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("skill_tree")):
		deactivate_skill_tree()

func show_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = true

func hide_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false

func load_dialog_state():
	# Verifica se o arquivo de save existe
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var loaded_value = file.get_var()
			if loaded_value != null:
				first_interaction = loaded_value
			file.close()
			print("[TV] Estado do diálogo carregado: primeira_interacao = ", first_interaction)
		else:
			print("[TV] Erro ao abrir arquivo de save, primeira interação será verdadeira")
	else:
		print("[TV] Arquivo de save não encontrado, primeira interação será verdadeira")

func save_dialog_state():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(first_interaction)
		file.close()
		print("[TV] Estado do diálogo salvo: primeira_interacao = ", first_interaction)

# Função para resetar o estado do diálogo (para novo jogo)
func reset_dialog_state():
	first_interaction = true
	save_dialog_state()
	print("[TV] Estado do diálogo resetado para novo jogo")

func start_william_dialog():
	print("[TV] Iniciando diálogo com William pela primeira vez")
	
	first_interaction = false
	dialog_active = true
	
	# Salva o estado para que não aconteça novamente
	save_dialog_state()
	
	# Esconde o prompt de interação
	hide_interaction_prompt()
	
	print("[TV] Pausando jogador...")
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		print("[TV] Jogador pausado com sucesso")
	else:
		print("[TV] AVISO: player_ref é null!")
	
	print("[TV] Escondendo HUD...")
	# Esconde a HUD principal
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
	if hud and is_instance_valid(hud):
		hud.visible = false
		print("[TV] HUD escondida")
	else:
		print("[TV] AVISO: HUD não encontrada")
	
	print("[TV] Criando instância do sistema de diálogo...")
	# Cria e mostra o sistema de diálogo
	var dialog_instance = dialog_system_scene.instantiate()
	if not dialog_instance:
		print("[TV] ERRO: Falha ao instanciar sistema de diálogo!")
		return
	
	print("[TV] Adicionando sistema de diálogo à cena...")
	get_tree().current_scene.add_child(dialog_instance)
	
	print("[TV] Conectando sinal de fim do diálogo...")
	# Conecta o sinal de fim do diálogo
	dialog_instance.connect("dialog_sequence_finished", _on_dialog_finished)
	
	print("[TV] Pausando jogo...")
	# Pausa o jogo ANTES de iniciar o diálogo
	get_tree().paused = true
	
	print("[TV] Iniciando diálogos da TV...")
	# Inicia os diálogos da TV
	dialog_instance.start_tv_dialog()
	
	print("[TV] Liberando cursor...")
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[TV] Diálogo com William iniciado com sucesso!")

func _on_dialog_finished():
	print("[TV] Diálogo com William finalizado")
	
	dialog_active = false
	
	# Mostra o prompt de interação novamente se o jogador ainda estiver na área
	if player_inside:
		show_interaction_prompt()
	
	# Libera o jogador
	if player_ref:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
	
	# Mostra a HUD principal
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
	if hud and is_instance_valid(hud):
		hud.visible = true
		print("[TV] HUD restaurada")
	else:
		print("[TV] AVISO: HUD não encontrada para restaurar")
	
	# Despausa o jogo
	get_tree().paused = false
	
	# Restaura o modo do cursor baseado no modo da câmera do jogador
	if player_ref and player_ref.has_method("get") and player_ref.get("first_person_mode"):
		if player_ref.first_person_mode:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func activate_skill_tree():
	if skill_tree_active:
		return
	
	print("[TV] Ativando árvore de habilidades via TV")
	
	skill_tree_active = true
	
	# Salva a câmera original
	original_camera = get_viewport().get_camera_3d()
	
	# Ativa a câmera da TV
	if tv_camera:
		tv_camera.make_current()
		print("[TV] Câmera da TV ativada")
	
	# Esconde o prompt de interação
	hide_interaction_prompt()
	
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
		print("[TV] Jogador pausado para skill tree")
	
	# Esconde a HUD principal
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
	if hud and is_instance_valid(hud):
		hud.visible = false
		print("[TV] HUD escondida")
	else:
		print("[TV] AVISO: HUD não encontrada")
	
	# Mostra a skill tree
	if skill_tree_ui and is_instance_valid(skill_tree_ui):
		skill_tree_ui.visible = true
		skill_tree_ui.show_menu()
		print("[TV] Skill tree UI ativada")
	else:
		print("[TV] ERRO: Skill tree UI não encontrada!")
		deactivate_skill_tree()
		return
	
	# Muda o estado do jogo
	if state_manager:
		state_manager.change_state(state_manager.GameState.SKILL_TREE)
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[TV] Árvore de habilidades ativada com sucesso!")

func deactivate_skill_tree():
	if not skill_tree_active:
		return
	
	print("[TV] Desativando árvore de habilidades via TV")
	
	skill_tree_active = false
	
	# Esconde a skill tree primeiro
	if skill_tree_ui and is_instance_valid(skill_tree_ui):
		skill_tree_ui.hide_skill_tree()
		skill_tree_ui.visible = false
		print("[TV] Skill tree UI desativada")
	
	# Restaura a câmera original
	if original_camera and is_instance_valid(original_camera):
		original_camera.make_current()
		print("[TV] Câmera original restaurada")
	else:
		print("[TV] AVISO: Câmera original não encontrada")
	
	# Mostra o prompt de interação novamente se o jogador ainda estiver na área
	if player_inside:
		show_interaction_prompt()
	
	# Libera o jogador
	if player_ref and is_instance_valid(player_ref):
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
		print("[TV] Jogador liberado")
	
	# Mostra a HUD principal
	var hud = get_node_or_null("/root/UIManager/hud_instance")
	if not hud:
		hud = get_tree().get_first_node_in_group("hud")
	if hud and is_instance_valid(hud):
		hud.visible = true
		print("[TV] HUD restaurada")
	else:
		print("[TV] AVISO: HUD não encontrada para restaurar")
	
	# Muda o estado do jogo
	if state_manager:
		state_manager.change_state(state_manager.GameState.PLAYING)
	
	# Despausa o jogo
	get_tree().paused = false
	
	# Restaura o modo do cursor baseado no modo da câmera do jogador
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("get") and player_ref.get("first_person_mode"):
		if player_ref.first_person_mode:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[TV] Árvore de habilidades desativada com sucesso!")

func _on_skill_upgraded(branch: String, level: int):
	print("[TV] Habilidade melhorada via UI: ", branch, " nível ", level)
	# A aplicação real será feita pelo SkillManager
	play_upgrade_effect()

func _on_skill_tree_closed():
	print("[TV] Skill tree foi fechada via sinal")
	# Chama a função de desativação
	deactivate_skill_tree()

func _on_skill_manager_upgraded(branch: String, level: int):
	print("[TV] Habilidade melhorada via SkillManager: ", branch, " nível ", level)
	# Aqui você pode adicionar efeitos visuais específicos da TV
	play_upgrade_effect()

func play_upgrade_effect():
	# Adiciona um pequeno efeito visual/sonoro quando uma habilidade é melhorada
	print("[TV] Efeito de upgrade de habilidade reproduzido")
	
	# Você pode adicionar aqui:
	# - Efeito de partículas
	# - Som de confirmação
	# - Animação da TV
	# - Etc.

# Função para ser chamada externamente se necessário
func force_close_skill_tree():
	if skill_tree_active:
		deactivate_skill_tree()
