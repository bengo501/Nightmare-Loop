# Sistema de Fantasmas dos Estágios do Luto

## Visão Geral
O sistema implementa 5 tipos diferentes de fantasmas, cada um representando um dos estágios do luto de Kübler-Ross. Cada fantasma possui características únicas, cores distintas e habilidades especiais que refletem seu estágio emocional.

## Estágios e Fantasmas

### 1. **Negação** (Verde - GhostDenial)
- **Cor**: Verde claro (0.2, 1.0, 0.2, 0.7)
- **Imagem**: `greenGhost.png`
- **Características**:
  - Velocidade: Normal (1.0x)
  - Vida: Normal (1.0x)
  - **Habilidade Especial**: Phase Through - Torna-se intangível por 1 segundo
- **Comportamento**: Representa a recusa em aceitar a realidade
- **Morte**: Desaparece lentamente

### 2. **Raiva** (Cinza - GhostAnger)
- **Cor**: Cinza (0.7, 0.7, 0.7, 0.8)
- **Imagem**: `greyGhost.png`
- **Características**:
  - Velocidade: Rápida (1.5x)
  - Vida: Aumentada (1.2x)
  - **Habilidade Especial**: Rage Attack - Ataque duplo com dano adicional
- **Comportamento**: Agressivo e rápido
- **Morte**: Explode causando dano em área

### 3. **Barganha** (Azul - GhostBargaining)
- **Cor**: Azul (0.2, 0.2, 1.0, 0.6)
- **Imagem**: `blueGhost.png`
- **Características**:
  - Velocidade: Lenta (0.8x)
  - Vida: Aumentada (1.5x)
  - **Habilidade Especial**: Heal Others - Cura fantasmas próximos
- **Comportamento**: Suporte, ajuda outros fantasmas
- **Morte**: Deixa um item especial

### 4. **Depressão** (Roxo - GhostDepression)
- **Cor**: Roxo escuro (0.6, 0.2, 0.8, 0.5)
- **Imagem**: `purpleGhost.png`
- **Características**:
  - Velocidade: Muito lenta (0.6x)
  - Vida: Muito alta (2.0x)
  - **Habilidade Especial**: Drain Energy - Reduz velocidade do jogador
- **Comportamento**: Lento mas resistente, drena energia
- **Morte**: Dissolve-se em lágrimas

### 5. **Aceitação** (Amarelo - GhostAcceptance)
- **Cor**: Amarelo brilhante (1.0, 1.0, 0.2, 0.9)
- **Imagem**: `yellowGhost.png`
- **Características**:
  - Velocidade: Rápida (1.2x)
  - Vida: Reduzida (0.8x)
  - **Habilidade Especial**: Peaceful Death - Morte pacífica
- **Comportamento**: Equilibrado, aceita o destino
- **Morte**: Parte em paz com efeito luminoso

## Estrutura Técnica

### Script Base: `GhostBase.gd`
- Classe base que herda de `CharacterBody3D`
- Enum `GriefStage` define os 5 estágios
- Sistema de propriedades configurável por estágio
- Billboard system para sprites 2D em mundo 3D

### Cenas Individuais:
- `GhostDenial.tscn` - Fantasma da Negação
- `GhostAnger.tscn` - Fantasma da Raiva  
- `GhostBargaining.tscn` - Fantasma da Barganha
- `GhostDepression.tscn` - Fantasma da Depressão
- `GhostAcceptance.tscn` - Fantasma da Aceitação

### Componentes por Fantasma:
- **CharacterBody3D**: Corpo físico principal
- **CollisionShape3D**: Colisão cilíndrica
- **NavigationAgent3D**: IA de navegação
- **AttackArea**: Área de ataque
- **Billboard/Sprite3D**: Sistema de sprite 2D como billboard

## Habilidades Especiais

### Phase Through (Negação)
```gdscript
func _phase_through_ability():
    collision_layer = 0  # Torna intangível
    await get_tree().create_timer(1.0).timeout
    collision_layer = 3  # Volta ao normal
```

### Rage Attack (Raiva)
```gdscript
func _rage_attack_ability():
    # Ataque adicional de 50% do dano
    player_ref.take_damage(attack_damage * 0.5)
```

### Heal Others (Barganha)
```gdscript
func _heal_others_ability():
    # Cura fantasmas em raio de 5 unidades
    for ghost in nearby_ghosts:
        if distance < 5.0 and ghost.has_method("heal"):
            ghost.heal(20)
```

### Drain Energy (Depressão)
```gdscript
func _drain_energy_ability():
    # Reduz velocidade do jogador por 3 segundos
    player_ref.apply_slow_effect(3.0, 0.5)
```

### Peaceful Death (Aceitação)
```gdscript
func _peaceful_death_ability():
    # Morte sem causar dano extra
    # Apenas o comportamento padrão
```

## Sistema de Billboard

Cada fantasma usa um sistema de billboard que:
- Sempre olha para o jogador
- Usa sprites 2D das imagens fornecidas
- Aplica modulação de cor específica do estágio
- Posicionado 1.5 unidades acima do centro do fantasma

## Integração com o Jogo

### Navegação
- Usa `NavigationAgent3D` para pathfinding
- Atualiza caminho a cada 0.5 segundos
- Evita obstáculos automaticamente

### Combate
- Dano base de 20 pontos
- Cooldown de 1 segundo entre ataques
- Alcance de ataque de 1.5 unidades
- Labels de dano visuais

### Grupos
- Todos pertencem ao grupo "ghosts"
- Todos pertencem ao grupo "enemy"
- Facilita localização e interação

## Uso no Map_2

No `map_2.tscn`, foram adicionados exemplos de todos os 5 tipos:
- Posicionados em diferentes locais do mapa
- Cada um com transform único
- Prontos para teste e demonstração

## Extensibilidade

O sistema permite fácil:
- Adição de novos estágios
- Modificação de propriedades existentes
- Criação de novas habilidades especiais
- Ajuste de balance de gameplay

## Considerações de Design

### Temática Psicológica
Cada fantasma reflete genuinamente seu estágio do luto:
- **Negação**: Evita confronto (intangibilidade)
- **Raiva**: Agressivo e explosivo
- **Barganha**: Cooperativo (cura aliados)
- **Depressão**: Lento mas persistente (drena energia)
- **Aceitação**: Equilibrado e pacífico

### Balance de Gameplay
- Velocidades variadas criam dinâmica diferente
- Vidas balanceadas com velocidades
- Habilidades únicas mas não overpowered
- Cada tipo oferece desafio específico

## Debugging

Sistema inclui logs detalhados:
- Inicialização de cada estágio
- Execução de habilidades especiais
- Estados de vida e dano
- Sequências de morte

Todos os logs são prefixados com `[Ghost]` para fácil identificação. 