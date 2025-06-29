extends Node

# Global PSX Effect Manager - Nightmare Loop
# Aplica shader PSX em TODA a aplicação desde o início

var global_canvas_layer: CanvasLayer = null
var global_color_rect: ColorRect = null
var back_buffer_copy: BackBufferCopy = null
var psx_material: ShaderMaterial = null
var psx_shader_material_resource = preload("res://materials/psx_post_process_material.tres")
var debug_mode: bool = false

func _ready():
	print("🌍 Global PSX Effect inicializado!")
	setup_global_psx_effect()
	get_tree().node_added.connect(_on_node_added)
	get_tree().tree_changed.connect(_on_tree_changed)
	
	# Conecta ao sinal de redimensionamento da janela
	if get_window():
		get_window().size_changed.connect(_on_window_size_changed)
	
	print("✅ Global PSX Effect ativo!")
	print("🎮 Controles:")
	print("  F1 - Toggle PSX Effect")
	print("  F2 - Toggle Debug Mode")

func setup_global_psx_effect():
	global_canvas_layer = CanvasLayer.new()
	global_canvas_layer.name = "GlobalPSXLayer"
	global_canvas_layer.layer = 1000
	global_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	# Adiciona BackBufferCopy para capturar a tela
	back_buffer_copy = BackBufferCopy.new()
	back_buffer_copy.name = "PSXBackBufferCopy"
	back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	
	global_color_rect = ColorRect.new()
	global_color_rect.name = "GlobalPSXRect"
	global_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	global_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_color_rect.color = Color.WHITE

	setup_psx_material()

	# Monta a hierarquia correta
	global_canvas_layer.add_child(back_buffer_copy)
	global_canvas_layer.add_child(global_color_rect)
	get_tree().root.add_child(global_canvas_layer)
	
	# Move o CanvasLayer para o final da árvore (renderiza por último)
	move_canvas_layer_to_front()

	print("🌍 PSX Effect global configurado!")
	print("📺 BackBufferCopy: ", back_buffer_copy != null)
	print("🎨 Material: ", psx_material != null)

func setup_psx_material():
	# Cria material básico primeiro
	psx_material = ShaderMaterial.new()
	
	# Tenta carregar o shader principal
	var psx_shader = load("res://shaders/psx_post_process.gdshader")
	if psx_shader == null:
		print("⚠️ Shader principal não encontrado, usando shader simples")
		psx_shader = load("res://shaders/psx_post_process_simple.gdshader")
	
	if psx_shader != null:
		psx_material.shader = psx_shader
		update_shader_parameters()
		global_color_rect.material = psx_material
		print("✅ Shader PSX aplicado com sucesso")
	else:
		print("❌ ERRO: Nenhum shader PSX encontrado!")
		# Fallback: sem shader
		global_color_rect.material = null

func update_shader_parameters():
	if not psx_material or not psx_material.shader:
		return

	# Parâmetros básicos que funcionam em ambos os shaders
	psx_material.set_shader_parameter("enable_color_limitation", true)
	psx_material.set_shader_parameter("color_levels", 10)
	psx_material.set_shader_parameter("brightness", 0.8)
	psx_material.set_shader_parameter("contrast", 1.2)
	
	# Parâmetros avançados (só se o shader suportar)
	if psx_material.shader.get_path().get_file() == "psx_post_process.gdshader":
		psx_material.set_shader_parameter("enable_dithering", true)
		psx_material.set_shader_parameter("dither_strength", 0.5)
		psx_material.set_shader_parameter("enable_fog", true)
		psx_material.set_shader_parameter("fog_strength", 0.6)
		psx_material.set_shader_parameter("enable_noise", true)
		psx_material.set_shader_parameter("noise_strength", 0.4)
		psx_material.set_shader_parameter("enable_contrast_boost", true)
		psx_material.set_shader_parameter("saturation", 0.7)
		psx_material.set_shader_parameter("fog_color", Vector3(0.15, 0.1, 0.1))
		psx_material.set_shader_parameter("noise_color", Vector3(0.1, 0.05, 0.05))

func move_canvas_layer_to_front():
	"""Move o CanvasLayer para o final da árvore para renderizar por último"""
	if global_canvas_layer and is_instance_valid(global_canvas_layer):
		var root = get_tree().root
		if root and global_canvas_layer.get_parent() == root:
			root.move_child(global_canvas_layer, root.get_child_count() - 1)

func _on_node_added(node: Node):
	if global_canvas_layer and is_instance_valid(global_canvas_layer):
		if not global_canvas_layer.is_ancestor_of(node):
			# Move o CanvasLayer para o final da árvore
			move_canvas_layer_to_front()

func _on_tree_changed():
	"""Chamado quando a árvore de nós muda (incluindo mudanças de cena)"""
	if global_canvas_layer and is_instance_valid(global_canvas_layer):
		move_canvas_layer_to_front()

func _on_window_size_changed():
	"""Chamado quando o tamanho da janela muda"""
	adapt_to_screen_size()

func adapt_to_screen_size():
	if not global_color_rect:
		return
	global_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	global_color_rect.queue_redraw()

func toggle_debug_mode():
	debug_mode = !debug_mode
	if debug_mode:
		# Modo debug: sem shader, só mostra informações
		global_color_rect.material = null
		global_color_rect.color = Color(0, 1, 0, 0.2)  # Verde transparente
		print("🐛 Debug Mode ATIVADO - Shader desabilitado")
	else:
		# Modo normal: reaplica shader
		setup_psx_material()
		global_color_rect.color = Color.WHITE
		print("🎮 Debug Mode DESATIVADO - Shader reativado")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				if global_canvas_layer:
					global_canvas_layer.visible = !global_canvas_layer.visible
					print("🌍 Global PSX Effect toggled: ", "ATIVO" if global_canvas_layer.visible else "DESATIVO")
			KEY_F2:
				toggle_debug_mode()
