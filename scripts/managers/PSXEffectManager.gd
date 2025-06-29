extends Node

# Gerenciador de Efeitos PSX para Nightmare Loop
# Aplica configurações visuais que simulam jogos de PlayStation 1

# Configurações PSX
@export var enable_psx_mode: bool = true  # Ativado por padrão
@export var psx_render_scale: float = 0.5  # Reduz resolução para efeito pixelado
@export var color_depth_reduction: bool = true
@export var texture_filtering: bool = false  # Desabilita filtro para pixels nítidos

# Referências
var main_viewport: Viewport
var current_environment: Environment
var original_environment: Environment
var psx_crt_effect: Control = null

# Cena do efeito PSX + CRT (única que será usada)
var psx_crt_effect_scene = preload("res://scenes/effects/PSXWithCRT.tscn")

func _ready():
	print("🎮 PSX Effect Manager inicializado!")
	
	# Obtém referências
	main_viewport = get_viewport()
	
	# Aguarda um frame para garantir que a cena está carregada
	await get_tree().process_frame
	
	# Aplica efeitos PSX + CRT por padrão
	print("📺 Aplicando PSX + CRT por padrão...")
	apply_psx_effects()
	
	# Debug dos controles
	print("📺 Controles PSX + CRT:")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset PSX Clássico")
	print("  F3 - Preset PSX Horror")
	print("  F4 - Preset PSX Nightmare")
	print("  F5 - Debug Camera Info")
	print("  F6 - Toggle CRT Effects")
	print("  F7 - CRT Vintage")
	print("  F8 - CRT Modern")
	print("  F9 - CRT Strong")

func apply_psx_effects():
	print("🎮 Aplicando efeitos PSX + CRT...")
	
	# 1. Configurações de renderização
	apply_render_settings()
	
	# 2. Configurações de ambiente
	apply_psx_environment()
	
	# 3. Configurações de projeto
	apply_project_settings()
	
	# 4. Aplica APENAS o efeito PSX + CRT (que inclui tudo)
	apply_psx_crt_effect()
	
	print("✅ Efeitos PSX + CRT aplicados por padrão!")

func apply_render_settings():
	if main_viewport:
		# Configurações de renderização PSX
		main_viewport.snap_2d_transforms_to_pixel = true
		main_viewport.snap_2d_vertices_to_pixel = true
		
		# Reduz a resolução para efeito pixelado
		if psx_render_scale < 1.0:
			var original_size = main_viewport.get_visible_rect().size
			var new_size = original_size * psx_render_scale
			main_viewport.set_size(new_size)
			print("📺 Resolução reduzida para: ", new_size)

func apply_psx_environment():
	# Usa a função robusta para encontrar e aplicar PSX às câmeras
	var success = find_and_apply_to_cameras()
	
	if success:
		print("🌫️ Environment PSX aplicado com sucesso!")
	else:
		print("⚠️ Falha ao aplicar Environment PSX - tentando novamente em 1 segundo...")
		# Tenta novamente após 1 segundo (caso as câmeras ainda não estejam prontas)
		await get_tree().create_timer(1.0).timeout
		find_and_apply_to_cameras()

func apply_project_settings():
	# Configurações de projeto para efeito PSX
	if not texture_filtering:
		# Desabilita filtro de textura para pixels nítidos
		print("🔲 Filtros de textura desabilitados")
	
	# Outras configurações podem ser adicionadas aqui

func toggle_psx_mode():
	enable_psx_mode = !enable_psx_mode
	
	if enable_psx_mode:
		apply_psx_effects()
		print("🎮 PSX Mode: ATIVADO")
	else:
		disable_psx_effects()
		print("🎮 PSX Mode: DESATIVADO")

