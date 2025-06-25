extends CanvasLayer

# Referências aos nós
@onready var background = $Background
@onready var stage_image = $CenterContainer/VBoxContainer/StageImage
@onready var stage_title = $MarginContainer/StageTitle
@onready var center_container = $CenterContainer
@onready var margin_container = $MarginContainer
@onready var timer = $Timer

# Configurações da introdução
@export var display_duration: float = 3.0
@export var fade_in_duration: float = 1.0
@export var fade_out_duration: float = 1.0

# Sinais
signal intro_finished

# Variáveis para controle de tweens
var current_tween: Tween = null
var is_hiding: bool = false

# Texturas dos estágios
var stage_textures = {
	"estagio1": {
		"image_path": "res://assets/textures/estagio1Image.png",
		"title_path": "res://assets/textures/estagio1Title.png"
	}
	# Aqui podem ser adicionados mais estágios no futuro
}

func _ready():
	# Aguarda alguns frames para garantir que todos os nós foram carregados
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("[StageIntro] _ready() iniciado")
	
	# Verifica se todos os nós foram carregados corretamente
	if not _validate_nodes():
		print("[StageIntro] ERRO: Nem todos os nós foram carregados corretamente")
		return
	
	# Conecta o timer
	if timer:
		timer.connect("timeout", _on_timer_timeout)
		print("[StageIntro] Timer conectado")
	
	# Inicia invisível
	if center_container:
		center_container.modulate.a = 0.0
		print("[StageIntro] CenterContainer alpha definido para 0")
	if margin_container:
		margin_container.modulate.a = 0.0
		print("[StageIntro] MarginContainer alpha definido para 0")
	visible = false
	
	print("[StageIntro] Sistema de introdução de estágio inicializado com sucesso")

func _validate_nodes() -> bool:
	"""
	Valida se todos os nós necessários foram carregados
	"""
	var nodes_valid = true
	
	if not background:
		print("[StageIntro] ERRO: Background não encontrado")
		nodes_valid = false
	
	if not stage_image:
		print("[StageIntro] ERRO: StageImage não encontrado")
		# Tenta encontrar manualmente
		stage_image = get_node_or_null("CenterContainer/VBoxContainer/StageImage")
		if not stage_image:
			nodes_valid = false
	
	if not stage_title:
		print("[StageIntro] ERRO: StageTitle não encontrado")
		# Tenta encontrar manualmente
		stage_title = get_node_or_null("MarginContainer/StageTitle")
		if not stage_title:
			nodes_valid = false
	
	if not center_container:
		print("[StageIntro] ERRO: CenterContainer não encontrado")
		center_container = get_node_or_null("CenterContainer")
		if not center_container:
			nodes_valid = false
	
	if not margin_container:
		print("[StageIntro] ERRO: MarginContainer não encontrado")
		margin_container = get_node_or_null("MarginContainer")
		if not margin_container:
			nodes_valid = false
	
	if not timer:
		print("[StageIntro] ERRO: Timer não encontrado")
		timer = get_node_or_null("Timer")
		if not timer:
			nodes_valid = false
	
	return nodes_valid

func show_stage_intro(stage_name: String = "estagio1"):
	"""
	Mostra a introdução do estágio especificado
	"""
	print("[StageIntro] show_stage_intro() chamado com estágio: ", stage_name)
	print("[StageIntro] Estado atual - visible: ", visible, " is_hiding: ", is_hiding)
	
	# Usa call_deferred para aguardar frames sem async
	call_deferred("_show_stage_intro_deferred", stage_name)
	print("[StageIntro] call_deferred agendado")

