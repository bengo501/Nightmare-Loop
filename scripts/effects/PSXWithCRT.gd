extends Control

# Sistema PSX + CRT combinado
# PSX aplicado no SubViewportContainer, CRT aplicado via CanvasLayer + BackBufferCopy

# Referências
@onready var viewport_container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var game_content = $SubViewportContainer/SubViewport/GameContent
@onready var crt_effect = $CRTEffect
@onready var back_buffer_copy = $CRTEffect/BackBufferCopy
@onready var crt_overlay = $CRTEffect/CRTOverlay

# Materiais dos shaders
var psx_material: ShaderMaterial
var crt_material: ShaderMaterial

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

# Configurações CRT (valores mais sutis)
@export var enable_crt_effects: bool = true
@export var wiggle_strength: float = 0.5
@export var wiggle_speed: float = 0.8
@export var chromatic_aberration: float = 0.001
@export var scanline_intensity: float = 0.2
@export var vignette_strength: float = 0.15
@export var brightness: float = 1.0

# Referências para restaurar conteúdo
var original_scene: Node = null
var original_parent: Node = null

func _ready():
	print("🎮 PSX + CRT System inicializado!")
	
	# Configura o viewport
	setup_viewport()
	
	# Move o conteúdo da cena para o viewport
	await get_tree().process_frame
	move_scene_to_viewport()
	
	# Configura os materiais
	setup_materials()
	
	# Aplica presets padrão
	apply_classic_psx_preset()
	apply_classic_crt_preset()
	
	print("📺 PSX + CRT System ativo!")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset PSX Clássico")
	print("  F3 - Preset PSX Horror")
	print("  F4 - Preset PSX Nightmare")
	print("  F6 - Toggle CRT Effects")
	print("  F7 - CRT Vintage")
	print("  F8 - CRT Modern")
	print("  F9 - CRT Strong")

func setup_viewport():
	"""Configura o viewport para renderizar o jogo"""
	if viewport:
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		print("📺 SubViewport configurado: ", viewport.size)

func move_scene_to_viewport():
	"""Move a cena atual para dentro do SubViewport"""
	var current_scene = get_tree().current_scene
	
	# Evita recursão - não move a si mesmo
	if current_scene == self:
		print("⚠️ Não pode mover a cena PSX+CRT para si mesma")
		return
	
	# Evita mover cenas de efeitos
	if current_scene and (current_scene.name.contains("PSX") or current_scene.name.contains("CRT")):
		print("⚠️ Não pode mover cenas de efeitos PSX/CRT")
		return
	
	if current_scene and game_content:
		# Verifica se a cena já não está dentro do GameContent
		if current_scene.get_parent() == game_content:
			print("⚠️ Cena já está no GameContent: ", current_scene.name)
			return
		
		original_scene = current_scene
		original_parent = current_scene.get_parent()
		
		print("🎬 Movendo cena para SubViewport: ", current_scene.name)
		print("  📁 Cena original: ", current_scene.name)
		print("  📍 Parent original: ", original_parent.name if original_parent else "null")
		
		# Remove da árvore original
		if original_parent:
			original_parent.remove_child(current_scene)
		
		# Adiciona ao GameContent
		game_content.add_child(current_scene)
		print("  ✅ Cena movida para GameContent!")
		
		# Define este nó como a nova cena atual
		get_tree().current_scene = self
		print("  📺 PSXWithCRT agora é a cena atual")
	else:
		print("⚠️ Erro: current_scene ou game_content não encontrados")
		if not current_scene:
			print("    current_scene é null")
		if not game_content:
			print("    game_content é null")

func setup_materials():
	"""Configura os materiais PSX e CRT"""
	# Material PSX (SubViewportContainer)
	if viewport_container:
		psx_material = viewport_container.material as ShaderMaterial
		if psx_material:
			print("🎨 Material PSX configurado!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado!")
	
	# Material CRT (ColorRect overlay no CanvasLayer)
	if crt_overlay:
		crt_material = crt_overlay.material as ShaderMaterial
		if crt_material:
			print("📺 Material CRT configurado!")
		else:
			print("⚠️ ERRO: Material CRT não encontrado!")