func disable_psx_effects():
	# Restaura environment original em todas as câmeras
	if original_environment:
		var cameras_found = []
		
		# 1. Câmera do viewport principal
		if main_viewport:
			var main_camera = main_viewport.get_camera_3d()
			if main_camera:
				cameras_found.append(main_camera)
		
		# 2. Câmeras na cena atual
		var current_scene = get_tree().current_scene
		if current_scene:
			_find_cameras(current_scene, cameras_found)
		
		# 3. Câmeras do player
		var player_group = get_tree().get_nodes_in_group("player")
		for player in player_group:
			_find_cameras(player, cameras_found)
		
		# 4. Restaura environment original em todas
		var restored_count = 0
		for camera in cameras_found:
			if camera is Camera3D and is_instance_valid(camera):
				camera.environment = original_environment
				restored_count += 1
		
		print("🔄 Environment original restaurado em ", restored_count, " câmeras")
	else:
		print("⚠️ Nenhum environment original salvo para restaurar")
	
	# Remove efeito PSX + CRT
	remove_psx_crt_effect()
	
	# Restaura resolução original
	var screen_size = DisplayServer.screen_get_size()
	if main_viewport:
		main_viewport.set_size(screen_size)
	
	print("🔄 Efeitos PSX desabilitados")

# Presets de configuração
func apply_classic_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.3, 0.3, 0.5)
		env.fog_density = 0.008
		env.adjustment_brightness = 0.9
		env.adjustment_contrast = 1.1
		env.adjustment_saturation = 0.8
		print("🎮 Preset PSX Clássico aplicado!")

func apply_horror_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.2, 0.1, 0.1)
		env.fog_density = 0.015
		env.adjustment_brightness = 0.7
		env.adjustment_contrast = 1.4
		env.adjustment_saturation = 0.6
		print("🎮 Preset PSX Horror aplicado!")

func apply_nightmare_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.1, 0.05, 0.2)
		env.fog_density = 0.02
		env.adjustment_brightness = 0.6
		env.adjustment_contrast = 1.6
		env.adjustment_saturation = 0.4
		print("🎮 Preset PSX Nightmare aplicado!")

# Input para controles em tempo real
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				toggle_psx_mode()
			KEY_F2:
				apply_classic_psx_preset()
			KEY_F3:
				apply_horror_psx_preset()
			KEY_F4:
				apply_nightmare_psx_preset()
			KEY_F5:
				debug_camera_info()
			KEY_F6:
				toggle_psx_crt_effect()
			KEY_F7:
				apply_crt_vintage_preset()
			KEY_F8:
				apply_crt_modern_preset()
			KEY_F9:
				apply_crt_strong_preset()

func debug_camera_info():
	"""Debug: Lista todas as câmeras encontradas no jogo"""
	print("========================================")
	print("🔍 DEBUG - INFORMAÇÕES DAS CÂMERAS")
	print("========================================")
	
	var cameras_found = []
	
	# 1. Câmera do viewport principal
	print("📺 Viewport Principal:")
	if main_viewport:
		var main_camera = main_viewport.get_camera_3d()
		if main_camera:
			cameras_found.append(main_camera)
			print("  ✅ Câmera encontrada: ", main_camera.name)
			print("  📍 Environment: ", main_camera.environment)
		else:
			print("  ❌ Nenhuma câmera no viewport principal")
	else:
		print("  ❌ Viewport principal não encontrado")
	
	# 2. Câmeras na cena atual
	print("🎬 Cena Atual:")
	var current_scene = get_tree().current_scene
	if current_scene:
		print("  📁 Cena: ", current_scene.name)
		var scene_cameras = []
		_find_cameras(current_scene, scene_cameras)
		for camera in scene_cameras:
			if camera not in cameras_found:
				cameras_found.append(camera)
			print("  📷 Câmera: ", camera.name, " | Environment: ", camera.environment)
	else:
		print("  ❌ Nenhuma cena atual")
	
	# 3. Câmeras do player
	print("🎮 Player:")
	var player_group = get_tree().get_nodes_in_group("player")
	if player_group.size() > 0:
		for player in player_group:
			print("  👤 Player: ", player.name)
			var player_cameras = []
			_find_cameras(player, player_cameras)
			for camera in player_cameras:
				if camera not in cameras_found:
					cameras_found.append(camera)
				print("    📷 Câmera: ", camera.name, " | Environment: ", camera.environment)
	else:
		print("  ❌ Nenhum player encontrado")
	
	print("========================================")
	print("📊 RESUMO:")
	print("  Total de câmeras: ", cameras_found.size())
	print("  Environment original salvo: ", original_environment != null)
	print("  Environment atual: ", current_environment)
	print("  PSX Mode ativo: ", enable_psx_mode)
	print("========================================")

