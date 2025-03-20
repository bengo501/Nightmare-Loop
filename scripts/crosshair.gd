extends TextureRect

func _process(delta):
	if material and material is ShaderMaterial:  # Garante que o material é um ShaderMaterial
		var mouse_pos = get_viewport().get_mouse_position()  # Obtém a posição do mouse
		var screen_size = get_viewport_rect().size  # Obtém o tamanho da tela

		# Normaliza a posição do mouse para coordenadas (-0.5 a 0.5)
		var normalized_mouse_pos = (mouse_pos / screen_size) - Vector2(0.5, 0.5)

		# Define o parâmetro do shader corretamente no Godot 4
		material.set("shader_parameter/mouse_pos", normalized_mouse_pos)
