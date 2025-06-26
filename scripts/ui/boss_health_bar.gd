extends Control

# === REFERÊNCIAS DOS ELEMENTOS DA UI ===
@onready var boss_name_label: Label = $VBoxContainer/BossNameLabel
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthBarContainer/HealthLabel
@onready var phase_label: Label = $VBoxContainer/PhaseLabel

# === PROPRIEDADES ===
var boss_name: String = ""
var max_health: float = 500.0
var current_health: float = 500.0
var current_phase: int = 1

# === CORES DAS FASES ===
var phase_colors = {
	1: Color(0.1, 0.8, 0.1, 1.0),  # Verde para Fase 1
	2: Color(0.8, 0.1, 0.1, 1.0)   # Vermelho para Fase 2
}

var phase_names = {
	1: "FASE 1: NEGAÇÃO",
	2: "FASE 2: NEGAÇÃO DESESPERADA"
}

func _ready():
	# Inicialmente invisível
	visible = false
	print("[BossHealthBar] Barra de vida do boss inicializada")

# === FUNÇÕES PÚBLICAS ===
func show_boss_health_bar(boss_display_name: String, boss_max_health: float):
	"""Mostra a barra de vida do boss com informações iniciais"""
	boss_name = boss_display_name
	max_health = boss_max_health
	current_health = boss_max_health
	current_phase = 1
	
	# Atualiza elementos da UI
	boss_name_label.text = boss_name.to_upper()
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = str(int(current_health)) + " / " + str(int(max_health))
	phase_label.text = phase_names[current_phase]
	
	# Define cor inicial
	_update_health_bar_color()
	
	# Mostra com animação
	_show_with_animation()
	
	print("👑 Barra de vida do boss mostrada: ", boss_name, " (", max_health, " HP)")

func update_health(new_health: float, boss_max_health: float = -1):
	"""Atualiza a vida do boss com animação suave"""
	if boss_max_health > 0:
		max_health = boss_max_health
		health_bar.max_value = max_health
	
	var old_health = current_health
	current_health = clamp(new_health, 0, max_health)
	
	# Animação suave da barra de vida
	var tween = create_tween()
	tween.tween_method(_animate_health_bar, old_health, current_health, 0.5)
	tween.tween_callback(_on_health_animation_finished)
	
	# Atualiza texto imediatamente
	health_label.text = str(int(current_health)) + " / " + str(int(max_health))
	
	# Efeito visual quando recebe dano
	if current_health < old_health:
		_damage_flash_effect()
	
	print("🩸 Vida do boss atualizada: ", current_health, "/", max_health)

func update_phase(new_phase: int):
	"""Atualiza a fase do boss"""
	if new_phase != current_phase:
		current_phase = new_phase
		phase_label.text = phase_names.get(current_phase, "FASE DESCONHECIDA")
		_update_health_bar_color()
		_phase_change_effect()
		print("🔄 Fase do boss atualizada para: ", current_phase)

func hide_boss_health_bar():
	"""Esconde a barra de vida do boss com animação"""
	_hide_with_animation()

# === FUNÇÕES PRIVADAS ===
func _animate_health_bar(value: float):
	"""Anima a barra de vida suavemente"""
	health_bar.value = value

func _on_health_animation_finished():
	"""Chamada quando a animação de vida termina"""
	# Verifica se o boss morreu
	if current_health <= 0:
		_boss_death_effect()

func _update_health_bar_color():
	"""Atualiza a cor da barra baseada na fase"""
	var color = phase_colors.get(current_phase, Color.WHITE)
	
	# Atualiza o estilo da barra
	var style = health_bar.get_theme_stylebox("fill").duplicate()
	style.bg_color = color
	health_bar.add_theme_stylebox_override("fill", style)

func _show_with_animation():
	"""Mostra a barra com animação deslizante"""
	visible = true
	modulate.a = 0.0
	position.x += 50  # Começa deslocada para a direita
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "position:x", position.x - 50, 0.5)
	tween.tween_callback(_on_show_animation_finished)

func _hide_with_animation():
	"""Esconde a barra com animação"""
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(self, "position:x", position.x + 50, 0.5)
	tween.tween_callback(_on_hide_animation_finished)

func _on_show_animation_finished():
	"""Chamada quando a animação de mostrar termina"""
	print("✨ Barra de vida do boss apareceu completamente")

func _on_hide_animation_finished():
	"""Chamada quando a animação de esconder termina"""
	visible = false
	print("👻 Barra de vida do boss escondida")

func _damage_flash_effect():
	"""Efeito visual quando o boss recebe dano"""
	var original_color = modulate
	modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_color, 0.2)

func _phase_change_effect():
	"""Efeito visual quando o boss muda de fase"""
	var original_scale = scale
	scale = Vector2(1.1, 1.1)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, 0.3)
	
	# Pisca o texto da fase
	var original_modulate = phase_label.modulate
	phase_label.modulate = Color.YELLOW
	tween.parallel().tween_property(phase_label, "modulate", original_modulate, 0.5)

func _boss_death_effect():
	"""Efeito visual quando o boss morre"""
	print("💀 Boss morreu! Executando efeito de morte...")
	
	# Pisca várias vezes
	for i in range(5):
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.3, 0.1)
		tween.tween_property(self, "modulate:a", 1.0, 0.1)
		await tween.finished
	
	# Esconde após o efeito
	await get_tree().create_timer(1.0).timeout
	hide_boss_health_bar()

# === GETTERS PÚBLICOS ===
func get_current_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return (current_health / max_health) * 100.0

func is_boss_alive() -> bool:
	return current_health > 0 