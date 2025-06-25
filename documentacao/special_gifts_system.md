# Sistema de Gifts Especiais - Nightmare Loop

## Visão Geral

O sistema de gifts especiais permite criar itens colecionáveis que adicionam **+5 pontos** em vez de +1 ponto para cada estágio do luto. Estes gifts são visualmente distintos dos gifts normais e funcionam de forma completamente independente.

## Gifts Especiais Disponíveis

### 1. **GiftNegacao.tscn**
- **Estágio:** Negação
- **Pontos:** +5
- **Cor:** Vermelho vibrante com brilho
- **Descrição:** "Um presente especial que representa a negação da perda"

### 2. **GiftRaiva.tscn**
- **Estágio:** Raiva
- **Pontos:** +5
- **Cor:** Laranja vibrante com brilho
- **Descrição:** "Um presente especial que representa a raiva da perda"

### 3. **GiftBarganha.tscn**
- **Estágio:** Barganha
- **Pontos:** +5
- **Cor:** Amarelo vibrante com brilho
- **Descrição:** "Um presente especial que representa a barganha da perda"

### 4. **GiftDepressao.tscn**
- **Estágio:** Depressão
- **Pontos:** +5
- **Cor:** Azul vibrante com brilho
- **Descrição:** "Um presente especial que representa a depressão da perda"

### 5. **GiftAceitacao.tscn**
- **Estágio:** Aceitação
- **Pontos:** +5
- **Cor:** Verde vibrante com brilho
- **Descrição:** "Um presente especial que representa a aceitação da perda"

## Características Especiais

### Visual
- **Cores mais vibrantes** que os gifts normais
- **Efeito de brilho (emission)** para destacar
- **Rotação mais rápida** (3.0 vs 2.0)
- **Flutuação mais pronunciada** (0.3 vs 0.2)

### Comportamento
- **Funcionamento independente** - cada gift é uma cena separada
- **Coleta individual** - não afeta outros gifts
- **Efeito visual de coleta** - crescimento e fade out
- **Logs detalhados** para debug

### Sistema de Pontos
- **+5 pontos** por gift coletado
- **Integração com GiftManager** existente
- **Persistência** - pontos salvos automaticamente

## Como Usar

### 1. Adicionando ao Mapa
```gdscript
# Em qualquer cena, adicione como child:
# - GiftNegacao.tscn
# - GiftRaiva.tscn
# - GiftBarganha.tscn
# - GiftDepressao.tscn
# - GiftAceitacao.tscn
```

### 2. Posicionamento
```gdscript
# Exemplo de posicionamento no editor:
# GiftNegacao: Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -20, 2, 0)
# GiftRaiva:   Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -10, 2, 0)
# etc...
```

### 3. Configuração Personalizada
```gdscript
# No script SpecialGift.gd, você pode modificar:
@export var bonus_points: int = 5  # Quantidade de pontos
var rotation_speed = 3.0           # Velocidade de rotação
```

## Exemplo de Uso Completo

### Cena de Exemplo: SpecialGiftsCollection.tscn
```
SpecialGiftsCollection (Node3D)
├── GiftNegacao (instância)     # Posição (-20, 2, 0)
├── GiftRaiva (instância)       # Posição (-10, 2, 0)
├── GiftBarganha (instância)    # Posição (0, 2, 0)
├── GiftDepressao (instância)   # Posição (10, 2, 0)
└── GiftAceitacao (instância)   # Posição (20, 2, 0)
```

## Logs do Sistema

Quando um gift especial é coletado, você verá logs como:
```
[SpecialGift] Gift especial criado: negacao (+5 pontos)
[SpecialGift] Player entrou na área do gift especial: negacao
[SpecialGift] Presente especial coletado: negacao (+5 pontos)
[SpecialGift] Total de negacao: 5
```

## Integração com Sistema Existente

Os gifts especiais são **totalmente compatíveis** com o sistema existente:
- Usam o mesmo **GiftManager**
- Atualizam a **HUD** automaticamente
- Funcionam com o **sistema de save/load**
- Integram com o **sistema de modos de ataque**

## Vantagens

1. **Independência:** Cada gift funciona sozinho
2. **Flexibilidade:** Fácil de posicionar em qualquer mapa
3. **Personalização:** Valores configuráveis
4. **Visual Distintivo:** Fácil de identificar como especiais
5. **Compatibilidade:** Funciona com todo o sistema existente

## Como Testar

1. Adicione qualquer gift especial ao seu mapa
2. Execute o jogo
3. Aproxime-se do gift (deve aparecer "Pressione E")
4. Pressione E para coletar
5. Verifique na HUD que foram adicionados +5 pontos
6. Verifique os logs no console para confirmação 