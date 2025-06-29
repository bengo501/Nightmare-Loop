# Sistema PSX UI Completo - Implementação

## Visão Geral
Sistema PSX que afeta **toda a tela** incluindo jogo e interfaces de usuário, aplicado **automaticamente por padrão** no Nightmare Loop.

## Arquivos Criados/Modificados

### 1. **Shader PSX UI**
- **Arquivo**: `shaders/psx_ui_effect.gdshader`
- **Tipo**: `shader_type canvas_item`
- **Função**: Shader que processa toda a tela incluindo UI

**Características:**
- Fog/Névoa com cores customizáveis
- Noise/Ruído animado
- Color Limitation (redução de cores)
- Dithering para efeito retro
- Funciona com SCREEN_UV para capturar tela completa

### 2. **Material PSX UI**
- **Arquivo**: `materials/psx_ui_material.tres`
- **Função**: Material que usa o shader PSX UI
- **Parâmetros Padrão**:
  - `fog_color`: Vector3(0.3, 0.3, 0.5)
  - `color_levels`: 16
  - `dither_strength`: 0.5

### 3. **Cena PSX UI Effect**
- **Arquivo**: `scenes/effects/PSXUIEffect.tscn`
- **Estrutura**:
  ```
  PSXUIEffect (CanvasLayer, layer=1000)
  ├── BackBufferCopy
  └── PSXOverlay (ColorRect com material PSX)
  ```

### 4. **Script PSX UI Effect**
- **Arquivo**: `scripts/effects/PSXUIEffect.gd`
- **Função**: Controla o efeito PSX UI

**Funcionalidades:**
- Configuração automática do material
- 3 presets: Clássico, Horror, Nightmare
- Controles em tempo real (F1-F4)
- Toggle on/off dos efeitos

### 5. **PSXEffectManager Atualizado**
- **Arquivo**: `scripts/managers/PSXEffectManager.gd`
- **Função**: Gerencia e aplica PSX automaticamente

**Melhorias:**
- Aplica PSX UI Effect por padrão
- Integração com sistema de autoload
- Controle completo via F1-F5

## Como Funciona

### 1. **Inicialização Automática**
```gdscript
# PSXEffectManager._ready()
func _ready():
    # Aguarda cena carregar
    await get_tree().process_frame
    
    # Aplica PSX por padrão
    apply_psx_effects()
```

### 2. **Aplicação do Efeito UI**
```gdscript
func apply_psx_ui_effect():
    # Instancia PSXUIEffect
    psx_ui_effect = psx_ui_effect_scene.instantiate()
    
    # Adiciona ao topo da árvore (layer 1000)
    get_tree().root.add_child(psx_ui_effect)
```

### 3. **Captura de Tela Completa**
```glsl
// No shader
void fragment(){
    vec3 screen_color = texture(TEXTURE, SCREEN_UV).rgb;
    // Processa toda a tela incluindo UI
    COLOR.rgb = final_color;
}
```

## Controles Disponíveis

### **F1** - Toggle PSX Effects
- Liga/desliga todos os efeitos PSX
- Mantém environment mas remove shader UI

### **F2** - Preset Clássico
- Fog: Azul acinzentado (0.3, 0.3, 0.5)
- 16 níveis de cor
- Dithering médio (0.5)

### **F3** - Preset Horror
- Fog: Vermelho escuro (0.2, 0.1, 0.1)
- 12 níveis de cor
- Dithering forte (0.7)

### **F4** - Preset Nightmare
- Fog: Roxo escuro (0.1, 0.05, 0.2)
- 8 níveis de cor
- Dithering muito forte (0.8)

### **F5** - Debug Camera Info
- Lista todas as câmeras encontradas
- Mostra status dos environments
- Informações de debug completas

## Integração com o Jogo

### **Autoload Configuration**
```ini
# project.godot
[autoload]
PSXEffectManager="*res://scripts/managers/PSXEffectManager.gd"
```

### **Aplicação Automática**
O sistema PSX é aplicado automaticamente quando:
1. Qualquer cena é carregada
2. PSXEffectManager._ready() é executado
3. Efeito UI é instanciado e adicionado à árvore

### **Compatibilidade**
- ✅ **Jogo 3D**: Environment + fog aplicados às câmeras
- ✅ **Interfaces 2D**: Shader UI afeta menus, HUD, etc.
- ✅ **Todas as cenas**: Funciona em world.tscn, map_2.tscn, etc.
- ✅ **Performance**: BackBufferCopy otimizado

## Vantagens do Sistema

### **1. Cobertura Total**
- Jogo 3D: Environment PSX nas câmeras
- UI/Menus: Shader canvas_item na tela toda
- Sem áreas não cobertas

### **2. Performance Otimizada**
- BackBufferCopy eficiente
- Shader canvas_item leve
- Layer 1000 garante renderização correta

### **3. Controle Completo**
- Toggle em tempo real
- Múltiplos presets
- Configuração granular

### **4. Integração Transparente**
- Autoload automático
- Sem necessidade de configuração manual
- Funciona em todas as cenas

## Troubleshooting

### **PSX não aparece**
1. Verificar se PSXEffectManager está no autoload
2. Verificar console para mensagens de erro
3. Testar F1 para toggle manual

### **UI não afetada**
1. Verificar se BackBufferCopy está ativo
2. Verificar layer 1000 do CanvasLayer
3. Verificar material PSX UI

### **Performance baixa**
1. Reduzir dither_strength
2. Desabilitar noise temporariamente
3. Verificar resolução da tela

## Arquivos de Referência

### **Principais**
- `shaders/psx_ui_effect.gdshader`
- `materials/psx_ui_material.tres`
- `scenes/effects/PSXUIEffect.tscn`
- `scripts/effects/PSXUIEffect.gd`
- `scripts/managers/PSXEffectManager.gd`

### **Ambientes**
- `environments/psx_environment.tres`

### **Configuração**
- `project.godot` (autoload)

---

## Status: ✅ IMPLEMENTADO E ATIVO

O sistema PSX UI está **totalmente implementado** e **ativo por padrão** no Nightmare Loop. Todos os jogadores verão os efeitos PSX automaticamente, incluindo nas interfaces de usuário. 