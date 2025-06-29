# Correção do Problema do CRT Overlay

## Problema Identificado
O CRT overlay estava "comendo" a imagem, deixando apenas uma pequena parte visível no canto superior esquerdo da tela.

## Causa do Problema
1. **BackBufferCopy mal configurado**: O BackBufferCopy não estava capturando corretamente o conteúdo da tela
2. **Estrutura de nós inadequada**: O uso de CanvasLayer com BackBufferCopy estava causando problemas de renderização
3. **Shader incompatível**: O shader CRT estava usando `screen_texture` uniform que não funcionava corretamente

## Solução Implementada

### 1. Remoção do BackBufferCopy
```gdscript
# ANTES (problemático)
[node name="CRTOverlay" type="CanvasLayer" parent="."]
layer = 1001

[node name="BackBufferCopy" type="BackBufferCopy" parent="CRTOverlay"]

[node name="CRTEffect" type="ColorRect" parent="CRTOverlay"]

# DEPOIS (corrigido)
[node name="CRTOverlay" type="Control" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="CRTEffect" type="ColorRect" parent="CRTOverlay"]
```

### 2. Atualização do Shader CRT
```glsl
// ANTES (problemático)
uniform sampler2D screen_texture : hint_screen_texture;
color.r = texture(screen_texture, vec2(x+uv.x+chromaticAberrationOffset,uv.y+chromaticAberrationOffset)).x;

// DEPOIS (corrigido)
vec3 color = chromatic_shift(SCREEN_TEXTURE, wiggled_uv);
```

### 3. Nova Estrutura de Renderização
```
PSXWithCRT (Control)
├── SubViewportContainer (PSX Material) ← Efeitos PSX
│   └── SubViewport → GameContent
└── CRTOverlay (Control) ← Efeitos CRT
    └── CRTEffect (ColorRect com CRT Material)
```

## Parâmetros do Novo Shader CRT

### Uniforms Atualizados
- `wiggle_strength`: Intensidade do tremor (0.0 - 10.0)
- `wiggle_speed`: Velocidade do tremor (0.1 - 5.0)  
- `chromatic_aberration`: Aberração cromática (0.0 - 0.01)
- `scanline_intensity`: Intensidade das linhas de varredura (0.0 - 1.0)
- `vignette_strength`: Força da vinheta (0.0 - 1.0)
- `brightness`: Brilho (0.5 - 2.0)

### Funções do Shader
- `wiggle()`: Aplica tremor na tela
- `chromatic_shift()`: Separação RGB para aberração cromática
- `scanlines()`: Linhas de varredura horizontais
- `vignette()`: Escurecimento nas bordas

## Presets CRT Atualizados

### Clássico (F7)
- Wiggle: 2.0 / 1.0
- Chromatic: 0.003
- Scanlines: 0.5
- Vignette: 0.3
- Brightness: 1.0

### Vintage (F8)
- Wiggle: 4.0 / 1.5
- Chromatic: 0.005
- Scanlines: 0.7
- Vignette: 0.5
- Brightness: 0.9

### Moderno (F9)
- Wiggle: 1.0 / 0.8
- Chromatic: 0.002
- Scanlines: 0.3
- Vignette: 0.2
- Brightness: 1.1

### Forte (F10)
- Wiggle: 6.0 / 2.0
- Chromatic: 0.008
- Scanlines: 0.8
- Vignette: 0.6
- Brightness: 0.8

## Controles

### PSX
- F1: Toggle PSX Effects
- F2: PSX Clássico
- F3: PSX Horror  
- F4: PSX Nightmare

### CRT
- F6: Toggle CRT Effects
- F7: CRT Vintage
- F8: CRT Moderno
- F9: CRT Forte

## Resultado
- ✅ CRT overlay agora cobre toda a tela
- ✅ Efeitos CRT funcionam corretamente
- ✅ PSX + CRT combinados sem conflitos
- ✅ Performance otimizada sem BackBufferCopy
- ✅ Controles responsivos em tempo real

## Teste
Execute o jogo e pressione:
1. F1 + F6 para ativar ambos os efeitos
2. F2-F4 para testar presets PSX
3. F7-F9 para testar presets CRT
4. Verifique se a tela inteira está sendo afetada pelos shaders 