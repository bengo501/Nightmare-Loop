extends Node3D

# Referência para controlar a introdução do estágio
var intro_shown = false
var stage1_dialog_shown = false

# Referência ao WorldEnvironment
@onready var world_environment = $WorldEnvironment

func _ready():
	print("[Map2Controller] Inicializando controlador do Map 2")
	
	# Configura a atmosfera esverdeada
	setup_green_atmosphere()
	
	# Aguarda alguns frames para garantir que tudo foi carregado
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("[Map2Controller] Frames aguardados, verificando intro_shown: ", intro_shown)
	
	# Mostra a introdução do estágio se ainda não foi mostrada
	if not intro_shown:
		print("[Map2Controller] Chamando show_stage_intro()")
		show_stage_intro()
	else:
		print("[Map2Controller] Introdução já foi mostrada, pulando")

func setup_green_atmosphere():
	"""
	Configura a atmosfera esverdeada, fog e depth of field
	"""
	print("[Map2Controller] Configurando atmosfera esverdeada")
	
	if world_environment and world_environment.environment:
		var env = world_environment.environment
		print("[Map2Controller] Environment encontrado, aplicando configurações esverdeadas")
		
		# Força aplicação das configurações do ambiente
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.05, 0.15, 0.05, 1)
		
		# Luz ambiente esverdeada
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.1, 0.3, 0.1, 1)
		env.ambient_light_energy = 0.3
		
		# Fog verde
		env.fog_enabled = true
		env.fog_light_color = Color(0.2, 0.6, 0.2, 1)
		env.fog_light_energy = 1.2
		env.fog_density = 0.15
		
		# Volumetric fog esverdeado
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.08
		env.volumetric_fog_albedo = Color(0.15, 0.4, 0.15, 1)
		env.volumetric_fog_emission = Color(0.05, 0.2, 0.05, 1)
		
		# Glow esverdeado
		env.glow_enabled = true
		env.glow_intensity = 0.4
		env.glow_strength = 0.8
		
		# Ajustes de cor para atmosfera sombria
		env.adjustment_enabled = true
		env.adjustment_brightness = 0.9
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 0.8
		
		print("[Map2Controller] Atmosfera esverdeada configurada com sucesso!")
	else:
		print("[Map2Controller] AVISO: WorldEnvironment não encontrado!")
	
	# Configura Depth of Field na câmera do player
	setup_camera_dof()

func setup_camera_dof():
	"""
	Configura Depth of Field na câmera do player (Godot 4)
	"""
	print("[Map2Controller] Configurando Depth of Field na câmera do player")
	
	# Aguarda alguns frames para garantir que o player foi carregado
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Procura pelo player na cena
	var player = find_player_in_scene()
	if player:
		# Procura pela câmera dentro do player
		var camera = find_camera_in_player(player)
		if camera:
			print("[Map2Controller] Câmera encontrada, aplicando Depth of Field")
			
			# Configura DOF na câmera (Godot 4)
			var camera_attrs = CameraAttributesPractical.new()
			camera_attrs.dof_blur_far_enabled = true
			camera_attrs.dof_blur_far_distance = 20.0
			camera_attrs.dof_blur_far_transition = 8.0
			camera_attrs.dof_blur_near_enabled = true
			camera_attrs.dof_blur_near_distance = 2.0
			camera_attrs.dof_blur_near_transition = 1.5
			
			camera.attributes = camera_attrs
			
			print("[Map2Controller] Depth of Field configurado com sucesso!")
		else:
			print("[Map2Controller] AVISO: Câmera não encontrada no player")
	else:
		print("[Map2Controller] AVISO: Player não encontrado para configurar DOF")

func find_player_in_scene() -> Node:
	"""
	Procura pelo player na cena atual
	"""
	var scene_root = get_tree().current_scene
	if not scene_root:
		return null
	
	# Procura por diferentes nomes possíveis do player
	var player = find_node_by_name(scene_root, "Player")
	if not player:
		player = find_node_by_name(scene_root, "player")
	if not player:
		player = find_node_by_name(scene_root, "PlayerCharacter")
	
	return player

func find_camera_in_player(player: Node) -> Camera3D:
	"""
	Procura pela câmera dentro do nó do player
	"""
	if not player:
		return null
	
	# Procura recursivamente por uma Camera3D
	return find_camera_recursive(player)

func find_camera_recursive(node: Node) -> Camera3D:
	"""
	Busca recursivamente por uma Camera3D
	"""
	if node is Camera3D:
		return node as Camera3D
	
	for child in node.get_children():
		var camera = find_camera_recursive(child)
		if camera:
			return camera
	
	return null

func find_node_by_name(parent: Node, node_name: String) -> Node:
	"""
	Busca recursivamente por um nodo com o nome especificado
	"""
	if parent.name == node_name:
		return parent
	
	for child in parent.get_children():
		var result = find_node_by_name(child, node_name)
		if result:
			return result
	
	return null

