# Correção do Erro: reset_game null instance

## Problema
Erro: "Attempt to call function 'reset_game' in base 'null instance' on a null instance"

## Causa
1. Caminhos incorretos nos autoloads do project.godot
2. Falta de verificação de null nos scripts
3. Arquivo inexistente (damage_counter_manager.gd)

## Correções

### 1. Autoloads Corrigidos (project.godot)
```
ANTES:
GameManager="*res://scripts/managers/GameManager.gd"
GameStateManager="*res://scripts/managers/GameStateManager.gd"
UIManager="*res://scripts/managers/UIManager.gd"
SceneManager="*res://scripts/managers/SceneManager.gd"
DamageCounterManager="*res://scripts/managers/damage_counter_manager.gd"

DEPOIS:
GameManager="*res://scripts/game_manager.gd"
GameStateManager="*res://scripts/game_state_manager.gd"
UIManager="*res://scripts/ui_manager.gd"
SceneManager="*res://scripts/scene_manager.gd"
# DamageCounterManager removido (não existe)
```

### 2. Null Safety Implementado
Arquivos corrigidos:
- scripts/world.gd
- scripts/ui/main_menu.gd
- scripts/game_manager.gd
- scripts/ui_manager.gd
- scripts/ui/pause_menu.gd
- scripts/ui/game_over.gd
- scripts/ui/options_menu.gd

ANTES:
```gdscript
@onready var game_manager = get_node("/root/GameManager")
game_manager.reset_game()  # ❌ Pode dar erro
```

DEPOIS:
```gdscript
@onready var game_manager = get_node_or_null("/root/GameManager")
if game_manager and game_manager.has_method("reset_game"):
    game_manager.reset_game()  # ✅ Seguro
```

### 3. Validação de Managers
```gdscript
func _validate_managers() -> bool:
    var missing_managers = []
    if not game_manager:
        missing_managers.append("GameManager")
    # ... outros managers
    
    if missing_managers.size() > 0:
        print("ERRO: Managers não encontrados: ", missing_managers)
        return false
    return true
```

## Resultado
✅ Erro eliminado
✅ Autoloads funcionando
✅ Código robusto
✅ Debug melhorado
✅ Fallbacks implementados 