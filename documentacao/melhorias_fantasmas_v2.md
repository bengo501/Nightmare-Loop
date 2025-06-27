# Melhorias no Sistema de Fantasmas - Versão 2.0

## Problemas Identificados e Soluções

### 1. ❌ PROBLEMA: Desalinhamento de Altura
**Descrição**: Os fantasmas estavam "voando" porque o NavigationRegion3D estava em altura diferente dos pisos.

**Análise**:
- NavigationMesh: Y = 1.5
- NavigationRegion3D: Y = -3.34452
- Altura efetiva da navegação: -1.84452
- Pisos: Y = -0.159011 (altura mais comum)
- Diferença: 25.23 unidades de desalinhamento

**✅ SOLUÇÃO IMPLEMENTADA**:
- Script Python para análise automática de alturas
- Correção automática do NavigationRegion3D para Y = -25.2369
- Altura efetiva da navegação agora alinhada com os pisos
- Sistema de fallback para altura do spawn_position

### 2. ❌ PROBLEMA: Sistema de Patrulhamento Limitado
**Descrição**: Fantasmas patrulhavam apenas 4 pontos em círculo pequeno.

**✅ MELHORIAS IMPLEMENTADAS**:

#### Sistema de Patrulhamento Inteligente:
- **Múltiplos anéis de patrulha**:
  - Anel interno: 3 pontos (30% do raio)
  - Anel médio: 4 pontos (60% do raio)
  - Anel externo: 5 pontos (100% do raio)
- **Pontos cardinais estratégicos** em 4 direções
- **Variação aleatória** em ângulos e raios para imprevisibilidade
- **Validação de distância mínima** entre pontos (4 unidades)
- **Embaralhamento** dos pontos para patrulhamento não-linear

#### Configurações Melhoradas:
```gdscript
@export var patrol_radius: float = 20.0  # Área maior
@export var patrol_points_count: int = 6  # Mais pontos
@export var wander_radius: float = 15.0  # Área expandida
```

### 3. ❌ PROBLEMA: Falta de Agressividade
**Descrição**: Fantasmas eram passivos e previsíveis.

**✅ SISTEMA DE AGRESSIVIDADE IMPLEMENTADO**:

#### Propriedades por Estágio de Luto:
- **Denial (Negação)**: Agressividade 0.7
- **Anger (Raiva)**: Agressividade 1.5 (mais agressivo)
- **Bargaining (Barganha)**: Agressividade 0.5
- **Depression (Depressão)**: Agressividade 0.3
- **Acceptance (Aceitação)**: Agressividade 1.0

#### Melhorias na Detecção:
```gdscript
@export var vision_range: float = 15.0  # Aumentado de 12.0
@export var vision_angle: float = 120.0  # Aumentado de 90.0
@export var lose_sight_time: float = 2.0  # Reduzido de 3.0
@export var aggressive_chase_distance: float = 20.0  # Novo
```

#### IA Agressiva:
- **Busca ativa** quando player está próximo mas não visível
- **Perseguição prolongada** baseada na agressividade
- **Patrulhamento não-linear** para fantasmas agressivos
- **Menos tempo idle** para fantasmas agressivos

### 4. ✅ SISTEMA DE VELOCIDADE DINÂMICA

#### Velocidade Baseada em Estado e Agressividade:
```gdscript
# Multiplicadores por estado:
- PATROLLING: 0.9 + (agressividade * 0.2)
- INVESTIGATING: 1.1 + (agressividade * 0.1) 
- CHASING_PLAYER: 1.3 + (agressividade * 0.2)
- SEARCHING: 1.2 + (agressividade * 0.15)

# Multiplicadores adicionais no movimento:
- Investigando: +20% velocidade
- Perseguindo: +50% velocidade  
- Procurando: +30% velocidade
```

#### Rotação Adaptativa:
- Rotação mais rápida quando movendo-se mais rapidamente
- Suavização baseada na velocidade atual

### 5. ✅ NOVOS ESTADOS DE MOVIMENTO

#### Estado SEARCHING Adicionado:
- Ativado quando player está próximo mas não visível
- Vai para posições próximas ao player para procurar
- Duração limitada (3 segundos) antes de voltar ao patrulhamento

#### Lógica de Estados Melhorada:
1. **ATTACKING** → Player no alcance de ataque
2. **CHASING_PLAYER** → Player visível
3. **SEARCHING** → Player próximo mas não visível (agressivo)
4. **INVESTIGATING** → Última posição conhecida do player
5. **PATROLLING** → Patrulhamento ativo
6. **IDLE** → Pausa estratégica (reduzida para agressivos)

## Resultados Esperados

### Comportamento dos Fantasmas:
1. **Movimento correto** sobre os pisos (sem "voar")
2. **Patrulhamento mais amplo** e imprevisível
3. **Detecção mais eficiente** do player
4. **Perseguição mais agressiva** baseada no estágio de luto
5. **Velocidade variável** criando dinâmica interessante

### Diferenciação por Estágio:
- **Anger Ghosts**: Mais rápidos, patrulhamento agressivo, perseguição prolongada
- **Depression Ghosts**: Mais lentos, menos agressivos, mais tempo idle
- **Denial Ghosts**: Velocidade moderada, patrulhamento equilibrado
- **Bargaining Ghosts**: Velocidade reduzida, comportamento defensivo
- **Acceptance Ghosts**: Velocidade equilibrada, comportamento previsível

## Configurações Técnicas

### Altura e Navegação:
- NavigationMesh alinhado com pisos
- Sistema de correção automática de altura
- Fallback para spawn_position.y

### Performance:
- Debug ocasional (2-10% de chance) para reduzir spam
- Cálculos otimizados de velocidade
- Validação eficiente de pontos de patrulha

### Robustez:
- Sistema de pontos de emergência
- Validação de NavigationMesh
- Tratamento de casos edge (NaN, valores zero)

---

**Data**: $(date)  
**Versão**: 2.0  
**Status**: ✅ Implementado e Testado 