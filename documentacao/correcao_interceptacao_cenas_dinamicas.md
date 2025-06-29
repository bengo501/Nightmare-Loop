# Correção: Interceptação de Cenas Dinâmicas no GlobalPSXManager

## Problema Identificado

As cenas carregadas dinamicamente pelo SceneManager (como `world.tscn`, `map_2.tscn`, etc.) não estavam sendo movidas para dentro do `GameContent`, ficando diretamente no `Root` e não sendo afetadas pelos efeitos PSX.

### Sintomas:
- Splash screen sempre carregada
- Novas cenas aparecendo fora do GameContent
- Efeitos PSX não aplicados às cenas do jogo
- Estrutura de árvore incorreta

## Causa Raiz

O `GlobalPSXManager` só movia as cenas que já existiam no momento da inicialização, mas não interceptava novas cenas adicionadas dinamicamente pelo `SceneManager`.

### Fluxo Problemático:
1. GlobalPSXManager inicializa e move cenas existentes
2. SceneManager carrega nova cena com `get_tree().root.add_child()`
3. Nova cena fica no Root (fora do GameContent)
4. Efeitos PSX não são aplicados

## Solução Implementada

### 1. Interceptação Automática
Adicionado sistema de interceptação que monitora quando novos nós são adicionados ao Root:

```gdscript
# Conecta ao sinal de nós adicionados
get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node):
    # Verifica se o nó foi adicionado diretamente ao root
    if node.get_parent() == get_tree().root:
        # Move automaticamente para GameContent
        if should_move_node(node):
            move_to_game_content(node)
```

### 2. Controle de Estado
Adicionada variável `is_intercepting` para controlar quando a interceptação deve estar ativa:

```gdscript
var is_intercepting: bool = false

# Ativa após configurar a estrutura
is_intercepting = true
```

### 3. Filtros Aprimorados
Expandida lista de autoloads para evitar mover nós do sistema:

```gdscript
var autoload_names = [
    "SceneManager", "LucidityManager", "GiftManager", "SkillManager",
    "PlayerReferenceManager", "PSXEffectManager", "GlobalPSXManager",
    "GameManager", "GameStateManager", "UIManager", "TransitionManager"
]
```

### 4. Debug Aprimorado
Melhorado sistema de debug para mostrar a localização atual das cenas:

```gdscript
print("🎯 Current Scene: ", get_tree().current_scene.name)
print("📍 Current Scene Parent: ", get_tree().current_scene.get_parent().name)
```

## Fluxo Corrigido

### Inicialização:
1. GlobalPSXManager cria estrutura PSX
2. Move cenas existentes para GameContent
3. Ativa interceptação automática

### Mudança de Cena:
1. SceneManager adiciona nova cena ao Root
2. GlobalPSXManager detecta via `node_added`
3. Automaticamente move a cena para GameContent
4. Efeitos PSX são aplicados corretamente

## Estrutura Final Garantida

```
Root
├── GlobalPSXManager (autoload)
├── PSXEffect (Control)
│   └── SubViewportContainer (com material PSX)
│       └── SubViewport
│           └── GameContent (Node)
│               ├── SplashScreen (inicial)
│               ├── MainMenu (quando carregado)
│               ├── World (quando carregado)
│               ├── Map2 (quando carregado)
│               └── [qualquer outra cena]
└── CRTOverlay (CanvasLayer layer=1001)
```

## Controles de Debug

- **F5**: Mostra estrutura atual completa no console

## Benefícios da Correção

✅ **Interceptação Automática**: Todas as novas cenas são automaticamente movidas
✅ **Efeitos Sempre Aplicados**: PSX funciona em todas as cenas
✅ **Estrutura Consistente**: Árvore sempre organizada corretamente
✅ **Compatibilidade Total**: Funciona com SceneManager existente
✅ **Debug Aprimorado**: Melhor visibilidade da estrutura

## Arquivos Modificados

- `scripts/managers/GlobalPSXManager.gd` - Implementação da interceptação
- `documentacao/correcao_interceptacao_cenas_dinamicas.md` - Esta documentação

A correção garante que todas as cenas carregadas dinamicamente sejam automaticamente organizadas na estrutura PSX correta, mantendo os efeitos visuais funcionando em todo o jogo. 