func _show_stage_intro_deferred(stage_name: String):
	"""
	Função auxiliar que executa a introdução após alguns frames
	"""
	print("[StageIntro] _show_stage_intro_deferred() executado com estágio: ", stage_name)
	
	# Revalida os nós antes de usar
	if not _validate_nodes():
		print("[StageIntro] ERRO: Nós não estão disponíveis, cancelando introdução")
		return
	
	print("[StageIntro] Validação de nós passou")
	
	# Configura as texturas do estágio
	var textures = _load_stage_textures(stage_name)
	if not textures.is_empty():
		print("[StageIntro] Texturas carregadas com sucesso para estágio: ", stage_name)
		
		# Verifica se os nós existem antes de definir texturas
		if stage_image and is_instance_valid(stage_image):
			stage_image.texture = textures.image
			print("[StageIntro] Textura da imagem definida")
		else:
			print("[StageIntro] ERRO: stage_image não é válido")
			return
			
		if stage_title and is_instance_valid(stage_title):
			stage_title.texture = textures.title
			print("[StageIntro] Textura do título definida")
		else:
			print("[StageIntro] ERRO: stage_title não é válido")
			return
	else:
		print("[StageIntro] ERRO: Texturas não carregadas para estágio: ", stage_name)
		return
	
	# Define o modo de processamento para funcionar mesmo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[StageIntro] Modo de processamento definido para ALWAYS")
	
	# Pausa o jogo temporariamente
	get_tree().paused = true
	print("[StageIntro] Jogo pausado")
	
	# Torna visível
	visible = true
	print("[StageIntro] Nó definido como visível")
	
	# Verifica se center_container existe antes de animar
	if not center_container or not is_instance_valid(center_container):
		print("[StageIntro] ERRO: center_container não é válido para animação")
		return
	
	if not margin_container or not is_instance_valid(margin_container):
		print("[StageIntro] ERRO: margin_container não é válido para animação")
		return
	
	print("[StageIntro] Containers validados, iniciando fade in")
	
	# Inicia a animação de fade in
	_start_fade_in()

func _start_fade_in():
	"""
	Inicia a animação de fade in
	"""
	print("[StageIntro] _start_fade_in() iniciado")
	
	# Animação de fade in
	_cleanup_tween()
	current_tween = create_tween()
	if not current_tween:
		print("[StageIntro] ERRO: Falha ao criar tween")
		return
	
	print("[StageIntro] Tween criado com sucesso")
	
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.parallel().tween_property(center_container, "modulate:a", 1.0, fade_in_duration)
	current_tween.parallel().tween_property(margin_container, "modulate:a", 1.0, fade_in_duration)
	
	print("[StageIntro] Propriedades de tween configuradas")
	
	# Conecta ao sinal de conclusão
	current_tween.connect("finished", _on_fade_in_finished)
	print("[StageIntro] Sinal 'finished' conectado")

func _on_fade_in_finished():
	"""
	Chamado quando o fade in termina
	"""
	print("[StageIntro] _on_fade_in_finished() chamado")
	current_tween = null
	
	# Aguarda o tempo de exibição
	if timer and is_instance_valid(timer):
		timer.wait_time = display_duration
		timer.start()
		print("[StageIntro] Timer iniciado com duração: ", display_duration)
	else:
		print("[StageIntro] ERRO: Timer não é válido")

func _on_timer_timeout():
	"""
	Chamado quando o tempo de exibição termina
	"""
	print("[StageIntro] Tempo de exibição terminado, iniciando fade out")
	hide_stage_intro()

func hide_stage_intro():
	"""
	Esconde a introdução do estágio com fade out
	"""
	# Evita múltiplas chamadas
	if is_hiding:
		return
	is_hiding = true
	
	# Verifica se center_container existe antes de animar
	if not center_container or not is_instance_valid(center_container):
		print("[StageIntro] ERRO: center_container não é válido para fade out")
		_force_finish()
		return
	
	if not margin_container or not is_instance_valid(margin_container):
		print("[StageIntro] ERRO: margin_container não é válido para fade out")
		_force_finish()
		return
	
	# Inicia animação de fade out
	_start_fade_out()

func _start_fade_out():
	"""
	Inicia a animação de fade out
	"""
	# Animação de fade out
	_cleanup_tween()
	current_tween = create_tween()
	current_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.parallel().tween_property(center_container, "modulate:a", 0.0, fade_out_duration)
	current_tween.parallel().tween_property(margin_container, "modulate:a", 0.0, fade_out_duration)
	
	# Conecta ao sinal de conclusão
	current_tween.connect("finished", _on_fade_out_finished)

