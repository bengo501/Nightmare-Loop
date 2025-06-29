# Debug - Tela Branca PSX Shader - Nightmare Loop

## Problema
**Tela fica branca ao aplicar o shader PSX global**

## Análise do Problema

### **Causas Identificadas:**

1. **SCREEN_TEXTURE não declarado:** Shader tentava usar `SCREEN_TEXTURE` sem declaração `uniform`
2. **Falta de BackBufferCopy:** ColorRect sem captura de tela
3. **Parâmetros extremos:** Brilho/contraste causando tela muito escura
4. **Problemas de compatibilidade:** APIs antigas do Godot 3

## Correções Implementadas

### **1. Shader PSX Corrigido**
```gdscript
// ADICIONADO: Declaração explícita
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest, repeat_disable;

// ADICIONADO: Fallback para TEXTURE
vec4 original_color;
if (SCREEN_UV != vec2(0.0)) {
    original_color = texture(SCREEN_TEXTURE, screen_uv);
} else {
    original_color = texture(TEXTURE, UV);
}

// ADICIONADO: Debug para cor preta
if (length(final_color) < 0.001) {
    final_color = vec3(0.5, 0.5, 0.5); // Cinza para debug
}
```

### **2. Shader Simples para Debug**
Criado `psx_post_process_simple.gdshader` com:
- Apenas efeitos básicos (color limitation, brightness, contrast)
- Usa `TEXTURE` em vez de `SCREEN_TEXTURE`
- Debug com cor verde se não há textura

### **3. GlobalPSXEffect Melhorado**
```gdscript
// ADICIONADO: BackBufferCopy
back_buffer_copy = BackBufferCopy.new()
back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
global_canvas_layer.add_child(back_buffer_copy)

// ADICIONADO: Sistema de debug
func toggle_debug_mode():
    if debug_mode:
        global_color_rect.material = null
        global_color_rect.color = Color(0, 1, 0, 0.2)  # Verde transparente
    else:
        setup_psx_material()
        global_color_rect.color = Color.WHITE
```

### **4. Parâmetros Equilibrados**
```gdscript
brightness = 0.8      // Era 0.7 (muito escuro)
contrast = 1.2        // Era 1.6 (muito alto)
saturation = 0.7      // Era 0.5 (muito baixo)
fog_strength = 0.6    // Era 0.8 (muito forte)
```

## Controles de Debug

### **F1 - Toggle PSX Effect**
- Liga/desliga efeito PSX
- Console: `"🌍 Global PSX Effect toggled: ATIVO/DESATIVO"`

### **F2 - Toggle Debug Mode**
- **ON:** Remove shader, mostra overlay verde
- **OFF:** Reaplica shader
- Console: `"🐛 Debug Mode ATIVADO"` / `"🎮 Debug Mode DESATIVADO"`

## Como Testar

### **Passo 1: Verificar Inicialização**
Execute o projeto e verifique no console:
```
🌍 Global PSX Effect inicializado!
📺 BackBufferCopy: true
🎨 Material: true
✅ Shader PSX aplicado com sucesso
```

### **Passo 2: Testar Toggle**
1. Pressione **F1** - efeito deve ligar/desligar
2. Observe mudanças visuais na tela
3. Verifique mensagens no console

### **Passo 3: Testar Debug Mode**
1. Pressione **F2** - deve aparecer overlay verde transparente
2. Se overlay aparece = sistema funcionando
3. Pressione **F2** novamente - volta ao shader

### **Passo 4: Diagnóstico**

**Se tela continua branca:**
- Shader PSX tem problema → Use shader simples
- Modifique `setup_psx_material()`:
```gdscript
var psx_shader = load("res://shaders/psx_post_process_simple.gdshader")
```

**Se overlay verde não aparece:**
- Problema no GlobalPSXEffect
- Verifique se está no autoload do projeto

**Se nada acontece:**
- GlobalPSXEffect não está ativo
- Verifique `project.godot` → AutoLoad

## Soluções Temporárias

### **1. Forçar Shader Simples**
```gdscript
# Em setup_psx_material(), force o shader simples:
var psx_shader = load("res://shaders/psx_post_process_simple.gdshader")
```

### **2. Desabilitar Efeitos Problemáticos**
```gdscript
# No update_shader_parameters(), comente:
# psx_material.set_shader_parameter("enable_fog", true)
# psx_material.set_shader_parameter("enable_noise", true)
# psx_material.set_shader_parameter("enable_dithering", true)
```

### **3. Parâmetros Mínimos**
```gdscript
psx_material.set_shader_parameter("enable_color_limitation", true)
psx_material.set_shader_parameter("color_levels", 16)
psx_material.set_shader_parameter("brightness", 1.0)
psx_material.set_shader_parameter("contrast", 1.0)
```

## Resultado Esperado

### **✅ Funcionando Corretamente:**
- Tela não fica branca
- Efeito PSX visível (cores reduzidas, contraste alterado)
- F1 liga/desliga o efeito
- F2 mostra overlay verde no debug
- Console mostra mensagens de sucesso

### **❌ Ainda com Problema:**
- Tela branca persistente
- Nenhuma mudança visual com F1
- Overlay verde não aparece com F2
- Mensagens de erro no console

## Material PSX Restaurado

Para garantir que o material tenha todos os parâmetros:

```tres
[resource]
shader = ExtResource("1")
shader_parameter/enable_color_limitation = true
shader_parameter/color_levels = 10
shader_parameter/enable_dithering = true
shader_parameter/dither_strength = 0.75
shader_parameter/enable_fog = true
shader_parameter/fog_color = Vector3(0.15, 0.1, 0.1)
shader_parameter/fog_strength = 0.8
shader_parameter/fog_distance = 120.0
shader_parameter/fog_fade_range = 60.0
shader_parameter/enable_noise = true
shader_parameter/noise_color = Vector3(0.1, 0.05, 0.05)
shader_parameter/noise_strength = 0.65
shader_parameter/noise_time_fac = 2.5
shader_parameter/enable_contrast_boost = true
shader_parameter/contrast = 1.6
shader_parameter/brightness = 0.7
shader_parameter/saturation = 0.5
```

## Status: 🧪 AGUARDANDO TESTE

As correções foram aplicadas. Agora é necessário:
1. Executar o projeto
2. Testar os controles F1/F2
3. Verificar se a tela branca foi resolvida
4. Reportar o resultado para ajustes finais 