# Correção - Tela Branca PSX Shader - Nightmare Loop

## Problema Identificado
```
Tela fica branca ao aplicar o shader PSX global
```

## Possíveis Causas Identificadas

### **1. SCREEN_TEXTURE não declarado corretamente**
- **Problema:** `SCREEN_TEXTURE` usado sem declaração `uniform`
- **Sintoma:** Tela branca ou preta
- **Causa:** Shader não consegue acessar a textura da tela

### **2. Aplicação incorreta do shader**
- **Problema:** Shader aplicado em `ColorRect` sem `BackBufferCopy`
- **Sintoma:** Tela branca sem conteúdo
- **Causa:** Não há captura do buffer da tela

### **3. Parâmetros extremos do shader**
- **Problema:** Valores muito baixos de brilho/contraste
- **Sintoma:** Tela muito escura ou branca
- **Causa:** `brightness = 0.7` e `contrast = 1.6` podem escurecer demais

### **4. Problemas de compatibilidade Godot 4**
- **Problema:** APIs antigas ou sintaxe incompatível
- **Sintoma:** Erros de shader ou renderização
- **Causa:** Transição Godot 3 → 4

## Soluções Implementadas

### **1. Correção do Shader PSX**

**Problema Original:**
```gdscript
shader_type canvas_item;
// ... sem declaração de SCREEN_TEXTURE
void fragment() {
    vec4 original_color = texture(SCREEN_TEXTURE, screen_uv); // ERRO
}
```

**Correção Aplicada:**
```gdscript
shader_type canvas_item;

// CORREÇÃO: Declaração explícita do SCREEN_TEXTURE
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest, repeat_disable;

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    
    // CORREÇÃO: Fallback para TEXTURE se SCREEN_TEXTURE falhar
    vec4 original_color;
    if (SCREEN_UV != vec2(0.0)) {
        original_color = texture(SCREEN_TEXTURE, screen_uv);
    } else {
        original_color = texture(TEXTURE, UV);
    }
    
    // CORREÇÃO: Debug para detectar problemas
    if (length(final_color) < 0.001) {
        final_color = vec3(0.5, 0.5, 0.5); // Cinza para debug
    }
}
```

### **2. Shader Simples para Debug**

Criado `psx_post_process_simple.gdshader` para teste:

```gdscript
shader_type canvas_item;

uniform bool enable_color_limitation : hint_default = true;
uniform int color_levels : hint_range(4, 32) = 16;
uniform float brightness : hint_range(0.2, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;

void fragment() {
    // Usa TEXTURE padrão (mais seguro)
    vec4 original_color = texture(TEXTURE, UV);
    vec3 final_color = original_color.rgb;
    
    // Debug: verde se não há cor
    if (length(final_color) < 0.001) {
        final_color = vec3(0.0, 1.0, 0.0);
    }
    
    // Efeitos básicos
    final_color = (final_color - 0.5) * contrast + 0.5;
    final_color *= brightness;
    
    if (enable_color_limitation) {
        float step_size = 1.0 / float(color_levels - 1);
        final_color = floor(final_color / step_size) * step_size;
    }
    
    COLOR = vec4(clamp(final_color, 0.0, 1.0), original_color.a);
}
```

### **3. GlobalPSXEffect Melhorado**

**Adicionado BackBufferCopy:**
```gdscript
# Adiciona BackBufferCopy para capturar a tela
back_buffer_copy = BackBufferCopy.new()
back_buffer_copy.name = "PSXBackBufferCopy"
back_buffer_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT

# Monta hierarquia correta
global_canvas_layer.add_child(back_buffer_copy)
global_canvas_layer.add_child(global_color_rect)
```

**Sistema de Debug:**
```gdscript
func toggle_debug_mode():
    debug_mode = !debug_mode
    if debug_mode:
        # Modo debug: sem shader, overlay verde
        global_color_rect.material = null
        global_color_rect.color = Color(0, 1, 0, 0.2)
        print("🐛 Debug Mode ATIVADO")
    else:
        # Modo normal: reaplica shader
        setup_psx_material()
        global_color_rect.color = Color.WHITE
        print("🎮 Debug Mode DESATIVADO")
```

