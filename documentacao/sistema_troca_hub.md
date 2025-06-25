# Sistema de Troca de Hub com Preservação do Player

## Visão Geral
Este sistema permite trocar o ambiente (hub) do jogo mantendo o player persistente entre as cenas. Em vez de destruir e recriar o player, ele é temporariamente removido, o hub é trocado, e o player é reposicionado no novo ambiente.

## Arquitetura do Sistema

### Estrutura de Cenas
```
World.tscn (Cena Principal)
├── Player (Persistente)
├── Hub/ (Ambiente - Trocável)
│   ├── Furniture/
│   ├── Walls/
│   └── Objects/
├── Environment/
└── Lighting/
```

### Fluxo de Funcionamento

1. **Preservação do Player**
   - Player é temporariamente removido da árvore de cenas
   - Transform e estado são salvos

2. **Troca do Hub**
   - Cena atual é destruída
   - Nova cena (hub) é carregada
   - Player é readicionado à nova cena

3. **Reposicionamento**
   - Player é posicionado no `PontoNascimento`
   - Estados são restaurados

## Implementação Técnica

### SceneManager.gd - Nova Função

```gdscript
func change_hub_with_fade(hub_scene_path: String, fade_duration: float = 1.0):
    # 1. Encontra e preserva o player
    var player = find_node_by_name(current_scene_node, "Player")
    var player_parent = player.get_parent()
    player_parent.remove_child(player)
    
    # 2. Fade out
    # Overlay de fade criado
    
    # 3. Troca de cena
    current_scene_node.queue_free()
    var new_scene = hub_resource.instantiate()
    get_tree().root.add_child(new_scene)
    
    # 4. Restaura o player
    new_scene.add_child(player)
    
    # 5. Reposiciona no spawn point
    var spawn_point = find_node_by_name(new_scene, "PontoNascimento")
    player.global_transform.origin = spawn_point.global_transform.origin
    
    # 6. Fade in
```

### BedInteraction.gd - Modificações

```gdscript
func create_sleep_transition():
    # Usa a nova função de troca de hub
    await scene_manager.change_hub_with_fade("res://map_2.tscn", 2.0)
    
    # Reativa o player após a transição
    var new_player = scene_manager.find_node_by_name(get_tree().current_scene, "Player")
    new_player.set_physics_process(true)
    new_player.set_process_input(true)
```

## Vantagens do Sistema

### 🔄 **Persistência do Player**
- **Estado Mantido**: Vida, XP, inventário preservados
- **Sem Recriação**: Player não é destruído/recriado
- **Performance**: Mais eficiente que recarregar tudo

### 🎮 **Experiência Fluida**
- **Transição Suave**: Fade in/out sem interrupções
- **Posicionamento Automático**: Player spawn no local correto
- **Estados Restaurados**: Física e input reativados automaticamente

### 🛠️ **Flexibilidade Técnica**
- **Modular**: Fácil de usar em diferentes contextos
- **Reutilizável**: Funciona para qualquer troca de hub
- **Fallback**: Sistema de backup em caso de erro

## Pontos de Spawn

### PontoNascimento
Cada hub deve ter um nodo `Node3D` chamado "PontoNascimento":

```gdscript
[node name="PontoNascimento" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z)
```

### Posicionamento Automático
- Sistema busca automaticamente por "PontoNascimento"
- Player é posicionado na transform do spawn point
- Velocidade é resetada se for CharacterBody3D

## Tratamento de Erros

### Verificações de Segurança
```gdscript
# Verifica se player existe
if not player:
    print("[SceneManager] ERRO: Player não encontrado!")
    return

# Verifica se hub carregou
if hub_resource == null:
    # Restaura player se houver erro
    player_parent.add_child(player)
    return

# Verifica se spawn point existe
if not spawn_point:
    # Mantém posição anterior
    player.global_transform = player_transform
```

### Sistema de Fallback
- Se SceneManager falhar, usa carregamento direto
- Logs detalhados para debugging
- Restauração de estados em caso de erro

## Logs de Debug

O sistema fornece logs detalhados:

```
[SceneManager] Iniciando troca de hub para: res://map_2.tscn
[SceneManager] Player encontrado: Player
[SceneManager] Player removido temporariamente da cena
[SceneManager] Player adicionado à nova cena
[SceneManager] Player posicionado no PontoNascimento: (-12.8871, 1, -27.3619)
[SceneManager] Troca de hub concluída com sucesso!
[BedInteraction] Player reativado após transição
[BedInteraction] Transição de hub concluída com sucesso!
```

## Uso Prático

### Interação com Cama
1. Player entra na área da cama
2. Prompt de interação aparece
3. Player pressiona E para dormir
4. Sistema pausa player e esconde HUD
5. Fade out iniciado
6. Hub trocado mantendo player
7. Player reposicionado no PontoNascimento
8. Fade in e reativação do player
9. HUD restaurada

### Outros Usos Possíveis
- **Portais**: Transição entre áreas
- **Elevadores**: Mudança de andares
- **Veículos**: Entrada/saída de transportes
- **Sonhos**: Sequências especiais

## Configuração Necessária

### Cena de Origem (world.tscn)
- Player no nível raiz
- Hub como nó filho separado
- BedInteraction configurado

### Cena de Destino (map_2.tscn)
- PontoNascimento posicionado
- Sem player instanciado
- NavigationRegion3D configurado

### SceneManager
- Autoload configurado
- Função change_hub_with_fade disponível
- Sistema de busca de nodos implementado

## Considerações de Performance

### Otimizações
- **Remoção Temporária**: Player sai da árvore brevemente
- **Queue Free**: Cena anterior é destruída adequadamente
- **Process Frame**: Aguarda carregamento completo

### Limitações
- **Tempo de Carregamento**: Depende do tamanho do hub
- **Memória**: Cena anterior é completamente descarregada
- **Estados Temporários**: Alguns estados podem precisar ser salvos manualmente

## Extensibilidade

O sistema pode ser facilmente expandido para:
- **Múltiplos Spawn Points**: Diferentes pontos de entrada
- **Parâmetros Customizados**: Velocidade, posição específica
- **Efeitos Especiais**: Partículas, sons, animações
- **Dados Persistentes**: Salvar/carregar estados complexos

## Troubleshooting

### Problemas Comuns

1. **Player não encontrado**
   - Verificar se player está no grupo "player"
   - Confirmar nome do nodo como "Player"

2. **Spawn point não funciona**
   - Verificar se existe "PontoNascimento" na cena
   - Confirmar posição válida do spawn point

3. **Estados não restaurados**
   - Verificar se physics_process está sendo reativado
   - Confirmar se process_input está habilitado

### Debugging
- Ativar logs detalhados
- Verificar árvore de cenas no debugger
- Monitorar transform do player
- Confirmar carregamento de recursos 