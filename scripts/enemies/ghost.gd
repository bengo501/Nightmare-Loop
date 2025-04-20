extends Node3D

@export var max_health: float = 100.0
var current_health: float

func _ready():
    current_health = max_health
    # Adicionar o inimigo ao grupo "enemy" para detecção de ataques
    add_to_group("enemy")

func take_damage(damage: float):
    current_health -= damage
    print("Ghost took damage: ", damage, " Current health: ", current_health)
    
    # Efeito visual de dano (você pode personalizar isso)
    var material = $RigidBody3D/CSGCylinder3D.material as ShaderMaterial
    if material:
        material.shader_parameter/ghost_color = Vector4(2, 0, 0, 0.5)  # Cor vermelha temporária
    
    # Restaurar a cor original após um curto período
    await get_tree().create_timer(0.2).timeout
    if material:
        material.shader_parameter/ghost_color = Vector4(2, 3, 0.85, 0.5)
    
    if current_health <= 0:
        die()

func die():
    # Implementar lógica de morte do inimigo
    print("Ghost died!")
    queue_free()  # Remove o inimigo da cena 