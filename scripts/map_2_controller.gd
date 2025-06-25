extends Node3D

# Referência para controlar a introdução do estágio
var intro_shown = false

func _ready():
	print("[Map2Controller] Inicializando controlador do Map 2")
	
	# Aguarda alguns frames para garantir que tudo foi carregado
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("[Map2Controller] Frames aguardados, verificando intro_shown: ", intro_shown)
	
	# Mostra a introdução do estágio se ainda não foi mostrada
	if not intro_shown:
		print("[Map2Controller] Chamando show_stage_intro()")
		show_stage_intro()
	else:
		print("[Map2Controller] Introdução já foi mostrada, pulando")

func show_stage_intro():
	"""
	Mostra a introdução do Estágio 1
	"""
	print("[Map2Controller] show_stage_intro() iniciado")
	
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager:
		print("[Map2Controller] UIManager encontrado")
		intro_shown = true
		print("[Map2Controller] Chamando ui_manager.show_stage_intro('estagio1')")
		ui_manager.show_stage_intro("estagio1")
		
		# Conecta ao sinal de conclusão usando call_deferred
		call_deferred("_connect_to_intro_signal")
	else:
		print("[Map2Controller] ERRO: UIManager não encontrado")

func _connect_to_intro_signal():
	"""
	Conecta ao sinal da introdução após ela ser criada
	"""
	var ui_manager = get_node_or_null("/root/UIManager")
	if ui_manager and ui_manager.stage_intro_instance and is_instance_valid(ui_manager.stage_intro_instance) and not ui_manager.stage_intro_instance.is_queued_for_deletion():
		if ui_manager.stage_intro_instance.has_signal("intro_finished"):
			# Verifica se já não está conectado para evitar duplicação
			if not ui_manager.stage_intro_instance.is_connected("intro_finished", _on_intro_finished):
				ui_manager.stage_intro_instance.connect("intro_finished", _on_intro_finished)
				print("[Map2Controller] Conectado ao sinal intro_finished")
		else:
			print("[Map2Controller] AVISO: Sinal intro_finished não encontrado")
		
		# TESTE: Chama função de teste para verificar se funciona
		print("[Map2Controller] Chamando função de teste...")
		if ui_manager.stage_intro_instance.has_method("test_intro"):
			ui_manager.stage_intro_instance.test_intro()
		else:
			print("[Map2Controller] ERRO: Método test_intro não encontrado")
	else:
		print("[Map2Controller] AVISO: stage_intro_instance não disponível para conexão")

func _on_intro_finished():
	"""
	Chamado quando a introdução do estágio termina
	"""
	print("[Map2Controller] Introdução do estágio concluída")
	
	# Aqui podem ser adicionadas outras ações pós-introdução
	# Como ativar música ambiente, spawnar inimigos, etc. 
