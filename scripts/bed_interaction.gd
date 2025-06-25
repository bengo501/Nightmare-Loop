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
	
	# Pausa o jogador
	if player_ref:
		player_ref.set_physics_process(false)
		player_ref.set_process_input(false)
	
	# Esconde a HUD
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = false
	
	# Cria efeito de fade out
	create_sleep_transition()

func create_sleep_transition():
	print("[BedInteraction] Criando transição de sono")
	
	# Usa o SceneManager para fazer a transição com fade
	if scene_manager:
		print("[BedInteraction] Usando SceneManager para transição com fade")
		await scene_manager.change_scene_with_fade("map_2", 2.0)
	else:
		print("[BedInteraction] ERRO: SceneManager não disponível, criando fade manual")
		# Fallback para fade manual
		var fade_overlay = ColorRect.new()
		fade_overlay.name = "SleepFadeOverlay"
		fade_overlay.anchors_preset = Control.PRESET_FULL_RECT
		fade_overlay.color = Color(0, 0, 0, 0)
		fade_overlay.z_index = 1000
		
		# Adiciona à cena
		get_tree().current_scene.add_child(fade_overlay)
		
		# Animação de fade out
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 2.0)
		
		await tween.finished
		
		# Carregamento direto
		get_tree().change_scene_to_file("res://map_2.tscn")

 