extends Node

# Gerenciador de Efeitos PSX para Nightmare Loop
# Aplica configurações visuais que simulam jogos de PlayStation 1

# Configurações PSX FORTES (padrão)
@export var enable_psx_mode: bool = true  # ATIVADO POR PADRÃO
@export var psx_render_scale: float = 0.5
@export var color_depth_reduction: bool = true
@export var texture_filtering: bool = false

# Configurações FORTES para efeito mais visível
@export var strong_dithering: bool = true
@export var reduced_colors: bool = true
@export var enhanced_fog: bool = true

# Referências
var main_viewport: Viewport
var current_environment: Environment
var original_environment: Environment
var psx_screen_effect: CanvasLayer = null

# Cena do efeito PSX
var psx_screen_effect_scene = preload("res://scenes/effects/PSXScreenEffect.tscn")

func _ready():
	print("🎮 PSX Effect Manager inicializado!")
	print("📺 MODO PSX ATIVADO POR PADRÃO (configuração FORTE)")
	
	# Obtém referências
	main_viewport = get_viewport()
	
	# Aguarda um frame para garantir que a cena está carregada
	await get_tree().process_frame
	
	# SEMPRE aplica efeitos PSX (padrão ativado)
	apply_psx_effects()
	
	# Debug dos controles
	print("📺 Controles PSX:")
	print("  F1 - Toggle PSX Mode")
	print("  F2 - Preset Clássico")
	print("  F3 - Preset Horror FORTE")
	print("  F4 - Preset Nightmare")
	print("  F5 - Debug Camera Info")
	print("  F6 - Toggle Screen Effect")

func apply_psx_effects():
	print("🎮 Aplicando efeitos PSX...")
	
	# 1. Configurações de renderização
	apply_render_settings()
	
	# 2. Configurações de ambiente
	apply_psx_environment()
	
	# 3. Configurações de projeto
	apply_project_settings()
	
	# 4. Aplica efeito de tela PSX
	apply_screen_effect()
	
	print("✅ Efeitos PSX aplicados!")

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

func apply_screen_effect():
	"""Aplica o efeito PSX de tela completa com configurações FORTES"""
	if not psx_screen_effect and psx_screen_effect_scene:
		# Instancia o efeito de tela
		psx_screen_effect = psx_screen_effect_scene.instantiate()
		
		# Configura parâmetros FORTES
		if psx_screen_effect.has_method("setup_strong_psx"):
			psx_screen_effect.setup_strong_psx()
		
		# Adiciona à cena atual
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.add_child(psx_screen_effect)
			
			# Aplica configurações FORTES imediatamente
			apply_strong_psx_settings()
			
			print("🎬 PSX Screen Effect FORTE adicionado à cena!")
		else:
			print("⚠️ Não foi possível adicionar PSX Screen Effect - cena não encontrada")

func apply_strong_psx_settings():
	"""Aplica configurações PSX FORTES ao screen effect"""
	if psx_screen_effect and is_instance_valid(psx_screen_effect):
		# Configurações FORTES
		if psx_screen_effect.has_method("set_color_levels"):
			psx_screen_effect.set_color_levels(10)  # Bem reduzido (era 24)
		
		if psx_screen_effect.has_method("set_dither_strength"):
			psx_screen_effect.set_dither_strength(0.75)  # Muito dithering (era 0.4)
		
		# Aplica preset horror forte por padrão
		if psx_screen_effect.has_method("apply_horror_psx_preset"):
			psx_screen_effect.apply_horror_psx_preset()
		
		print("🎨 Configurações PSX FORTES aplicadas!")

func remove_screen_effect():
	"""Remove o efeito PSX de tela"""
	if psx_screen_effect and is_instance_valid(psx_screen_effect):
		psx_screen_effect.queue_free()
		psx_screen_effect = null
		print("🎬 PSX Screen Effect removido!")

func toggle_screen_effect():
	"""Liga/desliga o efeito de tela PSX"""
	if psx_screen_effect and is_instance_valid(psx_screen_effect):
		if psx_screen_effect.visible:
			psx_screen_effect.hide_effect()
		else:
			psx_screen_effect.show_effect()
	else:
		apply_screen_effect()

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
	
	# Remove efeito de tela
	remove_screen_effect()
	
	# Restaura resolução original
	var screen_size = DisplayServer.screen_get_size()
	if main_viewport:
		main_viewport.set_size(screen_size)
	
	print("🔄 Efeitos PSX desabilitados")

# Presets atualizados com configurações FORTES
func apply_classic_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.2, 0.2, 0.4)  # Mais escuro
		env.fog_density = 0.012  # Mais denso
		env.adjustment_brightness = 0.85  # Mais escuro
		env.adjustment_contrast = 1.2
		env.adjustment_saturation = 0.7  # Menos saturado
	
	# Aplica ao screen effect também
	if psx_screen_effect and psx_screen_effect.has_method("apply_classic_psx_preset"):
		psx_screen_effect.apply_classic_psx_preset()
	
	print("🎮 Preset PSX Clássico FORTE aplicado!")

func apply_horror_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.25, 0.1, 0.1)  # Vermelho mais forte
		env.fog_density = 0.02  # Muito denso
		env.adjustment_brightness = 0.6  # Bem escuro
		env.adjustment_contrast = 1.6  # Alto contraste
		env.adjustment_saturation = 0.5  # Pouca saturação
	
	# Aplica ao screen effect também
	if psx_screen_effect and psx_screen_effect.has_method("apply_horror_psx_preset"):
		psx_screen_effect.apply_horror_psx_preset()
	
	print("🎮 Preset PSX Horror FORTE aplicado!")

func apply_nightmare_psx_preset():
	var env = current_environment
	if env:
		env.fog_light_color = Color(0.15, 0.05, 0.25)  # Roxo mais forte
		env.fog_density = 0.025  # Extremamente denso
		env.adjustment_brightness = 0.5  # Muito escuro
		env.adjustment_contrast = 1.8  # Contraste extremo
		env.adjustment_saturation = 0.3  # Muito pouca saturação
	
	# Aplica ao screen effect também
	if psx_screen_effect and psx_screen_effect.has_method("apply_nightmare_psx_preset"):
		psx_screen_effect.apply_nightmare_psx_preset()
	
	print("🎮 Preset PSX Nightmare FORTE aplicado!")

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
				toggle_screen_effect()

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
