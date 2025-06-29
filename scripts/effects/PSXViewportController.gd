extends Control

# Controlador de Viewport com Shader PSX para Nightmare Loop
# Aplica efeitos PSX através de um viewport dedicado

# Referências aos nós
@onready var viewport_container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var game_content = $SubViewportContainer/SubViewport/GameContent
@onready var psx_quad = $PSXPostProcessLayer/PSXQuad
@onready var psx_camera = $PSXPostProcessLayer/PSXCamera

# Material do shader PSX
var psx_material: ShaderMaterial

# Configurações PSX
@export var enable_psx_effects: bool = true
@export var fog_color: Color = Color(0.4, 0.4, 0.6)
@export var noise_color: Color = Color(0.2, 0.2, 0.4)
@export var fog_distance: float = 150.0
@export var fog_fade_range: float = 75.0
@export var enable_noise: bool = true
@export var noise_time_factor: float = 3.0
@export var enable_color_limitation: bool = true
@export var color_levels: int = 24
@export var enable_dithering: bool = true
@export var dither_strength: float = 0.4

func _ready():
	print("🎮 PSX Viewport Controller inicializado!")
	
	# Configura o viewport
	setup_viewport()
	
	# Configura o material PSX
	setup_psx_material()
	
	# Configura texturas do viewport
	setup_viewport_textures()
	
	print("📺 PSX Viewport pronto! Controles:")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset Clássico")
	print("  F3 - Preset Horror")
	print("  F4 - Preset Nightmare")

func setup_viewport():
	"""Configura o viewport principal"""
	if viewport:
		# Configura o tamanho do viewport
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		
		# Configurações de renderização
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		
		print("📺 Viewport configurado: ", viewport.size)

func setup_psx_material():
	"""Configura o material do shader PSX"""
	if psx_quad:
		psx_material = psx_quad.get_surface_override_material(0)
		if psx_material:
			update_shader_parameters()
			print("🎨 Material PSX configurado!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado!")

func setup_viewport_textures():
	"""Configura as texturas do viewport para o shader"""
	if not psx_material or not viewport:
		return
	
	# Aguarda um frame para garantir que o viewport está pronto
	await get_tree().process_frame
	
	# Define as texturas do viewport para o shader
	var screen_texture = viewport.get_texture()
	var depth_texture = viewport.get_texture()  # Em Godot 4, pode precisar de configuração específica
	
	if screen_texture:
		psx_material.set_shader_parameter("screen_texture", screen_texture)
		print("📸 Screen texture configurada!")
	
	# Para depth texture, pode precisar de configuração adicional no viewport
	# psx_material.set_shader_parameter("depth_texture", depth_texture)

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

func add_scene_to_viewport(scene: Node3D):
	"""Adiciona uma cena ao viewport"""
	if game_content and scene:
		game_content.add_child(scene)
		print("🎬 Cena adicionada ao viewport PSX: ", scene.name)

func remove_scene_from_viewport(scene: Node3D):
	"""Remove uma cena do viewport"""
	if game_content and scene and scene.get_parent() == game_content:
		game_content.remove_child(scene)
		print("🎬 Cena removida do viewport PSX: ", scene.name)

func get_viewport_camera() -> Camera3D:
	"""Retorna a câmera ativa do viewport"""
	if viewport:
		return viewport.get_camera_3d()
	return null

# Funções de controle dos efeitos PSX
func toggle_psx_effects():
	"""Liga/desliga os efeitos PSX"""
	enable_psx_effects = !enable_psx_effects
	update_shader_parameters()
	print("🎮 PSX Effects: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

func set_fog_distance(distance: float):
	"""Define a distância do fog"""
	fog_distance = distance
	if psx_material:
		psx_material.set_shader_parameter("fog_distance", fog_distance)

func set_color_levels(levels: int):
	"""Define os níveis de cor"""
	color_levels = clamp(levels, 2, 256)
	if psx_material:
		psx_material.set_shader_parameter("color_levels", color_levels)

func set_dither_strength(strength: float):
	"""Define a força do dithering"""
	dither_strength = clamp(strength, 0.0, 1.0)
	if psx_material:
		psx_material.set_shader_parameter("dither_strength", dither_strength)

# Presets de configuração PSX
func apply_classic_psx_preset():
	"""Aplica preset PSX clássico"""
	fog_color = Color(0.3, 0.3, 0.5)
	noise_color = Color(0.1, 0.1, 0.3)
	fog_distance = 100.0
	fog_fade_range = 50.0
	color_levels = 16
	dither_strength = 0.5
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
		print("📺 Viewport redimensionado: ", viewport.size) 