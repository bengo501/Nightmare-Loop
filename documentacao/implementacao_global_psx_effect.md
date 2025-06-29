# Global PSX Effect - Nightmare Loop

## Resumo
Implementação de um sistema PSX global que afeta TODA a aplicação desde o início, incluindo splashscreen, main menu, slides, loading screens e jogo.

## Problema Anterior
- Efeitos PSX aplicados apenas nas cenas de jogo
- Splashscreen, main menu e slides sem efeito PSX
- Configuração manual em cada cena
- Inconsistência visual entre diferentes partes da aplicação

## Solução Implementada

### **GlobalPSXEffect Autoload**
- **Arquivo:** `scripts/managers/GlobalPSXEffect.gd`
- **Tipo:** Autoload (carregado automaticamente)
- **Prioridade:** Primeiro autoload (carrega antes de tudo)
- **Função:** Aplica shader PSX em nível global de aplicação

### **Características Principais**

#### 1. **Aplicação Global**
```gdscript
# Cria CanvasLayer global com prioridade máxima
global_canvas_layer.layer = 1000
global_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS

# ColorRect que cobre toda a tela
global_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
global_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

#### 2. **Configurações PSX Fortes**
- **Cores:** 10 níveis (drasticamente reduzido)
- **Dithering:** 0.75 (muito pronunciado)
- **Contraste:** 1.6 (alto)
- **Brilho:** 0.7 (reduzido - mais escuro)
- **Saturação:** 0.5 (bem reduzida)
- **Fog:** Horror vermelho escuro
- **Ruído:** Intenso (0.65)

#### 3. **Adaptabilidade a Diferentes Telas**
```gdscript
func adapt_to_screen_size():
    # Adapta automaticamente a:
    # - Fullscreen / Windowed
    # - Diferentes resoluções
    # - Modos de esticamento
    global_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
```

#### 4. **Persistência Entre Cenas**
```gdscript
# Mantém efeito ativo ao trocar cenas
get_tree().current_scene_changed.connect(_on_scene_changed)
get_tree().node_added.connect(_on_node_added)

# Sempre mantém prioridade máxima
global_canvas_layer.move_to_front()
```

## Arquivos Modificados/Criados

### 1. **Novo Autoload**
- `scripts/managers/GlobalPSXEffect.gd` - Sistema global PSX

### 2. **Project.godot Atualizado**
```ini
[autoload]
GlobalPSXEffect="*res://scripts/managers/GlobalPSXEffect.gd"  # PRIMEIRO
GameManager="*res://scripts/game_manager.gd"
# ... outros autoloads
```

### 3. **Material PSX Restaurado**
- `materials/psx_post_process_material.tres` - Parâmetros fortes restaurados

### 4. **Scripts Simplificados**
- `scripts/world.gd` - Removida configuração manual PSX
- `scripts/map_2_controller.gd` - Removida configuração manual PSX

## Funcionalidades

### **Cobertura Total da Aplicação**
✅ **Splashscreen** - Efeito PSX desde o primeiro frame
✅ **Main Menu** - Menu principal com visual PSX
✅ **Slides** - Apresentações com efeito PSX
✅ **Loading Screens** - Telas de carregamento com PSX
✅ **Jogo** - Todas as cenas de jogo com PSX
✅ **UI** - Interfaces afetadas pelo shader

### **Controles Globais**
- **F1:** Toggle PSX Effect (liga/desliga globalmente)
- **Funcionam em:** Qualquer tela da aplicação

### **Adaptabilidade**
- **Fullscreen:** Funciona perfeitamente
- **Windowed:** Adapta automaticamente
- **Diferentes resoluções:** Escala corretamente
- **Modos de stretch:** Compatível com todos

## Vantagens da Implementação

### 1. **Consistência Visual**
- Mesmo efeito PSX em toda a aplicação
- Experiência visual unificada
- Atmosfera horror mantida constantemente

### 2. **Simplicidade de Uso**
- Aplicação automática (não precisa configurar)
- Um único ponto de controle
- Sem duplicação de código

### 3. **Performance Otimizada**
- Um único CanvasLayer global
- Shader aplicado apenas uma vez
- Sem múltiplas instâncias

### 4. **Manutenibilidade**
- Configurações centralizadas
- Fácil de modificar globalmente
- Sem dependências entre cenas

## Configuração Técnica

### **Hierarquia Global**
```
Root (SceneTree)
└── GlobalPSXLayer (CanvasLayer - layer 1000)
    └── GlobalPSXRect (ColorRect - tela inteira)
        └── Material: psx_post_process_material.tres
```

### **Parâmetros do Shader**
```gdscript
enable_color_limitation = true
color_levels = 10                    # Muito reduzido
enable_dithering = true
dither_strength = 0.75               # Muito pronunciado
enable_fog = true
fog_color = Vector3(0.15, 0.1, 0.1)  # Vermelho escuro
fog_strength = 0.8                   # Forte
enable_noise = true
noise_strength = 0.65                # Intenso
enable_contrast_boost = true
contrast = 1.6                       # Alto
brightness = 0.7                     # Reduzido
saturation = 0.5                     # Bem reduzida
```

## Resultados Esperados

### **Visual**
- Efeito PSX forte e consistente em toda a aplicação
- Splashscreen com visual retrô desde o início
- Menus com atmosfera horror PSX
- Slides com dithering pronunciado
- Loading screens com estética autêntica

### **Experiência do Usuário**
- Imersão total na atmosfera PSX
- Transições suaves entre telas
- Controles intuitivos (F1 para toggle)
- Adaptação automática a qualquer configuração de tela

### **Performance**
- Impacto mínimo (um único shader global)
- Não afeta FPS significativamente
- Carregamento rápido do autoload

## Controles de Debug

### **F1 - Toggle Global**
- Liga/desliga efeito PSX em toda a aplicação
- Funciona em qualquer tela
- Útil para comparação visual

### **Logs de Debug**
```
🌍 Global PSX Effect inicializado!
🌍 PSX Effect global configurado!
🔄 PSX Effect mantido na nova cena
🌍 Global PSX Effect toggled
```

## Status: ✅ IMPLEMENTADO

- GlobalPSXEffect autoload criado
- Material PSX com parâmetros fortes restaurado
- Project.godot configurado com autoload prioritário
- Scripts world.gd e map_2_controller.gd simplificados
- Sistema adaptável a diferentes modos de tela
- Efeito aplicado desde splashscreen até jogo
- Controles globais funcionais
- Documentação completa criada

## Resultado Final
O jogo agora tem efeitos PSX fortes aplicados em TODA a aplicação desde o primeiro frame, incluindo splashscreen, menus, slides e loading screens, com adaptabilidade automática a diferentes configurações de tela. 