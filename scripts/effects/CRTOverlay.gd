extends CanvasLayer

# CRT Overlay - Efeito de monitor CRT aplicado por cima de tudo

# Referências
@onready var back_buffer_copy = $BackBufferCopy
@onready var crt_effect = $CRTEffect

# Material CRT
var crt_material: ShaderMaterial

# Configurações CRT (valores sutis)
@export var enable_crt_effects: bool = true
@export var wiggle_strength: float = 0.5
@export var wiggle_speed: float = 0.8
@export var chromatic_aberration: float = 0.001
@export var scanline_intensity: float = 0.2
@export var vignette_strength: float = 0.15
@export var brightness: float = 1.0

func _ready():
	print("📺 CRT Overlay inicializado!")
	
	# Garante que o CRTEffect ignore inputs
	if crt_effect:
		crt_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if crt_effect:
		crt_material = crt_effect.material as ShaderMaterial
		setup_crt_material()
	print("✅ CRT Overlay ativo!")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F6:
				enable_crt_effects = !enable_crt_effects
				visible = enable_crt_effects
				update_crt_parameters()
				print("📺 CRT: ", "ON" if enable_crt_effects else "OFF")
			KEY_F7:
				apply_modern_crt_settings()
			KEY_F8:
				apply_vintage_crt_settings()
			KEY_F9:
				apply_strong_crt_settings()

func setup_crt_material():
	"""Configura o material CRT"""
	if crt_effect:
		crt_material = crt_effect.material as ShaderMaterial
		if crt_material:
			update_crt_parameters()
			print("📺 Material CRT configurado!")
		else:
			print("⚠️ ERRO: Material CRT não encontrado!")

func update_crt_parameters():
	"""Atualiza parâmetros do shader CRT"""
	if not crt_material:
		return
	
	crt_material.set_shader_parameter("wiggle_strength", wiggle_strength if enable_crt_effects else 0.0)
	crt_material.set_shader_parameter("wiggle_speed", wiggle_speed)
	crt_material.set_shader_parameter("chromatic_aberration", chromatic_aberration if enable_crt_effects else 0.0)
	crt_material.set_shader_parameter("scanline_intensity", scanline_intensity if enable_crt_effects else 0.0)
	crt_material.set_shader_parameter("vignette_strength", vignette_strength if enable_crt_effects else 0.0)
	crt_material.set_shader_parameter("brightness", brightness if enable_crt_effects else 1.0)

# Presets CRT
func apply_modern_crt_settings():
	"""Aplica configurações CRT modernas (mais sutis)"""
	wiggle_strength = 0.3
	wiggle_speed = 0.6
	chromatic_aberration = 0.0005
	scanline_intensity = 0.1
	vignette_strength = 0.1
	brightness = 1.05
	enable_crt_effects = true
	visible = true
	update_crt_parameters()
	print("📺 Configurações CRT Modernas aplicadas!")

func apply_vintage_crt_settings():
	"""Aplica configurações CRT vintage"""
	wiggle_strength = 1.0
	wiggle_speed = 1.2
	chromatic_aberration = 0.002
	scanline_intensity = 0.4
	vignette_strength = 0.25
	brightness = 0.95
	enable_crt_effects = true
	visible = true
	update_crt_parameters()
	print("📺 Configurações CRT Vintage aplicadas!")

func apply_strong_crt_settings():
	"""Aplica configurações CRT fortes"""
	wiggle_strength = 1.5
	wiggle_speed = 1.5
	chromatic_aberration = 0.003
	scanline_intensity = 0.6
	vignette_strength = 0.35
	brightness = 0.9
	enable_crt_effects = true
	visible = true
	update_crt_parameters()
	print("📺 Configurações CRT Fortes aplicadas!")
