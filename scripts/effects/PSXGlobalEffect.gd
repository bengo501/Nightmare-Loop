extends Control

# PSX Global Effect - Sempre Ativo
# Este nó fica permanentemente no root e aplica efeitos PSX a todo o conteúdo

# Referências
@onready var viewport_container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var game_content = $SubViewportContainer/SubViewport/GameContent

# Material PSX
var psx_material: ShaderMaterial

# Configurações PSX (sempre ativas)
@export var fog_color: Color = Color(0.3, 0.3, 0.5)
@export var noise_color: Color = Color(0.1, 0.1, 0.3)
@export var fog_distance: float = 100.0
@export var fog_fade_range: float = 50.0
@export var enable_noise: bool = true
@export var noise_time_factor: float = 4.0
@export var enable_color_limitation: bool = true
@export var color_levels: int = 16
@export var enable_dithering: bool = true
@export var dither_strength: float = 0.5

func _ready():
	print("🎮 PSX Global Effect inicializado (sempre ativo)!")
	
	# Configura o viewport
	setup_viewport()
	
	# Configura o material PSX
	setup_psx_material()
	
	# Aplica configurações PSX padrão
	apply_classic_psx_settings()
	
	print("✅ PSX Global Effect ativo permanentemente!")

func setup_viewport():
	"""Configura o viewport para renderizar o conteúdo"""
	if viewport:
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		print("📺 SubViewport configurado: ", viewport.size)

func setup_psx_material():
	"""Configura o material PSX"""
	if viewport_container:
		psx_material = viewport_container.material as ShaderMaterial
		if psx_material:
			print("🎨 Material PSX configurado e sempre ativo!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado!")

func apply_classic_psx_settings():
	"""Aplica configurações PSX clássicas (sempre ativas)"""
	fog_color = Color(0.3, 0.3, 0.5)
	noise_color = Color(0.1, 0.1, 0.3)
	fog_distance = 100.0
	fog_fade_range = 50.0
	color_levels = 16
	dither_strength = 0.5
	enable_noise = true
	enable_color_limitation = true
	enable_dithering = true
	
	update_psx_parameters()
	print("🎮 Configurações PSX Clássicas aplicadas!")

func update_psx_parameters():
	"""Atualiza parâmetros do shader PSX"""
	if not psx_material:
		return
	
	# PSX sempre ativo - enable_fog sempre true
	psx_material.set_shader_parameter("enable_fog", true)
	psx_material.set_shader_parameter("fog_color", Vector3(fog_color.r, fog_color.g, fog_color.b))
	psx_material.set_shader_parameter("noise_color", Vector3(noise_color.r, noise_color.g, noise_color.b))
	psx_material.set_shader_parameter("fog_distance", fog_distance)
	psx_material.set_shader_parameter("fog_fade_range", fog_fade_range)
	psx_material.set_shader_parameter("enable_noise", enable_noise)
	psx_material.set_shader_parameter("noise_time_fac", noise_time_factor)
	psx_material.set_shader_parameter("enable_color_limitation", enable_color_limitation)
	psx_material.set_shader_parameter("color_levels", color_levels)
	psx_material.set_shader_parameter("enable_dithering", enable_dithering)
	psx_material.set_shader_parameter("dither_strength", dither_strength)

# Funções para mudar presets PSX (opcionais)
func apply_horror_psx_settings():
	"""Aplica configurações PSX horror"""
	fog_color = Color(0.2, 0.1, 0.1)
	noise_color = Color(0.1, 0.05, 0.05)
	fog_distance = 80.0
	fog_fade_range = 40.0
	color_levels = 12
	dither_strength = 0.7
	update_psx_parameters()
	print("🎮 Configurações PSX Horror aplicadas!")

func apply_nightmare_psx_settings():
	"""Aplica configurações PSX nightmare"""
	fog_color = Color(0.1, 0.05, 0.2)
	noise_color = Color(0.05, 0.02, 0.1)
	fog_distance = 60.0
	fog_fade_range = 30.0
	color_levels = 8
	dither_strength = 0.8
	update_psx_parameters()
	print("🎮 Configurações PSX Nightmare aplicadas!")

# Função para adicionar conteúdo ao GameContent
func add_game_content(content: Node):
	"""Adiciona conteúdo ao GameContent"""
	if game_content and content:
		game_content.add_child(content)
		print("🎬 Conteúdo adicionado ao GameContent: ", content.name)

# Função para redimensionar quando a janela muda
func _on_viewport_size_changed():
	"""Atualiza o tamanho do viewport quando a janela muda"""
	if viewport:
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		print("📺 SubViewport redimensionado: ", viewport.size)

# Input opcional para trocar presets
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F2:
				apply_classic_psx_settings()
			KEY_F3:
				apply_horror_psx_settings()
			KEY_F4:
				apply_nightmare_psx_settings() 