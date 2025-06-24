extends Node3D

var player_inside = false
var player_ref: Node3D
var skill_tree_active = false
var original_camera: Camera3D = null

# Referências aos nós da TV
@onready var tv_camera = $TVCamera
@onready var skill_tree_ui = $SkillTreeUI
@onready var interaction_prompt = $InteractionPrompt

# Referências aos managers
@onready var ui_manager = get_node("/root/UIManager")
@onready var state_manager = get_node("/root/GameStateManager")
@onready var skill_manager = get_node("/root/SkillManager")

func _ready():
	# Conecta os sinais da área de interação
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)
	
	# Conecta os sinais da skill tree
	if skill_tree_ui:
		skill_tree_ui.connect("skill_upgraded", _on_skill_upgraded)
	
	# Conecta aos sinais do SkillManager
	if skill_manager:
		skill_manager.skill_upgraded.connect(_on_skill_manager_upgraded)
	
	print("[TV] Sistema de TV-Skill Tree inicializado")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		show_interaction_prompt()
		print("[TV] Jogador entrou na área da TV")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		hide_interaction_prompt()
		print("[TV] Jogador saiu da área da TV")

func _input(event):
	if player_inside and event.is_action_pressed("interact") and not skill_tree_active:
		activate_skill_tree()
	elif skill_tree_active and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("skill_tree")):
		deactivate_skill_tree()

func show_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = true

func hide_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false

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
	
	# Esconde o prompt de interação
	hide_interaction_prompt()
	
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
	
	# Esconde a HUD principal
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = false
	
	# Mostra a skill tree
	if skill_tree_ui and is_instance_valid(skill_tree_ui):
		skill_tree_ui.visible = true
		skill_tree_ui.show_menu()
	
	# Muda o estado do jogo
	if state_manager:
		state_manager.change_state(state_manager.GameState.SKILL_TREE)
	
	# Pausa o jogo
	get_tree().paused = true
	
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func deactivate_skill_tree():
	if not skill_tree_active:
		return
	
	print("[TV] Desativando árvore de habilidades via TV")
	
	skill_tree_active = false
	
	# Restaura a câmera original
	if original_camera:
		original_camera.make_current()
	
	# Mostra o prompt de interação novamente se o jogador ainda estiver na área
	if player_inside:
		show_interaction_prompt()
	
	# Libera o jogador
	if player_ref:
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
	
	# Mostra a HUD principal
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = true
	
	# Esconde a skill tree
	if skill_tree_ui and is_instance_valid(skill_tree_ui):
		skill_tree_ui.visible = false
	
	# Muda o estado do jogo
	if state_manager:
		state_manager.change_state(state_manager.GameState.PLAYING)
	
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

func _on_skill_upgraded(branch: String, level: int):
	print("[TV] Habilidade melhorada via UI: ", branch, " nível ", level)
	# A aplicação real será feita pelo SkillManager
	play_upgrade_effect()

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
