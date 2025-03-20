extends TextureRect

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position() # Obtém a posição do mouse
	position = mouse_pos - (size / 2) # Centraliza a mira no cursor
