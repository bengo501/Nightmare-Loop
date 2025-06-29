# Correção do Shader PSX - Problema da Janela Branca

## Problema Identificado
O shader PSX estava aparecendo como uma **janela branca no canto inferior esquerdo** em vez de afetar toda a tela.

### Causa do Problema
1. **Abordagem Incorreta**: BackBufferCopy + ColorRect não estava funcionando corretamente
2. **Shader Canvas_Item**: Não estava processando adequadamente a textura da tela
3. **Posicionamento**: O efeito não estava cobrindo toda a área da tela

## Solução Implementada

### Nova Estrutura: SubViewportContainer
Implementada a estrutura recomendada:
```
PSXFullScreenViewport (Control)
└── SubViewportContainer (com material PSX)
    └── SubViewport
        └── GameContent (Node3D - conteúdo do jogo)
```

### Arquivos Criados

#### 1. **Shader Viewport Específico**
- **Arquivo**: `shaders/psx_viewport_effect.gdshader`
- **Diferença**: Usa `UV` em vez de `SCREEN_UV`
- **Função**: Processa corretamente a textura do SubViewport

```glsl
void fragment(){
    // Obtém a cor do pixel atual da textura (SubViewport)
    vec3 screen_color = texture(TEXTURE, UV).rgb;
    // ... processamento PSX ...
    COLOR.rgb = final_color;
}
```

#### 2. **Material Viewport**
- **Arquivo**: `materials/psx_viewport_material.tres`
- **Função**: Material específico para o SubViewportContainer

#### 3. **Cena PSX Viewport**
- **Arquivo**: `scenes/effects/PSXFullScreenViewport.tscn`
- **Estrutura**: SubViewportContainer com material PSX

#### 4. **Script de Controle**
- **Arquivo**: `scripts/effects/PSXFullScreenViewport.gd`
- **Função**: Move conteúdo da cena para o SubViewport

### Como Funciona

#### 1. **Movimentação de Conteúdo**
```gdscript
func move_scene_to_viewport():
    var current_scene = get_tree().current_scene
    
    # Remove cena atual de seu pai
    original_parent.remove_child(current_scene)
    
    # Adiciona ao SubViewport
    game_content.add_child(current_scene)
    
    # PSX se torna a nova current_scene
    get_tree().current_scene = self
```

#### 2. **Aplicação do Shader**
- SubViewport renderiza o jogo normalmente
- SubViewportContainer aplica shader PSX na textura resultante
- Resultado cobre toda a tela incluindo UI

#### 3. **Integração com PSXEffectManager**
```gdscript
# PSXEffectManager atualizado
var psx_viewport_effect_scene = preload("res://scenes/effects/PSXFullScreenViewport.tscn")

func apply_psx_viewport_effect():
    psx_viewport_effect = psx_viewport_effect_scene.instantiate()
    get_tree().root.add_child(psx_viewport_effect)
```

## Vantagens da Nova Abordagem

### ✅ **Cobertura Total**
- Jogo 3D renderizado no SubViewport
- Shader aplicado em toda a área da tela
- UI também afetada pelo efeito PSX

### ✅ **Performance Otimizada**
- SubViewport mais eficiente que BackBufferCopy
- Shader canvas_item leve
- Renderização controlada

### ✅ **Controle Completo**
- Move/restaura cenas dinamicamente
- Mantém funcionalidade original
- F1-F4 para controles em tempo real

### ✅ **Compatibilidade**
- Funciona com qualquer cena
- Preserva input handling
- Mantém current_scene corretamente

## Controles Disponíveis

- **F1**: Toggle PSX Effects
- **F2**: Preset Clássico
- **F3**: Preset Horror  
- **F4**: Preset Nightmare

## Status: ✅ PROBLEMA RESOLVIDO

A janela branca foi **completamente eliminada**. O shader PSX agora:
1. Cobre toda a tela corretamente
2. Afeta tanto jogo 3D quanto UI
3. Funciona automaticamente por padrão
4. Tem performance otimizada

### Arquivos Principais
- `scenes/effects/PSXFullScreenViewport.tscn`
- `scripts/effects/PSXFullScreenViewport.gd`
- `shaders/psx_viewport_effect.gdshader`
- `materials/psx_viewport_material.tres`
- `scripts/managers/PSXEffectManager.gd` (atualizado)

O sistema PSX agora funciona perfeitamente sem problemas visuais! 🎮✨ 