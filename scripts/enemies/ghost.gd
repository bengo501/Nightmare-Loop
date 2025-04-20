extends CharacterBody3D

@export var max_health: float = 100.0
var current_health: float

func _ready():
	current_health = max_health
	print("DEBUG: Ghost inicializado com ", max_health, " de vida")
	add_to_group("enemy")  # Adiciona ao grupo de inimigos para ser detectado pelo raycast do jogador

func take_damage(damage: float) -> void:
	current_health -= damage
	print("DEBUG: Ghost tomou ", damage, " de dano! Vida restante: ", current_health)

	# Efeito visual de dano
	var material := $CSGCylinder3D.material as ShaderMaterial
	if material:
		material.set_shader_parameter("ghost_color", Vector4(2, 0, 0, 0.5))  # Cor vermelha temporária
		print("DEBUG: Efeito visual de dano aplicado")

		# Espera e restaura cor
		await get_tree().create_timer(0.2).timeout
		if material:
			material.set_shader_parameter("ghost_color", Vector4(2, 3, 0.85, 0.5))
			print("DEBUG: Cor do ghost restaurada")

	if current_health <= 0:
		die()

func die() -> void:
	print("DEBUG: Ghost morreu!")
	queue_free()  # Remove o ghost da cena