**Carregamento Inteligente de Shader:**
```gdscript
func setup_psx_material():
    psx_material = ShaderMaterial.new()
    
    # Tenta shader principal, fallback para simples
    var psx_shader = load("res://shaders/psx_post_process.gdshader")
    if psx_shader == null:
        print("⚠️ Usando shader simples")
        psx_shader = load("res://shaders/psx_post_process_simple.gdshader")
    
    if psx_shader != null:
        psx_material.shader = psx_shader
        update_shader_parameters()
        global_color_rect.material = psx_material
        print("✅ Shader PSX aplicado")
    else:
        print("❌ ERRO: Nenhum shader encontrado!")
        global_color_rect.material = null
```

### **4. Parâmetros Mais Seguros**

**Antes (Extremos):**
```gdscript
brightness = 0.7      // Muito escuro
contrast = 1.6        // Muito alto
saturation = 0.5      // Muito baixo
fog_strength = 0.8    // Muito forte
```

**Depois (Equilibrados):**
```gdscript
brightness = 0.8      // Mais claro
contrast = 1.2        // Mais suave
saturation = 0.7      // Mais colorido
fog_strength = 0.6    // Mais sutil
```

## Controles de Debug

### **F1 - Toggle PSX Effect**
- Liga/desliga o efeito PSX completamente
- Útil para comparar com/sem efeito

### **F2 - Toggle Debug Mode**
- **Debug ON:** Remove shader, mostra overlay verde transparente
- **Debug OFF:** Reaplica shader normalmente
- Útil para verificar se o problema é no shader ou na aplicação

## Como Diagnosticar o Problema

### **Passo 1: Verificar se o efeito está ativo**
1. Execute o projeto
2. Pressione **F1** para alternar o efeito
3. Deve aparecer mensagem no console: `"🌍 Global PSX Effect toggled: ATIVO/DESATIVO"`

### **Passo 2: Testar modo debug**
1. Pressione **F2** para ativar debug
2. Deve aparecer overlay verde transparente
3. Se o overlay aparece, o sistema está funcionando
4. Pressione **F2** novamente para voltar ao shader

### **Passo 3: Verificar mensagens do console**
```
🌍 Global PSX Effect inicializado!
📺 BackBufferCopy: true
🎨 Material: true
✅ Shader PSX aplicado com sucesso
```

### **Passo 4: Identificar o problema**

**Se tela fica branca:**
- ✅ BackBufferCopy está funcionando
- ❌ Problema no shader PSX
- **Solução:** Usar shader simples temporariamente

**Se overlay verde não aparece:**
- ❌ Problema na aplicação do efeito
- **Solução:** Verificar hierarquia de nós

**Se nada acontece:**
- ❌ GlobalPSXEffect não está ativo
- **Solução:** Verificar se está no autoload

## Soluções Temporárias

### **1. Usar Shader Simples**
Modifique `setup_psx_material()` para forçar o shader simples:
```gdscript
var psx_shader = load("res://shaders/psx_post_process_simple.gdshader")
```

### **2. Desabilitar Efeitos Específicos**
No shader principal, desabilite efeitos problemáticos:
```gdscript
uniform bool enable_fog : hint_default = false;
uniform bool enable_noise : hint_default = false;
uniform bool enable_dithering : hint_default = false;
```

### **3. Usar Apenas Limitação de Cores**
Configure parâmetros mínimos:
```gdscript
psx_material.set_shader_parameter("enable_color_limitation", true)
psx_material.set_shader_parameter("color_levels", 16)
psx_material.set_shader_parameter("brightness", 1.0)
psx_material.set_shader_parameter("contrast", 1.0)
```

## Status Atual

### **✅ Correções Aplicadas:**
- Shader PSX corrigido com `uniform SCREEN_TEXTURE`
- Shader simples criado para debug
- BackBufferCopy adicionado ao sistema
- Sistema de debug implementado (F1/F2)
- Parâmetros equilibrados
- Carregamento inteligente de shaders
- Fallbacks para situações de erro

### **🧪 Para Testar:**
1. Execute o projeto
2. Use **F1** para toggle do efeito
3. Use **F2** para modo debug
4. Verifique mensagens no console
5. Teste diferentes cenas

### **📋 Próximos Passos:**
1. Testar se a tela branca foi resolvida
2. Ajustar parâmetros conforme necessário
3. Implementar presets de efeito (F3/F4)
4. Otimizar performance se necessário

O sistema agora tem múltiplas camadas de proteção contra tela branca e ferramentas de debug para identificar problemas rapidamente. 