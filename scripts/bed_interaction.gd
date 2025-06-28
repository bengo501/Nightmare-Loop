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

# Variáveis removidas para simplificar

func _ready():
	print("[BedInteraction] 🛏️ Inicializando sistema de interação com a cama")
	
	# Conecta os sinais da área de interação
	if area_3d:
		area_3d.body_entered.connect(_on_body_entered)
		area_3d.body_exited.connect(_on_body_exited)
		print("[BedInteraction] ✅ Sinais da Area3D conectados")
		
		# Configura a Area3D
		area_3d.collision_layer = 0
		area_3d.collision_mask = 2  # Detecta player (layer 2)
		area_3d.monitoring = true
		area_3d.monitorable = false
		
		print("[BedInteraction] 📡 Area3D configurada - Layer: 0, Mask: 2")
	else:
		print("[BedInteraction] ❌ ERRO: Area3D não encontrada!")
	
	# Esconde o prompt inicialmente
	if interaction_prompt:
		interaction_prompt.visible = false
		print("[BedInteraction] 💬 Prompt de interação configurado")
	else:
		print("[BedInteraction] ⚠️ AVISO: Prompt de interação não encontrado")

func _on_body_entered(body):
	print("[BedInteraction] 👤 Corpo entrou na área: ", body.name)
	print("[BedInteraction] 🏷️ Grupos do corpo: ", body.get_groups())
	
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		show_interaction_prompt()
		print("[BedInteraction] ✅ JOGADOR DETECTADO! Prompt ativado.")

func _on_body_exited(body):
	print("[BedInteraction] 👤 Corpo saiu da área: ", body.name)
	
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		hide_interaction_prompt()
		print("[BedInteraction] 👋 Jogador saiu da área da cama")

func _input(event):
	if player_inside and Input.is_action_just_pressed("interact") and not interaction_active:
		print("[BedInteraction] ⚡ TECLA E PRESSIONADA! Iniciando transição...")
		sleep_interaction()

func show_interaction_prompt():
	print("[BedInteraction] 💬 Mostrando prompt de interação")
	if interaction_prompt and is_instance_valid(interaction_prompt):
		interaction_prompt.visible = true
		start_prompt_animation()

func hide_interaction_prompt():
	print("[BedInteraction] 🙈 Escondendo prompt de interação")
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
	print("[BedInteraction] 🌙 Iniciando transição para map_2...")
	
	interaction_active = true
	hide_interaction_prompt()
	
	# Salva a posição atual do player para referência
	var current_player = get_tree().get_first_node_in_group("player")
	if not current_player:
		print("[BedInteraction] ❌ Player não encontrado!")
		interaction_active = false
		return
	
	print("[BedInteraction] 👤 Player encontrado: ", current_player.name)
	
	# Preserva referências importantes do player
	var player_scene_path = current_player.scene_file_path
	if player_scene_path == "":
		player_scene_path = "res://scenes/player/player.tscn"
	
	print("[BedInteraction] 💾 Player scene path: ", player_scene_path)
	
	# Cria um autoload temporário para gerenciar a transição
	_create_transition_manager(player_scene_path)
	
	# Muda para a nova cena
	var result = get_tree().change_scene_to_file("res://map_2.tscn")
	if result != OK:
		print("[BedInteraction] ❌ Erro ao mudar cena: ", result)
		interaction_active = false
		return
	
	print("[BedInteraction] 🎉 TRANSIÇÃO INICIADA!")

func _create_transition_manager(player_scene_path: String):
	# Cria um nó temporário que sobrevive à mudança de cena
	var transition_manager = Node.new()
	transition_manager.name = "TransitionManager"
	transition_manager.set_script(preload("res://scripts/transition_manager.gd"))
	
	# Adiciona ao root para que sobreviva à mudança de cena
	get_tree().root.add_child(transition_manager)
	transition_manager.setup_player_transition(player_scene_path)

# Função removida - agora usa TransitionManager

func _find_spawn_point(scene: Node) -> Node3D:
	"""
	Procura recursivamente por um ponto de spawn na cena
	"""
	# Procura por nomes comuns de spawn points
	var spawn_names = ["PontoNascimento", "SpawnPoint", "PlayerSpawn", "Spawn"]
	
	for spawn_name in spawn_names:
		var spawn_point = _find_node_by_name(scene, spawn_name)
		if spawn_point and spawn_point is Node3D:
			return spawn_point
	
	return null

func _find_node_by_name(parent: Node, node_name: String) -> Node:
	"""
	Busca recursivamente por um nó com o nome especificado
	"""
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = _find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

# Funções removidas para simplificar o script

	
