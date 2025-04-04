extends TextureRect

const mouse_sensitivity = 1.5
const position_scale = 0.6
const lerp_speed = 15.0

var shader_target_pos = Vector2.ZERO
@onready var cores = $"../CanvasLayer/CanvasLayer2/cores"  # Nó visual que também mudará de cor

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

		var new_shader_pos = ((mouse_pos - (screen_size / 2)) / screen_size) * mouse_sensitivity * -1.0
		new_shader_pos *= position_scale
		shader_target_pos = lerp(shader_target_pos, new_shader_pos, delta * lerp_speed)

		material.set("shader_parameter/mouse_pos", shader_target_pos)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in COLOR_KEYS and material and material is ShaderMaterial:
			var color = COLOR_KEYS[event.keycode]

			# Atualiza a cor do shader
			material.set("shader_parameter/dot_color", color)
			material.set("shader_parameter/line_color", color)

			# Atualiza a cor do nó visual "cores"
			if cores.has_method("set_modulate"):
				cores.set_modulate(color)  # Para Sprite2D, TextureRect, etc.
			elif cores.has_method("set_color"):
				cores.set_color(color)     # Para ColorRect
