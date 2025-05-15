extends TextureRect

const mouse_sensitivity = 1.5
const position_scale = 0.6
const lerp_speed = 15.0

var shader_target_pos = Vector2.ZERO
@onready var cores = get_node_or_null("../cores") # Atualizado para buscar corretamente em CanvasLayer2

# Cores associadas às teclas
const COLOR_KEYS = {
	KEY_1: Color(0, 1, 0),     # Verde
	KEY_2: Color(0, 0.5, 1),   # Azul
	KEY_3: Color(1, 0, 0),     # Vermelho
	KEY_4: Color(0.5, 0, 1),   # Roxo
	KEY_5: Color(1, 0.4, 0.7)  # Rosa
}

func _process(delta):
	if material and material is ShaderMaterial:
		var mouse_pos = get_viewport().get_mouse_position()
		var screen_size = get_viewport_rect().size

		# Sincroniza a posição da crosshair com o mouse
		self.position = mouse_pos - self.size / 2

		# O shader já está centralizado, não precisa de offset do mouse

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in COLOR_KEYS and material and material is ShaderMaterial:
			var color = COLOR_KEYS[event.keycode]

			# Atualiza a cor do shader
			material.set("shader_parameter/dot_color", color)
			material.set("shader_parameter/line_color", color)

			# Atualiza a cor do nó visual "cores"
			if cores and cores.has_method("set_modulate"):
				cores.set_modulate(color)  # Para Sprite2D, TextureRect, etc.
			elif cores and cores.has_method("set_color"):
				cores.set_color(color)     # Para ColorRect
