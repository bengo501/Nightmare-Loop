extends Node3D

# Referências
var player_inside = false
var player_ref: Node3D
var interaction_active = false

# Referências aos nós filhos
@onready var area_3d = $Area3D
@onready var interaction_prompt = $InteractionPrompt

# Variáveis para animação
var prompt_tween: Tween

# Referências aos managers
@onready var ui_manager = get_node("/root/UIManager")
var scene_manager

func _ready():
	print("[BedInteraction] Inicializando sistema de interação com a cama")
	
	# Obtém referência ao SceneManager
	scene_manager = SceneManager
	if scene_manager:
		print("[BedInteraction] SceneManager conectado com sucesso")
	else:
		print("[BedInteraction] ERRO: SceneManager não encontrado!")
	
	# Conecta os sinais da área de interação
	if area_3d:
		area_3d.body_entered.connect(_on_body_entered)
		area_3d.body_exited.connect(_on_body_exited)
		print("[BedInteraction] Sinais da Area3D conectados")
	else:
		print("[BedInteraction] ERRO: Area3D não encontrada!")
	
	# Esconde o prompt inicialmente
	if interaction_prompt:
		interaction_prompt.visible = false
		print("[BedInteraction] Prompt de interação configurado")
	else:
		print("[BedInteraction] AVISO: Prompt de interação não encontrado")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		show_interaction_prompt()
		print("[BedInteraction] Jogador entrou na área da cama")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		hide_interaction_prompt()
		print("[BedInteraction] Jogador saiu da área da cama")

func _input(event):
	if player_inside and event.is_action_pressed("interact") and not interaction_active:
		sleep_interaction()
	
	# Função de emergência para destravar o jogo
	if event.is_action_pressed("ui_cancel") and interaction_active:
		print("[BedInteraction] EMERGÊNCIA: Destravando jogo")
		emergency_unlock()

func show_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = true
		start_prompt_animation()

func hide_interaction_prompt():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = false
		stop_prompt_animation()

func start_prompt_animation():
	if interaction_prompt and is_instance_valid(interaction_prompt):
		stop_prompt_animation()
		prompt_tween = create_tween()
		prompt_tween.set_loops()
		prompt_tween.tween_property(interaction_prompt, "modulate:a", 0.6, 0.8)
		prompt_tween.tween_property(interaction_prompt, "modulate:a", 1.0, 0.8)

func stop_prompt_animation():
	if prompt_tween:
		prompt_tween.kill()
		prompt_tween = null
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.modulate.a = 1.0

func sleep_interaction():
	print("[BedInteraction] Iniciando interação de dormir")
	
	interaction_active = true
	hide_interaction_prompt()
	
	# NÃO pausa o jogador aqui - deixa o SceneManager gerenciar isso
	print("[BedInteraction] Player não pausado - SceneManager irá gerenciar")
	
	# Cria efeito de fade out e troca apenas o hub
	create_sleep_transition()

func create_sleep_transition():
	print("[BedInteraction] Criando transição de sono com preservação do player")
	
	# Usa o SceneManager para trocar apenas o hub mantendo o player
	if SceneManager and SceneManager.has_method("change_hub_with_fade"):
		print("[BedInteraction] Usando SceneManager para trocar hub")
		
		# Chama de forma assíncrona para evitar travamentos
		call_deferred("_start_hub_change")
	else:
		print("[BedInteraction] AVISO: SceneManager não disponível, usando método alternativo")
		# Fallback para o método tradicional
		get_tree().change_scene_to_file("res://map_2.tscn")

func _start_hub_change():
	"""
	Inicia a mudança de hub de forma diferida
	"""
	print("[BedInteraction] Iniciando mudança de hub diferida")
	print("[BedInteraction] Estado atual - Jogo pausado: ", get_tree().paused)
	print("[BedInteraction] SceneManager válido: ", SceneManager != null)
	
	if SceneManager:
		print("[BedInteraction] Chamando SceneManager.change_hub_with_fade...")
		SceneManager.change_hub_with_fade("map_2", 2.0)
		print("[BedInteraction] Chamada para change_hub_with_fade concluída")
	else:
		print("[BedInteraction] ERRO: SceneManager é null!")
		interaction_active = false

func emergency_unlock():
	"""
	Função de emergência para destravar o jogo
	"""
	print("[BedInteraction] Executando destravamento de emergência")
	interaction_active = false
	get_tree().paused = false
	
	# Reativa o player se existir
	if player_ref and is_instance_valid(player_ref):
		player_ref.set_physics_process(true)
		player_ref.set_process_input(true)
		print("[BedInteraction] Player reativado")
	
	# Mostra a HUD
	if ui_manager and ui_manager.has_method("show_ui"):
		ui_manager.show_ui("hud")
	
	print("[BedInteraction] Destravamento de emergência concluído")

 
