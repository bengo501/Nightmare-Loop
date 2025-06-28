# Correção do Erro InputEventKey na Interação com a Cama

## Problema Identificado
Ao interagir com a "DoubleBed" para ir à cena "map_2.tscn", ocorria o seguinte erro:
```
Invalid call. Nonexistent function 'is_action_just_pressed' in base 'InputEventKey'.
```

## Causa do Erro
O erro ocorria porque o código estava tentando chamar o método `is_action_pressed()` diretamente no objeto `event` (que é do tipo `InputEventKey`), mas esse método não existe para objetos `InputEvent`.

### Código Problemático
```gdscript
# Em scripts/bed_interaction.gd e scripts/double_bed.gd
func _input(event):
    if player_inside and event.is_action_pressed("interact"):  # ❌ ERRO
        # ...
```

## Solução Implementada
Substituído `event.is_action_pressed()` por `Input.is_action_just_pressed()`, que é a forma correta de verificar inputs de ação no Godot.

### Código Corrigido
```gdscript
# Em scripts/bed_interaction.gd
func _input(event):
    if player_inside and Input.is_action_just_pressed("interact") and not interaction_active:  # ✅ CORRETO
        print("[BedInteraction] ⚡ TECLA E PRESSIONADA! Iniciando transição...")
        sleep_interaction()

# Em scripts/double_bed.gd  
func _input(event):
    if player_inside and Input.is_action_just_pressed("interact") and player_ref and teleport_position != null:  # ✅ CORRETO
        if pressE and is_instance_valid(pressE):
            pressE.visible = false
        # ...

# Em scripts/map_2_controller.gd
func _input(event):
    """Gerencia input para o sistema de pause"""
    if Input.is_action_just_pressed("ui_cancel"):  # ✅ CORRETO - Tecla ESC
        toggle_pause()
```

## Arquivos Modificados
- `scripts/bed_interaction.gd` - Função `_input()`
- `scripts/double_bed.gd` - Função `_input()`
- `scripts/map_2_controller.gd` - Função `_input()`

## Diferença Entre os Métodos
- `event.is_action_pressed()` - **NÃO EXISTE** para objetos InputEvent
- `Input.is_action_pressed()` - Verifica se a ação está sendo pressionada (contínuo)
- `Input.is_action_just_pressed()` - Verifica se a ação foi pressionada neste frame (único)

## Resultado
✅ A interação com a cama agora funciona corretamente
✅ Não há mais erros ao pressionar E perto da cama
✅ A transição para map_2.tscn funciona normalmente
✅ O sistema de pause no map_2 funciona corretamente com a tecla ESC

## Observações Técnicas
- Usamos `is_action_just_pressed()` em vez de `is_action_pressed()` para evitar múltiplas ativações
- O método `Input.is_action_just_pressed()` é mais apropriado para interações que devem ocorrer apenas uma vez por pressionar da tecla
- Esta correção mantém toda a funcionalidade existente, apenas corrige o método de detecção de input 