func _on_fade_out_finished():
	"""
	Chamado quando o fade out termina
	"""
	current_tween = null
	_finish_intro()

func _force_finish():
	"""
	Força o fim da introdução sem animação
	"""
	_cleanup_tween()
	visible = false
	get_tree().paused = false
	is_hiding = false
	emit_signal("intro_finished")
	print("[StageIntro] Introdução forçada a terminar")

func _finish_intro():
	"""
	Finaliza a introdução normalmente
	"""
	# Esconde e despausa o jogo
	visible = false
	get_tree().paused = false
	is_hiding = false
	
	# Emite sinal de conclusão
	emit_signal("intro_finished")
	print("[StageIntro] Introdução do estágio concluída")

func _input(event):
	"""
	Permite pular a introdução pressionando qualquer tecla
	"""
	if visible and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact")):
		print("[StageIntro] Introdução pulada pelo jogador")
		if timer and is_instance_valid(timer):
			timer.stop()
		hide_stage_intro()

func set_stage_textures(image_texture: Texture2D, title_texture: Texture2D):
	"""
	Define texturas customizadas para o estágio
	"""
	if stage_image and is_instance_valid(stage_image):
		stage_image.texture = image_texture
	if stage_title and is_instance_valid(stage_title):
		stage_title.texture = title_texture 

func _cleanup_tween():
	if current_tween and is_instance_valid(current_tween):
		# Desconecta sinais se estiverem conectados
		if current_tween.is_connected("finished", _on_fade_in_finished):
			current_tween.disconnect("finished", _on_fade_in_finished)
		if current_tween.is_connected("finished", _on_fade_out_finished):
			current_tween.disconnect("finished", _on_fade_out_finished)
		
		current_tween.kill()
		current_tween = null

func _exit_tree():
	"""
	Cleanup quando o nó é removido da árvore
	"""
	_cleanup_tween()
	if get_tree():
		get_tree().paused = false
	print("[StageIntro] Nó removido da árvore, cleanup realizado")

func _load_stage_textures(stage_name: String) -> Dictionary:
	"""
	Carrega as texturas do estágio dinamicamente
	"""
	print("[StageIntro] Carregando texturas para estágio: ", stage_name)
	
	if not stage_name in stage_textures:
		print("[StageIntro] ERRO: Estágio não encontrado: ", stage_name)
		return {}
	
	var paths = stage_textures[stage_name]
	var textures = {}
	
	# Carrega a imagem
	var image_texture = load(paths.image_path)
	if image_texture:
		textures.image = image_texture
		print("[StageIntro] Imagem carregada: ", paths.image_path)
	else:
		print("[StageIntro] ERRO: Falha ao carregar imagem: ", paths.image_path)
		return {}
	
	# Carrega o título
	var title_texture = load(paths.title_path)
	if title_texture:
		textures.title = title_texture
		print("[StageIntro] Título carregado: ", paths.title_path)
	else:
		print("[StageIntro] ERRO: Falha ao carregar título: ", paths.title_path)
		return {}
	
	return textures

func test_intro():
	"""
	Função de teste para verificar se a introdução funciona
	"""
	print("[StageIntro] test_intro() chamado")
	
	# Força visibilidade
	visible = true
	
	# Força alpha dos containers
	if center_container:
		center_container.modulate.a = 1.0
		print("[StageIntro] CenterContainer forçado para alpha 1.0")
	
	if margin_container:
		margin_container.modulate.a = 1.0
		print("[StageIntro] MarginContainer forçado para alpha 1.0")
	
	if background:
		background.modulate.a = 1.0
		print("[StageIntro] Background forçado para alpha 1.0")
	
	# Carrega texturas diretamente
	var textures = _load_stage_textures("estagio1")
	if not textures.is_empty():
		if stage_image:
			stage_image.texture = textures.image
			print("[StageIntro] Textura de imagem aplicada no teste")
		if stage_title:
			stage_title.texture = textures.title
			print("[StageIntro] Textura de título aplicada no teste")
	
	print("[StageIntro] Teste concluído - a introdução deve estar visível agora")
