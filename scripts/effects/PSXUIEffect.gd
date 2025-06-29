extends CanvasLayer

# Efeito PSX que afeta toda a tela incluindo UIs
# Usa BackBufferCopy + ColorRect com shader canvas_item

# Referências
@onready var back_buffer_copy = $BackBufferCopy
@onready var psx_overlay = $PSXOverlay

# Material do shader
var psx_material: ShaderMaterial

# Configurações PSX
@export var enable_psx_effects: bool = true
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
	print("🎮 PSX UI Effect inicializado!")
	
	# Configura o material PSX
	setup_psx_material()
	
	# Aplica preset padrão
	apply_classic_psx_preset()
	
	print("📺 PSX UI Effect ativo! (afeta jogo + UI)")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset Clássico")
	print("  F3 - Preset Horror")
	print("  F4 - Preset Nightmare")

func setup_psx_material():
	"""Configura o material do shader PSX"""
	if psx_overlay:
		psx_material = psx_overlay.material as ShaderMaterial
		if psx_material:
			update_shader_parameters()
			print("🎨 Material PSX UI configurado!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado!")

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
	print("🎮 PSX UI Effect: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

func show_effect():
	"""Mostra o efeito PSX"""
	visible = true
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 PSX UI Effect: MOSTRADO")

func hide_effect():
	"""Esconde o efeito PSX"""
	visible = false
	print("🎮 PSX UI Effect: ESCONDIDO")

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