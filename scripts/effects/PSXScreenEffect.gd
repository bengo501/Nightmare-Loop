extends CanvasLayer

# Efeito PSX de Tela Completa para Nightmare Loop
# Aplica o shader PSX como overlay sobre toda a tela

# PSX Screen Effect - Configurações FORTES para afetar UI também
# Valores padrão mais intensos para efeito mais visível

# Configurações PSX FORTES (padrão)
@export var enable_psx_effects: bool = true  # SEMPRE ATIVO
@export var color_levels: int = 10  # REDUZIDO (era 24)
@export var dither_strength: float = 0.75  # AUMENTADO (era 0.4)
@export var enable_dithering: bool = true
@export var enable_color_limitation: bool = true
@export var enable_fog: bool = true
@export var fog_strength: float = 0.8  # AUMENTADO
@export var noise_strength: float = 0.6  # AUMENTADO

# Configurações de viewport para afetar UI
@export var affect_ui: bool = true  # NOVO: afeta UI também
@export var ui_layer_priority: int = 100  # NOVO: prioridade alta

# Referências
var screen_material: ShaderMaterial
var color_rect: ColorRect

func _ready():
	print("🎬 PSX Screen Effect FORTE inicializado!")
	print("📺 Configurações INTENSAS ativadas por padrão")
	print("🖥️ UI será afetada pelo shader PSX")
	
	setup_screen_effect()
	apply_strong_default_settings()
	
	# Debug
	print("✅ PSX Screen Effect FORTE ativo!")
	print("🎨 Parâmetros:")
	print("  - Níveis de cor: ", color_levels, " (reduzido)")
	print("  - Força do dither: ", dither_strength, " (aumentado)")
	print("  - Força do fog: ", fog_strength, " (aumentado)")
	print("  - Afeta UI: ", affect_ui)

func setup_screen_effect():
	"""Configura o efeito de tela com prioridade para UI"""
	# Configura layer com prioridade alta para afetar UI
	if affect_ui:
		layer = ui_layer_priority
	
	# Procura por ColorRect existente ou cria um novo
	color_rect = get_node_or_null("ColorRect")
	if not color_rect:
		color_rect = ColorRect.new()
		add_child(color_rect)
	
	# Configura ColorRect para tela inteira
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color.WHITE  # Cor base para o shader
	
	# Aplica material do shader
	if color_rect.material:
		screen_material = color_rect.material
	else:
		print("⚠️ Material PSX não encontrado no ColorRect")

func apply_strong_default_settings():
	"""Aplica configurações FORTES por padrão"""
	if screen_material:
		# Configurações FORTES
		screen_material.set_shader_parameter("enable_color_limitation", enable_color_limitation)
		screen_material.set_shader_parameter("color_levels", color_levels)  # 10 cores
		screen_material.set_shader_parameter("enable_dithering", enable_dithering)
		screen_material.set_shader_parameter("dither_strength", dither_strength)  # 0.75
		screen_material.set_shader_parameter("enable_fog", enable_fog)
		screen_material.set_shader_parameter("fog_strength", fog_strength)  # 0.8
		screen_material.set_shader_parameter("noise_strength", noise_strength)  # 0.6
		
		# Aplica preset horror forte por padrão
		apply_horror_psx_preset()
		
		print("🎨 Configurações PSX FORTES aplicadas ao shader!")

# Funções públicas para controle externo
func set_color_levels(levels: int):
	"""Define número de níveis de cor"""
	color_levels = levels
	if screen_material:
		screen_material.set_shader_parameter("color_levels", color_levels)
	print("🎨 Níveis de cor definidos para: ", color_levels)

func set_dither_strength(strength: float):
	"""Define força do dithering"""
	dither_strength = strength
	if screen_material:
		screen_material.set_shader_parameter("dither_strength", dither_strength)
	print("🎨 Força do dither definida para: ", dither_strength)

func setup_strong_psx():
	"""Configuração extra forte para PSX"""
	color_levels = 8  # Muito reduzido
	dither_strength = 0.85  # Muito forte
	fog_strength = 0.9  # Muito forte
	noise_strength = 0.7  # Muito forte
	
	apply_strong_default_settings()
	print("💪 Configuração PSX EXTRA FORTE aplicada!")

# Presets atualizados com configurações FORTES
func apply_classic_psx_preset():
	"""Preset clássico FORTE"""
	if screen_material:
		screen_material.set_shader_parameter("color_levels", 12)
		screen_material.set_shader_parameter("dither_strength", 0.6)
		screen_material.set_shader_parameter("fog_strength", 0.7)
		screen_material.set_shader_parameter("noise_strength", 0.5)
		
		# Cores mais escuras
		screen_material.set_shader_parameter("fog_color", Vector3(0.2, 0.2, 0.4))
		screen_material.set_shader_parameter("noise_color", Vector3(0.1, 0.1, 0.2))
	
	print("🎮 Preset PSX Clássico FORTE aplicado!")

func apply_horror_psx_preset():
	"""Preset horror FORTE"""
	if screen_material:
		screen_material.set_shader_parameter("color_levels", 10)  # Bem reduzido
		screen_material.set_shader_parameter("dither_strength", 0.75)  # Muito dithering
		screen_material.set_shader_parameter("fog_strength", 0.85)  # Fog forte
		screen_material.set_shader_parameter("noise_strength", 0.65)  # Ruído forte
		
		# Cores vermelhas intensas
		screen_material.set_shader_parameter("fog_color", Vector3(0.25, 0.1, 0.1))
		screen_material.set_shader_parameter("noise_color", Vector3(0.15, 0.05, 0.05))
	
	print("🎮 Preset PSX Horror FORTE aplicado!")

func apply_nightmare_psx_preset():
	"""Preset nightmare FORTE"""
	if screen_material:
		screen_material.set_shader_parameter("color_levels", 8)  # Muito reduzido
		screen_material.set_shader_parameter("dither_strength", 0.85)  # Extremo dithering
		screen_material.set_shader_parameter("fog_strength", 0.9)  # Fog extremo
		screen_material.set_shader_parameter("noise_strength", 0.75)  # Ruído extremo
		
		# Cores roxas intensas
		screen_material.set_shader_parameter("fog_color", Vector3(0.15, 0.05, 0.25))
		screen_material.set_shader_parameter("noise_color", Vector3(0.1, 0.02, 0.15))
	
	print("🎮 Preset PSX Nightmare FORTE aplicado!")

func toggle_psx_effects():
	"""Liga/desliga efeitos PSX"""
	enable_psx_effects = !enable_psx_effects
	visible = enable_psx_effects
	print("🎮 PSX Screen Effect: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

func toggle_ui_affect():
	"""Liga/desliga efeito na UI"""
	affect_ui = !affect_ui
	layer = ui_layer_priority if affect_ui else 0
	print("🖥️ PSX afeta UI: ", "SIM" if affect_ui else "NÃO")

# Input para controles em tempo real
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F6:
				toggle_psx_effects()
			KEY_F7:
				apply_classic_psx_preset()
			KEY_F8:
				apply_horror_psx_preset()
			KEY_F9:
				apply_nightmare_psx_preset() 