func update_psx_parameters():
	"""Atualiza parâmetros do shader PSX"""
	if not psx_material:
		return
	
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

# Controles PSX
func toggle_psx_effects():
	"""Liga/desliga os efeitos PSX"""
	enable_psx_effects = !enable_psx_effects
	update_psx_parameters()
	print("🎮 PSX Effects: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

# Controles CRT
func toggle_crt_effects():
	"""Liga/desliga os efeitos CRT"""
	enable_crt_effects = !enable_crt_effects
	if enable_crt_effects:
		crt_effect.visible = true
	else:
		crt_effect.visible = false
	update_crt_parameters()
	print("📺 CRT Effects: ", "ATIVADO" if enable_crt_effects else "DESATIVADO")

# Presets PSX
func apply_classic_psx_preset():
	"""Aplica preset PSX clássico"""
	fog_color = Color(0.3, 0.3, 0.5)
	noise_color = Color(0.1, 0.1, 0.3)
	fog_distance = 100.0
	fog_fade_range = 50.0
	color_levels = 16
	dither_strength = 0.5
	enable_psx_effects = true
	update_psx_parameters()
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
	update_psx_parameters()
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
	update_psx_parameters()
	print("🎮 Preset PSX Nightmare aplicado!")

# Presets CRT
func apply_classic_crt_preset():
	"""Aplica preset CRT clássico"""
	wiggle_strength = 0.5
	wiggle_speed = 0.8
	chromatic_aberration = 0.001
	scanline_intensity = 0.2
	vignette_strength = 0.15
	brightness = 1.0
	enable_crt_effects = true
	crt_effect.visible = true
	update_crt_parameters()
	print("📺 Preset CRT Clássico aplicado!")

func apply_vintage_crt_preset():
	"""Aplica preset CRT vintage (mais forte)"""
	wiggle_strength = 1.0
	wiggle_speed = 1.2
	chromatic_aberration = 0.002
	scanline_intensity = 0.4
	vignette_strength = 0.25
	brightness = 0.95
	enable_crt_effects = true
	crt_effect.visible = true
	update_crt_parameters()
	print("📺 Preset CRT Vintage aplicado!")

func apply_modern_crt_preset():
	"""Aplica preset CRT moderno (mais sutil)"""
	wiggle_strength = 0.3
	wiggle_speed = 0.6
	chromatic_aberration = 0.0005
	scanline_intensity = 0.1
	vignette_strength = 0.1
	brightness = 1.05
	enable_crt_effects = true
	crt_effect.visible = true
	update_crt_parameters()
	print("📺 Preset CRT Moderno aplicado!")

func apply_strong_crt_preset():
	"""Aplica preset CRT forte (efeito intenso)"""
	wiggle_strength = 1.5
	wiggle_speed = 1.5
	chromatic_aberration = 0.003
	scanline_intensity = 0.6
	vignette_strength = 0.35
	brightness = 0.9
	enable_crt_effects = true
	crt_effect.visible = true
	update_crt_parameters()
	print("📺 Preset CRT Forte aplicado!")

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
			KEY_F6:
				toggle_crt_effects()
			KEY_F7:
				apply_vintage_crt_preset()
			KEY_F8:
				apply_modern_crt_preset()
			KEY_F9:
				apply_strong_crt_preset()

# Função para redimensionar quando a janela muda
func _on_viewport_size_changed():
	"""Atualiza o tamanho do viewport quando a janela muda"""
	if viewport:
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		print("📺 SubViewport redimensionado: ", viewport.size)

# Cleanup quando o nó é removido
func _exit_tree():
	if original_scene and original_parent and game_content:
		if original_scene.get_parent() == game_content:
			game_content.remove_child(original_scene)
		original_parent.add_child(original_scene)
		get_tree().current_scene = original_scene
		print("🎬 Cena restaurada: ", original_scene.name) 