# Função para aplicar efeitos PSX a uma cena específica
func apply_psx_to_scene(scene_node: Node):
	if not scene_node:
		return
	
	# Procura por câmeras na cena
	var cameras = []
	_find_cameras(scene_node, cameras)
	
	# Aplica environment PSX a todas as câmeras
	var psx_env = load("res://environments/psx_environment.tres")
	for camera in cameras:
		if camera is Camera3D:
			camera.environment = psx_env
			print("📷 PSX aplicado à câmera: ", camera.name)

func _find_cameras(node: Node, camera_list: Array):
	if node is Camera3D:
		camera_list.append(node)
	
	for child in node.get_children():
		_find_cameras(child, camera_list)

func find_and_apply_to_cameras():
	"""Encontra todas as câmeras ativas no jogo e aplica PSX"""
	var cameras_found = []
	var psx_env = load("res://environments/psx_environment.tres")
	
	# 1. Tenta câmera do viewport principal
	if main_viewport:
		var main_camera = main_viewport.get_camera_3d()
		if main_camera:
			cameras_found.append(main_camera)
	
	# 2. Procura câmeras na cena atual
	var current_scene = get_tree().current_scene
	if current_scene:
		_find_cameras(current_scene, cameras_found)
	
	# 3. Procura por player e suas câmeras
	var player_group = get_tree().get_nodes_in_group("player")
	for player in player_group:
		_find_cameras(player, cameras_found)
	
	# 4. Aplica PSX a todas as câmeras encontradas
	var applied_count = 0
	for camera in cameras_found:
		if camera is Camera3D and is_instance_valid(camera):
			# Salva environment original se não foi salvo ainda
			if not original_environment and camera.environment:
				original_environment = camera.environment
			
			# Aplica PSX
			camera.environment = psx_env
			current_environment = psx_env
			applied_count += 1
			print("📷 PSX aplicado à câmera: ", camera.name)
	
	if applied_count > 0:
		print("✅ PSX aplicado a ", applied_count, " câmeras")
	else:
		print("⚠️ Nenhuma câmera encontrada para aplicar PSX")
	
	return applied_count > 0 

func apply_psx_crt_effect():
	"""Aplica o efeito PSX + CRT que afeta jogo + UI"""
	if not psx_crt_effect and psx_crt_effect_scene:
		# Instancia o efeito PSX + CRT
		psx_crt_effect = psx_crt_effect_scene.instantiate()
		
		# Adiciona à árvore principal (substitui a cena atual)
		get_tree().root.add_child(psx_crt_effect)
		
		print("🎬 PSX + CRT Effect aplicado! (afeta jogo + UI)")
	else:
		print("⚠️ PSX + CRT Effect já ativo ou cena não encontrada")

func remove_psx_crt_effect():
	"""Remove o efeito PSX + CRT"""
	if psx_crt_effect and is_instance_valid(psx_crt_effect):
		psx_crt_effect.queue_free()
		psx_crt_effect = null
		print("🎬 PSX + CRT Effect removido!")

func toggle_psx_crt_effect():
	"""Liga/desliga o efeito PSX + CRT"""
	if psx_crt_effect and is_instance_valid(psx_crt_effect):
		if psx_crt_effect.visible:
			psx_crt_effect.visible = false
		else:
			psx_crt_effect.visible = true
	else:
		apply_psx_crt_effect()

func apply_crt_vintage_preset():
	"""Aplica preset CRT vintage via PSXWithCRT"""
	if psx_crt_effect and psx_crt_effect.has_method("apply_vintage_crt_preset"):
		psx_crt_effect.apply_vintage_crt_preset()
	else:
		print("⚠️ PSX+CRT Effect não encontrado para aplicar preset CRT Vintage")

func apply_crt_modern_preset():
	"""Aplica preset CRT moderno via PSXWithCRT"""
	if psx_crt_effect and psx_crt_effect.has_method("apply_modern_crt_preset"):
		psx_crt_effect.apply_modern_crt_preset()
	else:
		print("⚠️ PSX+CRT Effect não encontrado para aplicar preset CRT Moderno")

func apply_crt_strong_preset():
	"""Aplica preset CRT forte via PSXWithCRT"""
	if psx_crt_effect and psx_crt_effect.has_method("apply_strong_crt_preset"):
		psx_crt_effect.apply_strong_crt_preset()
	else:
		print("⚠️ PSX+CRT Effect não encontrado para aplicar preset CRT Forte") 
