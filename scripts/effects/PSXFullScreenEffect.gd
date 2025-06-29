extends Control

# Efeito PSX de Tela Completa que afeta jogo + UIs
# Captura toda a tela e aplica shader PSX sobre tudo

# Referências
@onready var viewport_container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var game_content = $SubViewportContainer/SubViewport/GameContent
@onready var psx_overlay = $PSXOverlay
@onready var psx_quad = $PSXOverlay/PSXQuad
@onready var psx_camera = $PSXOverlay/PSXCamera

# Material do shader
var psx_material: ShaderMaterial

# Configurações PSX
@export var enable_psx_effects: bool = true
@export var fog_color: Color = Color(0.3, 0.3, 0.5)
@export var noise_color: Color = Color(0.1, 0.1, 0.3)
@export var fog_distance: float = 100.0
@export var fog_fade_range: float = 50.0
@export var enable_noise: bool = true
@export var noise_time_factor: float = 3.0
@export var enable_color_limitation: bool = true
@export var color_levels: int = 16
@export var enable_dithering: bool = true
@export var dither_strength: float = 0.5

# Referência ao conteúdo original
var original_parent: Node = null
var original_content: Array = []

func _ready():
	print("🎮 PSX Full Screen Effect inicializado!")
	
	# Configura o viewport
	setup_viewport()
	
	# Move o conteúdo atual para o viewport
	move_content_to_viewport()
	
	# Configura o material PSX
	setup_psx_material()
	
	# Aplica preset padrão
	apply_classic_psx_preset()
	
	print("📺 PSX Full Screen Effect ativo! (afeta jogo + UI)")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset Clássico")
	print("  F3 - Preset Horror")
	print("  F4 - Preset Nightmare")

func setup_viewport():
	"""Configura o viewport para capturar tudo"""
	if viewport:
		# Configura o tamanho do viewport
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		
		# Configurações de renderização
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		
		print("📺 Viewport PSX configurado: ", viewport.size)

func move_content_to_viewport():
	"""Move todo o conteúdo da cena principal para o viewport PSX"""
	var main_scene = get_tree().current_scene
	if not main_scene or main_scene == self:
		return
	
	original_parent = main_scene.get_parent()
	
	# Salva referência do conteúdo original
	for child in main_scene.get_children():
		original_content.append(child)
	
	# Move o conteúdo para o viewport
	if game_content:
		# Remove a cena principal de seu pai
		if original_parent:
			original_parent.remove_child(main_scene)
		
		# Adiciona ao viewport
		game_content.add_child(main_scene)
		
		print("🎬 Conteúdo movido para viewport PSX")

func restore_original_content():
	"""Restaura o conteúdo original fora do viewport"""
	var main_scene = get_tree().current_scene
	if game_content and main_scene and main_scene.get_parent() == game_content:
		# Remove do viewport
		game_content.remove_child(main_scene)
		
		# Restaura ao pai original
		if original_parent:
			original_parent.add_child(main_scene)
		
		print("🎬 Conteúdo restaurado do viewport PSX")

func setup_psx_material():
	"""Configura o material do shader PSX"""
	if psx_quad:
		psx_material = psx_quad.get_surface_override_material(0)
		if psx_material:
			# Configura a textura do viewport
			setup_viewport_texture()
			update_shader_parameters()
			print("🎨 Material PSX Full Screen configurado!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado!")

func setup_viewport_texture():
	"""Configura a textura do viewport para o shader"""
	if not psx_material or not viewport:
		return
	
	# Aguarda um frame para garantir que o viewport está pronto
	await get_tree().process_frame
	
	# Define a textura do viewport para o shader
	var screen_texture = viewport.get_texture()
	if screen_texture:
		psx_material.set_shader_parameter("screen_texture", screen_texture)
		print("📸 Viewport texture configurada para PSX!")

func update_shader_parameters():
	"""Atualiza todos os parâmetros do shader PSX"""
	if not psx_material:
		return
	
	# Parâmetros principais
	psx_material.set_shader_parameter("enable_fog", enable_psx_effects)
	psx_material.set_shader_parameter("fog_color", Vector3(fog_color.r, fog_color.g, fog_color.b))
	psx_material.set_shader_parameter("noise_color", Vector3(noise_color.r, noise_color.g, noise_color.b))
	psx_material.set_shader_parameter("fog_distance", fog_distance)
	psx_material.set_shader_parameter("fog_fade_range", fog_fade_range)
	psx_material.set_shader_parameter("enable_noise", enable_psx_effects and enable_noise)
	psx_material.set_shader_parameter("noise_time_fac", noise_time_factor)
	psx_material.set_shader_parameter("enable_color_limitation", enable_psx_effects and enable_color_limitation)
	psx_material.set_shader_parameter("color_levels", color_levels)
	psx_material.set_shader_parameter("enable_dithering", enable_psx_effects and enable_dithering)
	psx_material.set_shader_parameter("dither_strength", dither_strength)

# Funções de controle
func toggle_psx_effects():
	"""Liga/desliga os efeitos PSX"""
	enable_psx_effects = !enable_psx_effects
	update_shader_parameters()
	print("🎮 PSX Full Screen Effect: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

func show_effect():
	"""Mostra o efeito PSX"""
	visible = true
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 PSX Full Screen Effect: MOSTRADO")

func hide_effect():
	"""Esconde o efeito PSX"""
	visible = false
	print("🎮 PSX Full Screen Effect: ESCONDIDO")

# Presets de configuração PSX
func apply_classic_psx_preset():
	"""Aplica preset PSX clássico"""
	fog_color = Color(0.3, 0.3, 0.5)
	noise_color = Color(0.1, 0.1, 0.3)
	fog_distance = 100.0
	fog_fade_range = 50.0
	color_levels = 16
	dither_strength = 0.5
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 Preset PSX Clássico aplicado!")

func apply_horror_psx_preset():
	"""Aplica preset PSX horror"""
	fog_color = Color(0.2, 0.1, 0.1)
	noise_color = Color(0.1, 0.05, 0.05)
	fog_distance = 80.0
	fog_fade_range = 40.0
	color_levels = 12
	dither_strength = 0.7
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 Preset PSX Horror aplicado!")

func apply_nightmare_psx_preset():
	"""Aplica preset PSX nightmare"""
	fog_color = Color(0.1, 0.05, 0.2)
	noise_color = Color(0.05, 0.02, 0.1)
	fog_distance = 60.0
	fog_fade_range = 30.0
	color_levels = 8
	dither_strength = 0.8
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 Preset PSX Nightmare aplicado!")

# Input para controles em tempo real
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				toggle_psx_effects()
			KEY_F2:
				apply_classic_psx_preset()
			KEY_F3:
				apply_horror_psx_preset()
			KEY_F4:
				apply_nightmare_psx_preset()

# Função para redimensionar quando a janela muda
func _on_viewport_size_changed():
	"""Atualiza o tamanho do viewport quando a janela muda"""
	if viewport:
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		print("📺 Viewport PSX redimensionado: ", viewport.size)

# Cleanup quando o nó é removido
func _exit_tree():
	restore_original_content() 