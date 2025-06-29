# Sistema PSX + CRT Completo - Implementação

## Visão Geral
Sistema completo que combina **efeitos PSX** (retrô PlayStation) com **efeitos CRT** (monitor vintage) aplicados automaticamente por padrão no Nightmare Loop.

### Estrutura de Camadas
```
PSXWithCRT (Control)
├── SubViewportContainer (Material PSX)
│   └── SubViewport
│       └── GameContent (jogo renderizado)
└── CRTOverlay (CanvasLayer, layer=1001)
    ├── BackBufferCopy
    └── CRTEffect (ColorRect com Material CRT)
```

## Arquivos Criados

### 1. **Shader CRT Monitor**
- **Arquivo**: `shaders/crt_monitor_effect.gdshader`
- **Tipo**: `shader_type canvas_item`
- **Função**: Simula efeitos de monitor CRT vintage

**Características CRT:**
- **Wiggle**: Tremulação da tela simulando instabilidade
- **Chromatic Aberration**: Separação de cores RGB
- **Scanlines**: Linhas horizontais animadas
- **Vignette**: Escurecimento das bordas
- **Brightness Control**: Controle de brilho

### 2. **Material CRT**
- **Arquivo**: `materials/crt_monitor_material.tres`
- **Parâmetros Padrão**:
  - `brightnessMult`: 4.0
  - `wiggleMult`: 0.005
  - `chromaticAberrationOffset`: 0.001

### 3. **Cena PSX + CRT**
- **Arquivo**: `scenes/effects/PSXWithCRT.tscn`
- **Estrutura**:
  ```
  PSXWithCRT (Control)
  ├── SubViewportContainer (PSX Material)
  │   └── SubViewport → GameContent
  └── CRTOverlay (layer 1001)
      ├── BackBufferCopy
      └── CRTEffect (CRT Material)
  ```

### 4. **Script Controlador**
- **Arquivo**: `scripts/effects/PSXWithCRT.gd`
- **Função**: Controla ambos os efeitos simultaneamente

### 5. **PSXEffectManager Atualizado**
- **Arquivo**: `scripts/managers/PSXEffectManager.gd`
- **Função**: Aplica PSX + CRT automaticamente

## Como Funciona

### 1. **Renderização em Camadas**
```gdscript
# Camada 1: Jogo renderizado no SubViewport
SubViewport → GameContent (cena do jogo)

# Camada 2: Shader PSX aplicado
SubViewportContainer.material → PSX effects

# Camada 3: Shader CRT aplicado por cima
CRTOverlay (layer 1001) → CRT effects
```

### 2. **Fluxo de Processamento**
1. **Jogo 3D**: Renderizado normalmente no SubViewport
2. **PSX Effects**: Aplicados na textura do viewport (fog, dithering, color reduction)
3. **CRT Effects**: Aplicados na tela final (scanlines, wiggle, chromatic aberration)
4. **Resultado**: Visual retrô completo com monitor vintage

### 3. **Movimentação de Cena**
```gdscript
func move_scene_to_viewport():
    # Remove cena atual de seu pai
    original_parent.remove_child(current_scene)
    
    # Move para o SubViewport
    game_content.add_child(current_scene)
    
    # PSX+CRT se torna a current_scene
    get_tree().current_scene = self
```

## Controles Disponíveis

### **Efeitos PSX (F1-F4)**
- **F1**: Toggle PSX Effects (liga/desliga PSX)
- **F2**: Preset PSX Clássico (azul acinzentado)
- **F3**: Preset PSX Horror (vermelho escuro)
- **F4**: Preset PSX Nightmare (roxo escuro)

### **Efeitos CRT (F6-F9)**
- **F6**: Toggle CRT Effects (liga/desliga CRT)
- **F7**: CRT Vintage (efeito forte, mais tremulação)
- **F8**: CRT Modern (efeito sutil, menos tremulação)
- **F9**: CRT Strong (efeito intenso, máxima tremulação)

### **Debug (F5)**
- **F5**: Debug Camera Info (informações das câmeras)

## Presets CRT Detalhados

### **CRT Clássico (Padrão)**
```gdscript
brightness_mult = 4.0
wiggle_mult = 0.005
chromatic_aberration_offset = 0.001
```

### **CRT Vintage (F7)**
```gdscript
brightness_mult = 3.5        # Mais escuro
wiggle_mult = 0.008          # Mais tremulação
chromatic_aberration_offset = 0.002  # Mais aberração
```

