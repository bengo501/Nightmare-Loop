extends Control

# Sistema PSX Full Screen usando SubViewportContainer
# Move todo o conteúdo da cena para o SubViewport e aplica shader no container

# Referências
@onready var viewport_container = $SubViewportContainer
@onready var viewport = $SubViewportContainer/SubViewport
@onready var game_content = $SubViewportContainer/SubViewport/GameContent

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

# Referências para restaurar conteúdo
var original_scene: Node = null
var original_parent: Node = null

func _ready():
	print("🎮 PSX Full Screen Viewport inicializado!")
	
	# Configura o viewport
	setup_viewport()
	
	# Move o conteúdo da cena para o viewport
	await get_tree().process_frame
	move_scene_to_viewport()
	
	# Configura o material PSX
	setup_psx_material()
	
	# Aplica preset padrão
	apply_classic_psx_preset()
	
	print("📺 PSX Full Screen Viewport ativo!")
	print("  F1 - Toggle PSX Effects")
	print("  F2 - Preset Clássico")
	print("  F3 - Preset Horror")
	print("  F4 - Preset Nightmare")

func setup_viewport():
	"""Configura o viewport para renderizar o jogo"""
	if viewport:
		# Configura o tamanho baseado na janela
		var window_size = get_viewport().get_visible_rect().size
		viewport.size = Vector2i(int(window_size.x), int(window_size.y))
		
		# Configurações de renderização
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.handle_input_locally = false
		
		print("📺 SubViewport configurado: ", viewport.size)

func move_scene_to_viewport():
	"""Move a cena atual para dentro do SubViewport"""
	var current_scene = get_tree().current_scene
	
	# Evita mover a si mesmo
	if current_scene == self:
		print("⚠️ Não pode mover a cena PSX para si mesma")
		return
	
	if current_scene and game_content:
		# Salva referências para restaurar depois
		original_scene = current_scene
		original_parent = current_scene.get_parent()
		
		# Remove a cena atual de seu pai
		if original_parent:
			original_parent.remove_child(current_scene)
		
		# Adiciona ao viewport
		game_content.add_child(current_scene)
		
		print("🎬 Cena movida para SubViewport: ", current_scene.name)
		
		# Atualiza a current_scene para o sistema PSX
		get_tree().current_scene = self
	else:
		print("⚠️ Não foi possível mover a cena para o viewport")

func restore_scene():
	"""Restaura a cena original fora do viewport"""
	if original_scene and original_parent and game_content:
		# Remove do viewport
		if original_scene.get_parent() == game_content:
			game_content.remove_child(original_scene)
		
		# Restaura ao pai original
		original_parent.add_child(original_scene)
		
		# Restaura current_scene
		get_tree().current_scene = original_scene
		
		print("🎬 Cena restaurada: ", original_scene.name)

func setup_psx_material():
	"""Configura o material do shader PSX"""
	if viewport_container:
		psx_material = viewport_container.material as ShaderMaterial
		if psx_material:
			update_shader_parameters()
			print("🎨 Material PSX configurado!")
		else:
			print("⚠️ ERRO: Material PSX não encontrado no SubViewportContainer!")

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
	print("🎮 PSX Full Screen Viewport: ", "ATIVADO" if enable_psx_effects else "DESATIVADO")

func show_effect():
	"""Mostra o efeito PSX"""
	visible = true
	enable_psx_effects = true
	update_shader_parameters()
	print("🎮 PSX Full Screen Viewport: MOSTRADO")

func hide_effect():
	"""Esconde o efeito PSX"""
	visible = false
	print("🎮 PSX Full Screen Viewport: ESCONDIDO")

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
		print("📺 SubViewport redimensionado: ", viewport.size)

# Cleanup quando o nó é removido
func _exit_tree():
	restore_scene() 