extends Node3D

# Referências
@onready var post_process_quad = $"."
@onready var post_process_camera = $Camera3D
var material: ShaderMaterial

# Configurações PSX
@export var enable_psx_effect: bool = true
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
	# Configura o material do shader
	setup_psx_material()
	
	# Configura a câmera de post-processing
	setup_post_process_camera()
	
	print("🎮 PSX Post-Process Effect inicializado!")
	print("📺 Efeitos ativos:")
	print("  - Fog: ", enable_psx_effect and material.get_shader_parameter("enable_fog"))
	print("  - Noise: ", enable_psx_effect and material.get_shader_parameter("enable_noise"))
	print("  - Color Limitation: ", enable_psx_effect and material.get_shader_parameter("enable_color_limitation"))
	print("  - Dithering: ", enable_psx_effect and material.get_shader_parameter("enable_dithering"))

func setup_psx_material():
	# Obtém o material do shader
	if post_process_quad and post_process_quad.get_surface_override_material(0):
		material = post_process_quad.get_surface_override_material(0)
		
		# Configura os parâmetros do shader
		update_shader_parameters()
	else:
		print("⚠️ ERRO: Material PSX não encontrado!")

func setup_post_process_camera():
	if post_process_camera:
		# Configura a câmera para capturar a tela
		post_process_camera.current = false  # Não deve ser a câmera principal
		post_process_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		post_process_camera.size = 2.0
		post_process_camera.near = 0.1
		post_process_camera.far = 10.0

func update_shader_parameters():
	if not material:
		return
	
	# Atualiza todos os parâmetros do shader
	material.set_shader_parameter("enable_fog", enable_psx_effect)
	material.set_shader_parameter("fog_color", Vector3(fog_color.r, fog_color.g, fog_color.b))
	material.set_shader_parameter("noise_color", Vector3(noise_color.r, noise_color.g, noise_color.b))
	material.set_shader_parameter("fog_distance", fog_distance)
	material.set_shader_parameter("fog_fade_range", fog_fade_range)
	material.set_shader_parameter("enable_noise", enable_psx_effect and enable_noise)
	material.set_shader_parameter("noise_time_fac", noise_time_factor)
	material.set_shader_parameter("enable_color_limitation", enable_psx_effect and enable_color_limitation)
	material.set_shader_parameter("color_levels", color_levels)
	material.set_shader_parameter("enable_dithering", enable_psx_effect and enable_dithering)
	material.set_shader_parameter("dither_strength", dither_strength)

# Funções para controle em tempo real
func toggle_psx_effect():
	enable_psx_effect = !enable_psx_effect
	update_shader_parameters()
	print("🎮 PSX Effect: ", "ATIVADO" if enable_psx_effect else "DESATIVADO")

func set_fog_distance(distance: float):
	fog_distance = distance
	if material:
		material.set_shader_parameter("fog_distance", fog_distance)

func set_color_levels(levels: int):
	color_levels = clamp(levels, 2, 256)
	if material:
		material.set_shader_parameter("color_levels", color_levels)

func set_dither_strength(strength: float):
	dither_strength = clamp(strength, 0.0, 1.0)
	if material:
		material.set_shader_parameter("dither_strength", dither_strength)

# Presets de configuração
func apply_classic_psx_preset():
	fog_color = Color(0.3, 0.3, 0.5)
	noise_color = Color(0.1, 0.1, 0.3)
	fog_distance = 100.0
	fog_fade_range = 50.0
	color_levels = 16
	dither_strength = 0.5
	update_shader_parameters()
	print("🎮 Preset PSX Clássico aplicado!")

func apply_horror_psx_preset():
	fog_color = Color(0.2, 0.1, 0.1)
	noise_color = Color(0.1, 0.05, 0.05)
	fog_distance = 80.0
	fog_fade_range = 40.0
	color_levels = 12
	dither_strength = 0.7
	update_shader_parameters()
	print("🎮 Preset PSX Horror aplicado!")

func apply_nightmare_psx_preset():
	fog_color = Color(0.1, 0.05, 0.2)
	noise_color = Color(0.05, 0.02, 0.1)
	fog_distance = 60.0
	fog_fade_range = 30.0
	color_levels = 8
	dither_strength = 0.8
	update_shader_parameters()
	print("🎮 Preset PSX Nightmare aplicado!")

# Input para debug (opcional)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				toggle_psx_effect()
			KEY_F2:
				apply_classic_psx_preset()
			KEY_F3:
				apply_horror_psx_preset()
			KEY_F4:
				apply_nightmare_psx_preset() 