### **CRT Modern (F8)**
```gdscript
brightness_mult = 4.5        # Mais brilhante
wiggle_mult = 0.002          # Menos tremulação
chromatic_aberration_offset = 0.0005  # Menos aberração
```

### **CRT Strong (F9)**
```gdscript
brightness_mult = 3.0        # Muito escuro
wiggle_mult = 0.01           # Tremulação intensa
chromatic_aberration_offset = 0.003  # Aberração forte
```

## Integração com o Jogo

### **Aplicação Automática**
```gdscript
# PSXEffectManager._ready()
func _ready():
    # Aplica PSX + CRT por padrão
    apply_psx_effects()

func apply_psx_effects():
    # 1. Configurações de renderização
    apply_render_settings()
    
    # 2. Environment PSX nas câmeras 3D
    apply_psx_environment()
    
    # 3. Configurações de projeto
    apply_project_settings()
    
    # 4. Aplica efeito PSX + CRT
    apply_psx_crt_effect()
```

### **Autoload Configuration**
```ini
# project.godot
[autoload]
PSXEffectManager="*res://scripts/managers/PSXEffectManager.gd"
```

## Vantagens do Sistema Combinado

### ✅ **Autenticidade Visual**
- **PSX**: Fog, dithering, color reduction como PS1 real
- **CRT**: Scanlines, wiggle, chromatic aberration como TVs antigas
- **Combinação**: Visual autêntico dos anos 90

### ✅ **Controle Granular**
- **Independente**: PSX e CRT podem ser ligados/desligados separadamente
- **Presets**: 3 presets PSX + 4 presets CRT = 12 combinações
- **Tempo Real**: Todos os ajustes via F1-F9

### ✅ **Performance Otimizada**
- **SubViewport**: Renderização eficiente
- **Shaders Leves**: Canvas_item otimizados
- **Camadas**: Processamento em paralelo

### ✅ **Compatibilidade Total**
- **Jogo 3D**: Environment PSX + viewport rendering
- **UI 2D**: Ambos shaders afetam interfaces
- **Todas as Cenas**: Funciona automaticamente

## Efeitos Visuais Detalhados

### **PSX Effects (Camada Base)**
1. **Fog/Névoa**: Cores customizáveis por preset
2. **Noise/Ruído**: Animado e sincronizado
3. **Color Limitation**: 8-16 níveis de cor
4. **Dithering**: Pontilhado retrô

### **CRT Effects (Camada Superior)**
1. **Wiggle**: `sin(TIME)` para tremulação realista
2. **Chromatic Aberration**: Separação RGB offset
3. **Scanlines**: `sin(uv.y * resolution)` animadas
4. **Vignette**: Escurecimento radial das bordas

## Troubleshooting

### **PSX não aparece**
1. Verificar F1 (toggle PSX)
2. Testar F2-F4 (presets PSX)
3. Verificar console para erros

### **CRT não aparece**
1. Verificar F6 (toggle CRT)
2. Testar F7-F9 (presets CRT)
3. Verificar se CRTOverlay está visível

### **Performance baixa**
1. Desabilitar CRT temporariamente (F6)
2. Usar preset CRT Modern (F8) - mais leve
3. Reduzir wiggle_mult e chromatic_aberration

### **Efeitos muito fortes**
1. CRT Modern (F8) para efeito sutil
2. PSX Clássico (F2) para PSX suave
3. Ajustar parâmetros individualmente

## Arquivos de Referência

### **Principais**
- `scenes/effects/PSXWithCRT.tscn`
- `scripts/effects/PSXWithCRT.gd`
- `shaders/crt_monitor_effect.gdshader`
- `materials/crt_monitor_material.tres`
- `scripts/managers/PSXEffectManager.gd` (atualizado)

### **PSX (mantidos)**
- `shaders/psx_viewport_effect.gdshader`
- `materials/psx_viewport_material.tres`
- `environments/psx_environment.tres`

---

## Status: ✅ IMPLEMENTADO E ATIVO

O sistema **PSX + CRT** está **totalmente implementado** e **ativo por padrão** no Nightmare Loop. 

### **Visual Final:**
- **Base**: Jogo 3D com environment PSX
- **Camada 1**: Shader PSX (fog, dithering, color reduction)
- **Camada 2**: Shader CRT (scanlines, wiggle, chromatic aberration)
- **Resultado**: Visual autêntico dos anos 90 com monitor vintage! 📺🎮✨ 