extends Node

# UTILITÁRIO: Monitor de Performance em Tempo Real
# Use para verificar o impacto das otimizações

var fps_history: Array[float] = []
var frame_time_history: Array[float] = []
var memory_history: Array[float] = []

var max_history_size: int = 60  # 1 segundo a 60 FPS
var update_timer: Timer
var is_monitoring: bool = false

# Dados de performance
var current_fps: float = 0.0
var average_fps: float = 0.0
var min_fps: float = 999.0
var max_fps: float = 0.0
var frame_time_ms: float = 0.0
var memory_usage_mb: float = 0.0

# UI Debug (opcional)
var debug_label: Label = null

func _ready():
	# Setup do timer de monitoramento
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # Atualiza a cada 100ms
	update_timer.timeout.connect(_update_performance_data)
	add_child(update_timer)
	
	print("[PerformanceMonitor] Monitor de performance inicializado")
	print("[PerformanceMonitor] Use start_monitoring() para começar")

func start_monitoring():
	"""Inicia o monitoramento de performance"""
	is_monitoring = true
	update_timer.start()
	print("[PerformanceMonitor] ✅ Monitoramento iniciado")

func stop_monitoring():
	"""Para o monitoramento de performance"""
	is_monitoring = false
	update_timer.stop()
	print("[PerformanceMonitor] ⏹️ Monitoramento parado")

func _update_performance_data():
	"""Atualiza dados de performance"""
	if not is_monitoring:
		return
	
	# FPS atual
	current_fps = Engine.get_frames_per_second()
	
	# Frame time em millisegundos
	frame_time_ms = 1000.0 / max(current_fps, 1.0)
	
	# Uso de memória (aproximado)
	memory_usage_mb = OS.get_static_memory_usage_by_type().values().reduce(func(acc, val): return acc + val, 0) / 1024.0 / 1024.0
	
	# Atualiza históricos
	_update_history_arrays()
	
	# Calcula estatísticas
	_calculate_statistics()
	
	# Atualiza UI debug se existir
	_update_debug_ui()

func _update_history_arrays():
	"""Atualiza arrays de histórico"""
	# FPS
	fps_history.append(current_fps)
	if fps_history.size() > max_history_size:
		fps_history.pop_front()
	
	# Frame time
	frame_time_history.append(frame_time_ms)
	if frame_time_history.size() > max_history_size:
		frame_time_history.pop_front()
	
	# Memória
	memory_history.append(memory_usage_mb)
	if memory_history.size() > max_history_size:
		memory_history.pop_front()

func _calculate_statistics():
	"""Calcula estatísticas de performance"""
	if fps_history.is_empty():
		return
	
	# FPS médio
	var fps_sum = fps_history.reduce(func(acc, val): return acc + val, 0.0)
	average_fps = fps_sum / fps_history.size()
	
	# FPS mínimo e máximo
	min_fps = fps_history.min()
	max_fps = fps_history.max()

func _update_debug_ui():
	"""Atualiza UI de debug se estiver ativa"""
	if debug_label and is_instance_valid(debug_label):
		var text = "=== PERFORMANCE MONITOR ===\n"
		text += "FPS: %.1f (avg: %.1f)\n" % [current_fps, average_fps]
		text += "Range: %.1f - %.1f\n" % [min_fps, max_fps]
		text += "Frame Time: %.2f ms\n" % frame_time_ms
		text += "Memory: %.1f MB\n" % memory_usage_mb
		text += "Samples: %d" % fps_history.size()
		debug_label.text = text

func create_debug_ui():
	"""Cria UI de debug na tela"""
	if debug_label:
		return  # Já existe
	
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_color_override("font_color", Color.YELLOW)
	debug_label.add_theme_font_size_override("font_size", 14)
	
	# Adiciona à árvore principal
	get_tree().root.add_child(debug_label)
	print("[PerformanceMonitor] UI de debug criada")

func remove_debug_ui():
	"""Remove UI de debug"""
	if debug_label and is_instance_valid(debug_label):
		debug_label.queue_free()
		debug_label = null
		print("[PerformanceMonitor] UI de debug removida")

func get_performance_report() -> Dictionary:
	"""Retorna relatório completo de performance"""
	return {
		"current_fps": current_fps,
		"average_fps": average_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"frame_time_ms": frame_time_ms,
		"memory_usage_mb": memory_usage_mb,
		"samples_count": fps_history.size(),
		"is_monitoring": is_monitoring
	}

func print_performance_report():
	"""Imprime relatório de performance no console"""
	var report = get_performance_report()
	print("\n=== RELATÓRIO DE PERFORMANCE ===")
	print("FPS Atual: %.1f" % report.current_fps)
	print("FPS Médio: %.1f" % report.average_fps)
	print("FPS Mín/Máx: %.1f / %.1f" % [report.min_fps, report.max_fps])
	print("Frame Time: %.2f ms" % report.frame_time_ms)
	print("Memória: %.1f MB" % report.memory_usage_mb)
	print("Amostras: %d" % report.samples_count)
	print("Status: %s" % ("Monitorando" if report.is_monitoring else "Parado"))
	print("================================\n")

func reset_statistics():
	"""Reseta todas as estatísticas"""
	fps_history.clear()
	frame_time_history.clear()
	memory_history.clear()
	min_fps = 999.0
	max_fps = 0.0
	print("[PerformanceMonitor] Estatísticas resetadas")

# Comandos de debug via input
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:  # F1 - Toggle monitoring
				if is_monitoring:
					stop_monitoring()
				else:
					start_monitoring()
			KEY_F2:  # F2 - Toggle debug UI
				if debug_label:
					remove_debug_ui()
				else:
					create_debug_ui()
			KEY_F3:  # F3 - Print report
				print_performance_report()
			KEY_F4:  # F4 - Reset statistics
				reset_statistics() 