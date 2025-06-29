# Estrutura Final PSX + CRT - CanvasLayer

## Estrutura da Árvore de Nós

```
PSXWithCRT (Control)
├── SubViewportContainer (Material PSX)
│   └── SubViewport
│       └── GameContent (Node3D)
│           └── [CONTEÚDO DO JOGO]
└── CRTEffect (CanvasLayer - layer 1001)
    ├── BackBufferCopy
    └── CRTOverlay (ColorRect - Material CRT)
```

## Como Funciona

### 1. **Camada PSX (SubViewportContainer)**
- **Material**: `psx_viewport_material.tres`
- **Shader**: `psx_viewport_effect.gdshader`
- **Função**: Aplica efeitos PSX (fog, dithering, color limitation) no conteúdo 3D
- **Posição**: Renderiza primeiro, como base

### 2. **Camada CRT (CanvasLayer)**
- **Material**: `crt_monitor_material.tres`
- **Shader**: `crt_monitor_effect.gdshader`
- **Função**: Aplica efeitos CRT (wiggle, scanlines, chromatic aberration) por cima
- **Posição**: Layer 1001 - renderiza por último, sobre tudo

## Fluxo de Renderização

1. **Jogo renderiza** dentro do `SubViewport`
2. **PSX shader processa** o viewport via `SubViewportContainer.material`
3. **BackBufferCopy captura** toda a tela (PSX + jogo)
4. **CRT shader processa** a captura via `screen_texture` uniform
5. **Resultado final** = Jogo + PSX + CRT

## Vantagens da Estrutura

### ✅ **Compatibilidade Total**
- PSX funciona com qualquer conteúdo 3D
- CRT funciona com qualquer tela (inclusive UI)
- Ambos podem ser ligados/desligados independentemente

### ✅ **Performance Otimizada**
- PSX processa apenas o viewport 3D
- CRT processa apenas uma vez por frame
- BackBufferCopy eficiente para captura de tela

### ✅ **Controle Granular**
- Cada shader tem seus próprios parâmetros
- Presets independentes para PSX e CRT
- Toggle individual via F1/F6

## Arquivos da Implementação

### Cenas
- `scenes/effects/PSXWithCRT.tscn` - Cena principal
- `scenes/effects/PSXFullScreenViewport.tscn` - Versão só PSX (backup)

### Scripts
- `scripts/effects/PSXWithCRT.gd` - Controlador principal
- `scripts/managers/PSXEffectManager.gd` - Autoload manager

### Shaders
- `shaders/psx_viewport_effect.gdshader` - Efeitos PSX
- `shaders/crt_monitor_effect.gdshader` - Efeitos CRT

### Materiais
- `materials/psx_viewport_material.tres` - Material PSX
- `materials/crt_monitor_material.tres` - Material CRT

## Controles

### PSX Effects
- **F1**: Toggle PSX On/Off
- **F2**: PSX Clássico (azul-cinza)
- **F3**: PSX Horror (vermelho escuro)
- **F4**: PSX Nightmare (roxo escuro)

### CRT Effects
- **F6**: Toggle CRT On/Off
- **F7**: CRT Vintage (forte)
- **F8**: CRT Moderno (sutil)
- **F9**: CRT Forte (intenso)

## Configuração no Projeto

### AutoLoad (project.godot)
```ini
[autoload]
PSXEffectManager="*res://scripts/managers/PSXEffectManager.gd"
```

### Ativação Automática
O sistema se ativa automaticamente quando o jogo inicia, aplicando:
- PSX Clássico preset
- CRT Clássico preset

## Parâmetros Configuráveis

### PSX Parameters
- `fog_color`: Cor da névoa
- `noise_color`: Cor do ruído
- `fog_distance`: Distância da névoa
- `color_levels`: Níveis de cor (8-16)
- `dither_strength`: Força do dithering

### CRT Parameters
- `wiggle_strength`: Intensidade do tremor
- `wiggle_speed`: Velocidade do tremor
- `chromatic_aberration`: Aberração cromática
- `scanline_intensity`: Intensidade das scanlines
- `vignette_strength`: Força da vinheta
- `brightness`: Brilho geral

## Integração com Cenas Existentes

O sistema funciona automaticamente com:
- `world.tscn`
- `map_2.tscn`
- Qualquer cena 3D do jogo

Não requer modificações nas cenas existentes - o PSXEffectManager move automaticamente o conteúdo para dentro do sistema de efeitos.

## Troubleshooting

### Se CRT não aparecer:
1. Verifique se `CRTEffect.visible = true`
2. Pressione F6 para toggle
3. Teste presets F7-F9

### Se PSX não aparecer:
1. Verifique material no SubViewportContainer
2. Pressione F1 para toggle
3. Teste presets F2-F4

### Performance:
- Sistema otimizado para 60fps
- Se necessário, reduza `color_levels` PSX
- Diminua `wiggle_strength` CRT 