func show_stage_intro():
	"""
	Mostra a introdução do Estágio 1
	"""
	print("[Map2Controller] show_stage_intro() iniciado")
	
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		print("[Map2Controller] UIManager encontrado")
		intro_shown = true
		print("[Map2Controller] Chamando ui_manager.show_stage_intro('estagio1')")
		ui_manager.show_stage_intro("estagio1")
		
		# Conecta ao sinal de conclusão usando call_deferred
		call_deferred("_connect_to_intro_signal")
	else:
		print("[Map2Controller] ERRO: UIManager não encontrado")

func _connect_to_intro_signal():
	"""
	Conecta ao sinal da introdução após ela ser criada
	"""
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.stage_intro_instance and is_instance_valid(ui_manager.stage_intro_instance) and not ui_manager.stage_intro_instance.is_queued_for_deletion():
		if ui_manager.stage_intro_instance.has_signal("intro_finished"):
			# Verifica se já não está conectado para evitar duplicação
			if not ui_manager.stage_intro_instance.is_connected("intro_finished", _on_intro_finished):
				ui_manager.stage_intro_instance.connect("intro_finished", _on_intro_finished)
				print("[Map2Controller] Conectado ao sinal intro_finished")
		else:
			print("[Map2Controller] AVISO: Sinal intro_finished não encontrado")
		
		# TESTE: Chama função de teste para verificar se funciona
		print("[Map2Controller] Chamando função de teste...")
		if ui_manager.stage_intro_instance.has_method("test_intro"):
			ui_manager.stage_intro_instance.test_intro()
		else:
			print("[Map2Controller] ERRO: Método test_intro não encontrado")
	else:
		print("[Map2Controller] AVISO: stage_intro_instance não disponível para conexão")

func _on_intro_finished():
	"""
	Chamado quando a introdução do estágio termina
	"""
	print("[Map2Controller] Introdução do estágio concluída")
	
	# Inicia o diálogo entre os três personagens após a intro
	print("[Map2Controller] Iniciando diálogo do estágio 1...")
	call_deferred("start_stage1_dialog")

func start_stage1_dialog():
	"""
	Inicia o diálogo entre Protagonista, Gregor e William após a introdução
	"""
	print("[Map2Controller] start_stage1_dialog() iniciado")
	
	# Verifica se o diálogo já foi mostrado para evitar duplicação
	if stage1_dialog_shown:
		print("[Map2Controller] Diálogo do estágio 1 já foi mostrado, pulando")
		return
	
	stage1_dialog_shown = true
	
	# Referência ao sistema de diálogo
	var dialog_system_scene = preload("res://scenes/ui/dialog_system.tscn")
	
	# Procura pelo player para pausar
	var player = find_player_in_scene()
	if player:
		print("[Map2Controller] Pausando jogador para diálogo...")
		player.set_physics_process(false)
		player.set_process_input(false)
	else:
		print("[Map2Controller] AVISO: Player não encontrado para pausar")
	
	# Esconde a HUD principal
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = false
		print("[Map2Controller] HUD escondida para diálogo")
	else:
		print("[Map2Controller] AVISO: HUD não encontrada ou inválida")
	
	print("[Map2Controller] Criando instância do sistema de diálogo...")
	# Cria e mostra o sistema de diálogo
	var dialog_instance = dialog_system_scene.instantiate()
	if not dialog_instance:
		print("[Map2Controller] ERRO: Falha ao instanciar sistema de diálogo!")
		return
	
	print("[Map2Controller] Adicionando sistema de diálogo à cena...")
	get_tree().current_scene.add_child(dialog_instance)
	
	print("[Map2Controller] Conectando sinal de fim do diálogo...")
	# Conecta o sinal de fim do diálogo
	dialog_instance.connect("dialog_sequence_finished", _on_stage1_dialog_finished)
	
	print("[Map2Controller] Pausando jogo...")
	# Pausa o jogo ANTES de iniciar o diálogo
	get_tree().paused = true
	
	print("[Map2Controller] Iniciando diálogos do estágio 1...")
	# Inicia os diálogos do estágio 1
	dialog_instance.start_stage1_dialog()
	
	print("[Map2Controller] Liberando cursor...")
	# Libera o cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	print("[Map2Controller] Diálogo do estágio 1 iniciado com sucesso!")

func _on_stage1_dialog_finished():
	"""
	Chamado quando o diálogo do estágio 1 termina
	"""
	print("[Map2Controller] Diálogo do estágio 1 finalizado")
	
	# Despausa o jogo
	get_tree().paused = false
	
	# Reativa o player
	var player = find_player_in_scene()
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
		print("[Map2Controller] Player reativado após diálogo")
	
	# Mostra a HUD novamente
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.hud_instance and is_instance_valid(ui_manager.hud_instance):
		ui_manager.hud_instance.visible = true
		print("[Map2Controller] HUD reexibida após diálogo")
	
	# Retorna o cursor ao modo capturado (se necessário)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	print("[Map2Controller] Jogo retomado após diálogo do estágio 1") 
