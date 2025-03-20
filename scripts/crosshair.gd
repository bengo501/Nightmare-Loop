extends TextureRect

const mouse_sensitivity = 1.5  # Ajuste da sensibilidade do shader ao mouse
const position_scale = 0.6  # Ajuste para aproximar o shader do cursor
const lerp_speed = 15.0  # Suaviza a transição do shader para evitar atrasos

var shader_target_pos = Vector2.ZERO  # Posição alvo do shader

func _process(delta):
	if material and material is ShaderMaterial:  # Garante que o material é um ShaderMaterial
		var mouse_pos = get_viewport().get_mouse_position()  # Obtém a posição do mouse
		var screen_size = get_viewport_rect().size  # Obtém o tamanho da tela

		# Ajuste da posição do mouse no shader e correção da inversão
		var new_shader_pos = ((mouse_pos - (screen_size / 2)) / screen_size) * mouse_sensitivity * -1.0
		
		# Aplica o fator de ajuste para aproximar mais o shader ao cursor
		new_shader_pos *= position_scale
		
		# Suaviza o movimento do shader para evitar atrasos perceptíveis
		shader_target_pos = lerp(shader_target_pos, new_shader_pos, delta * lerp_speed)

		# Aplica a posição corrigida ao shader
		material.set("shader_parameter/mouse_pos", shader_target_pos)
