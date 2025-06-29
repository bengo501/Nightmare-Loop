# Sistema de Colisores dos Fantasmas - Nightmare Loop

## **Problema Resolvido**

**❌ Problema Original:**
- Player ficava "trancado" ao encostar nos fantasmas
- Fantasmas bloqueavam o movimento como se fossem sólidos
- Contradição: fantasmas deveriam ser intangíveis mas ainda detectáveis por armas

**✅ Solução Implementada:**
- Fantasmas são intangíveis ao player (pode atravessar)
- Player pode atirar e acertar fantasmas
- Fantasmas mantêm capacidade de atacar o player
- Fantasmas ainda respeitam paredes e obstáculos

---

## **Sistema de Collision Layers**

### **Layer 1 (collision_layer = 1)**: Ambiente/Paredes
- **Uso**: Paredes, pisos, obstáculos estáticos
- **Exemplo**: CSGBox3D das paredes, pisos
- **Colide com**: Player (Layer 2), Fantasmas (Layer 4)

### **Layer 2 (collision_layer = 2)**: Player
- **Uso**: Corpo do jogador
- **collision_mask = 1**: Colide apenas com ambiente
- **Não colide com**: Fantasmas (Layer 4)
- **Resultado**: Player pode atravessar fantasmas

### **Layer 4 (collision_layer = 4)**: Fantasmas - Corpo
- **Uso**: CharacterBody3D dos fantasmas
- **collision_mask = 1**: Colide apenas com ambiente
- **Não colide com**: Player (Layer 2)
- **Resultado**: Fantasmas são intangíveis ao player mas respeitam paredes

### **AttackArea dos Fantasmas**
- **collision_layer = 0**: Não é sólido
- **collision_mask = 2**: Detecta player (Layer 2)
- **Resultado**: Fantasmas podem atacar o player

### **ShootRay do Player**
- **collision_mask = 4**: Detecta fantasmas (Layer 4)
- **Resultado**: Player pode atirar nos fantasmas

---

## **Arquivos Modificados**

### **Cenas dos Fantasmas:**
- `scenes/enemies/GhostDenial.tscn`
- `scenes/enemies/GhostAnger.tscn`
- `scenes/enemies/GhostBargaining.tscn`
- `scenes/enemies/GhostDepression.tscn`
- `scenes/enemies/GhostAcceptance.tscn`
- `scenes/enemies/ghost1.tscn`
- `scenes/enemies/DenialBoss.tscn`

**Alterações:**
```gdscript
# ANTES:
collision_layer = 3
collision_mask = 3

# DEPOIS:
collision_layer = 4  # Não colide com player
collision_mask = 1   # Só colide com paredes
```

### **Cena do Player:**
- `scenes/player/player.tscn`

**Alterações:**
```gdscript
# ADICIONADO:
collision_layer = 2  # Layer do player
collision_mask = 1   # Só colide com paredes
```

### **Script do Player:**
- `scripts/player/player.gd`

**Alterações:**
```gdscript
# ANTES:
shoot_ray.collision_mask = 2

# DEPOIS:
shoot_ray.collision_mask = 4  # Layer 4: Fantasmas (para detectar e atirar)
```

---

## **Comportamento Esperado**

### **✅ Testes de Funcionamento:**

1. **Teste de Atravessar Fantasmas:**
   - Player pode andar através dos fantasmas
   - Não fica "trancado" ou bloqueado
   - Movimento fluido sem obstáculos

2. **Teste de Tiro nos Fantasmas:**
   - Player pode mirar e atirar nos fantasmas
   - Raycast detecta colisão com fantasmas
   - Dano é aplicado corretamente

3. **Teste de Ataque dos Fantasmas:**
   - Fantasmas podem atacar o player
   - AttackArea detecta player corretamente
   - Dano é aplicado ao player

4. **Teste de Colisão com Paredes:**
   - Player não atravessa paredes
   - Fantasmas não atravessam paredes
   - NavigationAgent funciona corretamente

---

## **Vantagens da Solução**

### **🎮 Gameplay Melhorado:**
- **Movimento Fluido**: Player não fica preso nos fantasmas
- **Combate Funcional**: Pode atirar nos fantasmas normalmente
- **Lógica Consistente**: Fantasmas são intangíveis como esperado

### **🔧 Técnico:**
- **Performance**: Menos cálculos de colisão desnecessários
- **Modular**: Sistema de layers organizados e escaláveis
- **Compatível**: Não quebra funcionalidades existentes

### **👻 Imersão:**
- **Realismo**: Fantasmas se comportam como fantasmas
- **Tensão**: Player pode ser atacado mas não fica preso
- **Estratégia**: Permite táticas de movimento através dos inimigos

---

## **Como Testar**

1. **Abra o jogo no Godot**
2. **Vá para map_2.tscn**
3. **Teste cada comportamento:**
   - Ande através dos fantasmas
   - Atire nos fantasmas
   - Deixe os fantasmas te atacarem
   - Verifique se paredes ainda bloqueiam movimento

---

## **Estrutura Final do Sistema**

```
Ambiente (Layer 1)
├── Bloqueia: Player + Fantasmas
└── Detectado por: Ninguém (é obstáculo)

Player (Layer 2)  
├── Colide com: Ambiente
├── Não colide com: Fantasmas
└── Detectado por: AttackArea dos fantasmas

Fantasmas (Layer 4)
├── Colide com: Ambiente  
├── Não colide com: Player
└── Detectado por: ShootRay do player

AttackArea (Layer 0, Mask 2)
└── Detecta: Player

ShootRay (Mask 4)
└── Detecta: Fantasmas
```

Esta solução garante que os fantasmas sejam verdadeiramente "fantasmas" - intangíveis ao player mas ainda interativos no combate! 