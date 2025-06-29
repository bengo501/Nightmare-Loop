# Correção do Fluxo de Recursão PSX+CRT

## Problema Identificado
O sistema estava criando recursão onde o PSXEffect ficava dentro do GameContent, quando deveria ficar apenas o conteúdo real do jogo (splashScreen, MainMenu, world, map_2, UIManager, etc.).

## Causa da Recursão
1. **PSXEffectManager aplicava múltiplos efeitos**: Aplicava tanto PSXFullScreenViewport quanto PSXWithCRT
2. **Movimento incorreto de cenas**: Movia qualquer cena atual, incluindo cenas de efeitos
3. **Falta de verificação de recursão**: Não verificava se estava movendo a si mesmo

## Estrutura Correta Implementada

### Árvore de Nós Final
```
PSXWithCRT (Control) ← Cena atual
├── SubViewportContainer (Material PSX)
│   └── SubViewport
│       └── GameContent (Node3D)
│           ├── world.tscn ← Cenas do jogo
│           ├── map_2.tscn
│           ├── splashScreen.tscn
│           ├── MainMenu.tscn
│           ├── UIManager
│           └── [Outras cenas do jogo]
└── CRTEffect (CanvasLayer - layer 1001)
    ├── BackBufferCopy
    └── CRTOverlay (ColorRect - Material CRT)
```

### Conteúdo que vai para GameContent
✅ **Deve ir para GameContent:**
- `world.tscn` - Mundo do jogo
- `map_2.tscn` - Mapa 2
- `splashScreen.tscn` - Tela de splash
- `MainMenu.tscn` - Menu principal
- `loading.tscn` - Tela de carregamento
- `UIManager` - Gerenciador de UI
- Diálogos, slides, etc.

❌ **NÃO deve ir para GameContent:**
- `PSXWithCRT` - Cena de efeitos
- `PSXFullScreenViewport` - Cena de efeitos
- Qualquer cena com "PSX" ou "CRT" no nome

## Correções Implementadas

### 1. PSXEffectManager.gd
```gdscript
# ANTES (problemático)
func apply_psx_effects():
    apply_psx_viewport_effect()  # ← Aplicava PSXFullScreenViewport
    apply_psx_crt_effect()       # ← E também PSXWithCRT (recursão!)

# DEPOIS (corrigido)
func apply_psx_effects():
    apply_psx_crt_effect()       # ← Aplica APENAS PSXWithCRT
```

### 2. PSXWithCRT.gd - move_scene_to_viewport()
```gdscript
# ANTES (problemático)
func move_scene_to_viewport():
    var current_scene = get_tree().current_scene
    if current_scene == self:
        return  # ← Só verificava se era ele mesmo
    game_content.add_child(current_scene)

# DEPOIS (corrigido)
func move_scene_to_viewport():
    var current_scene = get_tree().current_scene
    
    # Evita recursão - não move a si mesmo
    if current_scene == self:
        return
    
    # Evita mover cenas de efeitos
    if current_scene.name.contains("PSX") or current_scene.name.contains("CRT"):
        return
    
    # Verifica se já está no GameContent
    if current_scene.get_parent() == game_content:
        return
    
    # Move apenas cenas válidas do jogo
    game_content.add_child(current_scene)
```

## Resultado

### ✅ GameContent agora contém apenas:
- Cenas reais do jogo
- UIManager para interfaces
- Conteúdo que deve ser afetado pelos shaders

### ✅ Sem recursão:
- PSXWithCRT não se move para si mesmo
- Cenas de efeitos não são movidas
- Fluxo limpo e previsível

### ✅ Shaders funcionam corretamente:
- PSX afeta todo o conteúdo 3D no viewport
- CRT afeta toda a tela final
- UI também é afetada pelos shaders

## Debug e Verificação

### Logs de Debug
```
🎮 PSX Effect Manager inicializado!
📺 Aplicando PSX + CRT por padrão...
🎬 PSX + CRT Effect aplicado! (afeta jogo + UI)
🎬 Movendo cena para SubViewport: world
  📁 Cena original: world
  📍 Parent original: root
  ✅ Cena movida para GameContent!
  📺 PSXWithCRT agora é a cena atual
```

### Verificação Manual
1. Abra o Remote Inspector
2. Vá para PSXWithCRT > SubViewportContainer > SubViewport > GameContent
3. Deve conter apenas as cenas do jogo, sem PSXEffect aninhado

## Controles Funcionais

### PSX Effects
- **F1**: Toggle PSX On/Off
- **F2**: PSX Clássico
- **F3**: PSX Horror
- **F4**: PSX Nightmare

### CRT Effects
- **F6**: Toggle CRT On/Off
- **F7**: CRT Vintage
- **F8**: CRT Moderno
- **F9**: CRT Forte

Todos os controles agora funcionam corretamente sem recursão! 