extends Label3D

var velocity = Vector3.ZERO
var gravity = 2.0
var lifetime = 1.0
var fade_speed = 1.0
var is_critical_damage = false

func _ready():
	# Cor padrão vermelha (será alterada se for crítico)
	if not is_critical_damage:
		modulate = Color(1, 0, 0, 1)

func _process(delta):
	# Aplica gravidade
	velocity.y -= gravity * delta
	
	# Move a label
	position += velocity * delta
	
	# Fade out
	modulate.a -= fade_speed * delta
	
	# Remove quando ficar invisível
	if modulate.a <= 0:
		queue_free()

func setup(damage: int, is_damage: bool = true, is_critical: bool = false):
	text = str(damage) if is_damage else "+" + str(damage)
	is_critical_damage = is_critical
	
	# Configurações para dano crítico
	if is_critical:
		# Cor amarela brilhante para dano crítico
		modulate = Color(1, 1, 0, 1)  # Amarelo
		# Fonte maior para dano crítico
		font_size = 96  # Aumenta de 64 para 96
		# Movimento mais dramático
		velocity = Vector3(randf_range(-1.5, 1.5), 3.0, 0)  # Movimento mais alto e mais aleatório
		# Adiciona texto indicativo de crítico
		text = "CRÍTICO! " + text
		print("💥 [DamageLabel] Dano crítico configurado: ", text)
	else:
		# Configurações normais
		modulate = Color(1, 0, 0, 1)  # Vermelho
		font_size = 64  # Tamanho normal
		velocity = Vector3(randf_range(-1, 1), 2, 0)  # Movimento normal
		print("⚔️ [DamageLabel] Dano normal configurado: ", text) 