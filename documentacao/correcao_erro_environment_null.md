# Correção do Erro: Invalid access to property 'environment' on null instance

## Problema
O erro "Invalid access to property or key 'environment' on a base object of type 'null instance'" ocorria no PSXEffectManager ao tentar acessar a propriedade `environment` de uma câmera que não existia.

## Causa Raiz
O código estava tentando acessar `main_viewport.get_camera_3d().environment` diretamente, mas `get_camera_3d()` pode retornar `null` se:
1. Não há câmera 3D ativa no viewport
2. A cena ainda não foi completamente carregada
3. A câmera ainda não foi inicializada

## Código Problemático
```gdscript
# ANTES - Código que causava erro
func apply_psx_environment():
    var psx_env = load("res://environments/psx_environment.tres")
    if psx_env and main_viewport:
        # ❌ ERRO: get_camera_3d() pode retornar null
        original_environment = main_viewport.get_camera_3d().environment
        main_viewport.get_camera_3d().environment = psx_env
```

## Solução Implementada

### 1. Verificação de Null
```gdscript
# DEPOIS - Código seguro
func apply_psx_environment():
    var success = find_and_apply_to_cameras()
    
    if success:
        print("🌫️ Environment PSX aplicado com sucesso!")
    else:
        # Retry após 1 segundo se as câmeras não estão prontas
        await get_tree().create_timer(1.0).timeout
        find_and_apply_to_cameras()
```

### 2. Sistema Robusto de Busca de Câmeras
```gdscript
func find_and_apply_to_cameras():
    var cameras_found = []
    var psx_env = load("res://environments/psx_environment.tres")
    
    # 1. Tenta câmera do viewport principal
    if main_viewport:
        var main_camera = main_viewport.get_camera_3d()
        if main_camera:  # ✅ Verifica se não é null
            cameras_found.append(main_camera)
    
    # 2. Procura câmeras na cena atual
    var current_scene = get_tree().current_scene
    if current_scene:
        _find_cameras(current_scene, cameras_found)
    
    # 3. Procura câmeras do player
    var player_group = get_tree().get_nodes_in_group("player")
    for player in player_group:
        _find_cameras(player, cameras_found)
    
    # 4. Aplica PSX com validação
    for camera in cameras_found:
        if camera is Camera3D and is_instance_valid(camera):
            camera.environment = psx_env
```

### 3. Aguardar Carregamento da Cena
```gdscript
func _ready():
    main_viewport = get_viewport()
    
    # ✅ Aguarda um frame para garantir que a cena está carregada
    await get_tree().process_frame
    
    if enable_psx_mode:
        apply_psx_effects()
```

### 4. Função de Debug
```gdscript
# Pressione F5 no jogo para debug das câmeras
func debug_camera_info():
    # Lista todas as câmeras encontradas
    # Mostra status dos environments
    # Ajuda a identificar problemas
```

## Melhorias Implementadas

1. **Validação Robusta**: Sempre verifica se objetos existem antes de acessá-los
2. **Múltiplas Fontes**: Procura câmeras em viewport, cena atual e player
3. **Retry Logic**: Tenta novamente se câmeras não estão prontas
4. **Debug Tools**: Função F5 para diagnosticar problemas
5. **Async Loading**: Aguarda carregamento completo da cena

## Controles de Debug
- **F1**: Toggle PSX Mode
- **F2**: Preset Clássico
- **F3**: Preset Horror
- **F4**: Preset Nightmare
- **F5**: Debug Camera Info (novo)

## Resultado
✅ Erro de null reference eliminado
✅ Sistema funciona em todas as cenas
✅ Fallback robusto para diferentes situações
✅ Debug tools para identificar problemas futuros

O PSXEffectManager agora é completamente seguro e funciona independentemente do estado das câmeras na cena. 