# Estrutura Global PSX + CRT - Implementação Final

## Estrutura de Árvore

```
Root
├── GlobalPSXManager (autoload)
├── PSXEffect (Control)
│   └── SubViewportContainer (com material PSX)
│       └── SubViewport
│           └── GameContent (Node)
│               ├── GameManager
│               ├── GameStateManager
│               ├── UIManager
│               └── [outras cenas do jogo]
└── CRTOverlay (CanvasLayer layer=1001)
    ├── BackBufferCopy
    └── CRTEffect (ColorRect com material CRT)
```

## Arquivos Principais

### Scripts
- `scripts/managers/GlobalPSXManager.gd` - Gerenciador principal (autoload)
- `scripts/effects/PSXGlobalEffect.gd` - Controla efeitos PSX (sempre ativo)
- `scripts/effects/CRTOverlay.gd` - Controla efeitos CRT (opcional)

### Cenas
- `scenes/effects/PSXGlobalEffect.tscn` - Efeito PSX sempre ativo
- `scenes/effects/CRTOverlay.tscn` - Overlay CRT independente

### Materiais e Shaders
- `materials/psx_viewport_material.tres` - Material PSX
- `materials/crt_monitor_material.tres` - Material CRT
- `shaders/psx_viewport_effect.gdshader` - Shader PSX
- `shaders/crt_monitor_effect.gdshader` - Shader CRT

## Funcionamento

### Inicialização
1. GlobalPSXManager (autoload) é carregado automaticamente
2. Cria PSXEffect e adiciona ao Root
3. Move todas as cenas existentes para GameContent
4. Cria CRTOverlay e adiciona ao Root (por último)

### Efeitos PSX
- **Sempre ativos** por padrão
- Aplicados via SubViewportContainer com material PSX
- Afetam todo o conteúdo do jogo (3D + UI)

### Efeitos CRT
- **Opcionais** e controláveis
- Aplicados via CanvasLayer com BackBufferCopy
- Ficam por cima de tudo (layer 1001)

## Controles

### PSX (sempre ativo)
- **F2**: Preset PSX Clássico (azul-cinza)
- **F3**: Preset PSX Horror (vermelho escuro)
- **F4**: Preset PSX Nightmare (roxo escuro)

### CRT (opcional)
- **F6**: Liga/Desliga CRT
- **F7**: Preset CRT Moderno (sutil)
- **F8**: Preset CRT Vintage (médio)
- **F9**: Preset CRT Forte (intenso)

### Debug
- **F5**: Mostra estrutura atual no console

## Configuração no project.godot

```ini
[autoload]
GlobalPSXManager="*res://scripts/managers/GlobalPSXManager.gd"
```

## Correções Implementadas

### Problema: Script herda de RefCounted
**Solução**: Corrigido `scripts/effects/CRTOverlay.gd` para herdar de `CanvasLayer`

### Problema: Material CRT com parâmetros incorretos
**Solução**: Atualizado `materials/crt_monitor_material.tres` com parâmetros corretos do shader

### Problema: Estrutura de árvore incorreta
**Solução**: GlobalPSXManager implementa a estrutura exata solicitada

## Características

✅ **PSX sempre ativo** - Não precisa ativar manualmente
✅ **CRT opcional** - Pode ser ligado/desligado
✅ **Estrutura limpa** - Separação clara entre PSX e CRT
✅ **Compatibilidade total** - Funciona com todas as cenas existentes
✅ **Performance otimizada** - Usa SubViewport para PSX e CanvasLayer para CRT
✅ **Controles intuitivos** - F2-F4 para PSX, F6-F9 para CRT

## Fluxo de Aplicação

1. **Startup**: GlobalPSXManager cria estrutura automaticamente
2. **PSX**: Sempre aplicado via SubViewportContainer
3. **CRT**: Aplicado opcionalmente via CanvasLayer
4. **Game Content**: Todas as cenas do jogo ficam em GameContent
5. **UI**: Interfaces ficam dentro do PSX (afetadas pelos efeitos)

Esta implementação garante que:
- PSX está sempre ativo por padrão
- CRT pode ser ligado/desligado conforme necessário
- Estrutura de árvore é exatamente como solicitado
- Compatibilidade com todas as cenas existentes
- Performance otimizada para ambos os efeitos 