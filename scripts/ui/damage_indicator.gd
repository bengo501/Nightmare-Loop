extends Label

var damage: int = 0
var duration: float = 1.2
var fade_start: float = 0.7
var move_distance: float = 100.0
var shake_amount: float = 10.0

func _ready():
	# Configura o texto com o valor do dano
	text = "-%d" % damage
	
	# Cria a animação
	var tween = create_tween()
	
	# Efeito de shake inicial
	var original_pos = position
	for i in range(5):
		tween.tween_property(self, "position", original_pos + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount)), 0.05)
		tween.tween_property(self, "position", original_pos, 0.05)
	
	# Efeito de escala
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Move para cima com efeito de desaceleração
	tween.tween_property(self, "position:y", position.y - move_distance, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, duration - fade_start).set_delay(fade_start)
	
	# Remove o nó quando a animação terminar
	tween.tween_callback(queue_free)

func set_damage(value: int):
	damage = value
	text = "-%d" % damage 