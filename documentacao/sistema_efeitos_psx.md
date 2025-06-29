# Sistema de Efeitos PSX - Nightmare Loop

## Visão Geral

Sistema completo de pós-processamento que simula o visual característico dos jogos de PlayStation 1, incluindo:
- Redução de cores (color quantization)
- Dithering para simular limitações de hardware
- Fog atmosférico com ruído
- Configurações de ambiente específicas
- Presets temáticos para diferentes atmosferas

## Arquivos Implementados

### 🎨 **Shaders e Materiais**
- `shaders/psx_post_process.gdshader` - Shader principal com todos os efeitos PSX
- `materials/psx_post_process_material.tres` - Material configurado com parâmetros PSX
- `environments/psx_environment.tres` - Environment otimizado para visual PSX

### 🎮 **Scripts e Cenas**
- `scripts/managers/PSXEffectManager.gd` - Gerenciador principal dos efeitos
- `scripts/effects/PSXPostProcess.gd` - Script para controle individual de efeitos
- `scenes/effects/PSXPostProcess.tscn` - Cena de pós-processamento

### ⚙️ **Integração**
- `project.godot` - PSXEffectManager adicionado como autoload
- `scripts/player/player.gd` - Controles PSX integrados aos cheats
- `scenes/ui/hud.tscn` - Controles PSX adicionados ao HUD

## Funcionalidades do Shader

### 🌫️ **Fog Atmosférico**
```glsl
uniform bool enable_fog = true;
uniform vec3 fog_color : source_color = vec3(0.4, 0.4, 0.6);
uniform float fog_distance : hint_range(1, 6000) = 150.0;
uniform float fog_fade_range : hint_range(1, 6000) = 75.0;
```

### 🎨 **Quantização de Cores**
```glsl
uniform bool enable_color_limitation = true;
uniform int color_levels : hint_range(2, 256) = 24;
```

### 📺 **Dithering**
```glsl
uniform bool enable_dithering = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.4;
```

### 🌊 **Ruído Temporal**
```glsl
uniform bool enable_noise = true;
uniform vec3 noise_color : source_color = vec3(0.2, 0.2, 0.4);
uniform float noise_time_fac : hint_range(0.1, 10) = 3.0;
```

## Controles Disponíveis

### 🎮 **Controles Principais**
- **F1** - Toggle PSX Mode (Liga/Desliga todos os efeitos)
- **F2** - Preset PSX Clássico
- **F3** - Preset PSX Horror
- **F4** - Preset PSX Nightmare

### 🎛️ **Presets Configurados**

#### **Clássico (F2)**
- Fog: Azul acinzentado suave
- Color Levels: 16 (simulando 16-bit)
- Dithering: Moderado (0.5)
- Atmosfera: Nostálgica e suave

#### **Horror (F3)**
- Fog: Vermelho escuro
- Color Levels: 12 (mais limitado)
- Dithering: Intenso (0.7)
- Atmosfera: Tensa e claustrofóbica

#### **Nightmare (F4)**
- Fog: Roxo escuro
- Color Levels: 8 (extremamente limitado)
- Dithering: Máximo (0.8)
- Atmosfera: Pesadelo intenso

## PSXEffectManager - Funcionalidades

### 🔧 **Configuração Automática**
```gdscript
func apply_psx_effects():
    # 1. Configurações de renderização
    apply_render_settings()
    # 2. Configurações de ambiente
    apply_psx_environment()
    # 3. Configurações de projeto
    apply_project_settings()
```

### 📷 **Aplicação por Cena**
```gdscript
func apply_psx_to_scene(scene_node: Node):
    # Encontra todas as câmeras na cena
    # Aplica environment PSX automaticamente
```

### 🎨 **Presets Dinâmicos**
```gdscript
func apply_classic_psx_preset()
func apply_horror_psx_preset()
func apply_nightmare_psx_preset()
```

## Integração com o Jogo

### 🎮 **Sistema de Cheats**
Os controles PSX foram integrados ao sistema de cheats existente:
```gdscript
# No player.gd
KEY_F1: cheat_toggle_psx_mode()
KEY_F2: cheat_psx_classic_preset()
KEY_F3: cheat_psx_horror_preset()
KEY_F4: cheat_psx_nightmare_preset()
```

### 🖥️ **HUD Atualizado**
Controles PSX adicionados ao painel de informações do HUD:
```
📺 EFEITOS PSX:
F1 - Toggle PSX Mode
F2 - Preset Clássico
F3 - Preset Horror
F4 - Preset Nightmare
```

### ⚡ **Autoload**
PSXEffectManager configurado como autoload para acesso global:
```
PSXEffectManager="*res://scripts/managers/PSXEffectManager.gd"
```

## Características Técnicas

### 🎨 **Algoritmo de Dithering**
- Matrix 4x4 de Bayer para padrões de dithering
- Aplicado baseado no brilho da imagem
- Controlável via `dither_strength`

### 🌫️ **Fog Baseado em Profundidade**
- Usa depth buffer para calcular distância
- Mistura cores de fog e noise dinamicamente
- Suporte a perspectiva aérea

### 🎨 **Quantização de Cores**
- Reduz paleta de cores para simular limitações de hardware
- Configurável de 2 a 256 níveis
- Mantém qualidade visual aceitável

### ⚡ **Performance**
- Shader otimizado para tempo real
- Toggles individuais para cada efeito
- Minimal overhead quando desabilitado

## Uso Recomendado

### 🎮 **Durante o Gameplay**
1. **F1** para ativar/desativar conforme preferência
2. **F2** para atmosfera geral do jogo
3. **F3** para momentos de tensão
4. **F4** para sequências de pesadelo/boss fights

### 🎨 **Para Desenvolvedores**
```gdscript
# Aplicar PSX a uma cena específica
var psx_manager = get_node("/root/PSXEffectManager")
psx_manager.apply_psx_to_scene(current_scene)

# Configurar preset específico
psx_manager.apply_horror_psx_preset()

# Ajustar parâmetros individualmente
psx_manager.set_fog_distance(120.0)
psx_manager.set_color_levels(16)
```

## Benefícios Implementados

### ✅ **Visual Autêntico**
- Simula fielmente limitações do PSX
- Dithering realista
- Fog atmosférico convincente

### ✅ **Flexibilidade**
- Controles em tempo real
- Múltiplos presets
- Configuração por cena

### ✅ **Performance**
- Shader otimizado
- Toggles individuais
- Minimal impact quando desabilitado

### ✅ **Integração**
- Sistema de cheats integrado
- HUD informativo
- Autoload para acesso global

## Arquivos Criados/Modificados

### ✅ **Novos Arquivos**
- `shaders/psx_post_process.gdshader`
- `materials/psx_post_process_material.tres`
- `environments/psx_environment.tres`
- `scripts/managers/PSXEffectManager.gd`
- `scripts/effects/PSXPostProcess.gd`
- `scenes/effects/PSXPostProcess.tscn`
- `documentacao/sistema_efeitos_psx.md`

### ✅ **Arquivos Modificados**
- `project.godot` - Autoload adicionado
- `scripts/player/player.gd` - Controles PSX integrados
- `scenes/ui/hud.tscn` - Controles PSX no HUD

## Conclusão

O sistema PSX está completamente implementado e pronto para uso, oferecendo uma experiência visual autêntica de PlayStation 1 com controles intuitivos e presets temáticos que complementam perfeitamente a atmosfera de horror do Nightmare Loop. 