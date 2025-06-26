# Sistema Boss Chefão da Negação

## Visão Geral
Sistema completo de boss fight para o **Chefe da Negação**, o boss final do primeiro estágio do Nightmare Loop. O boss representa a primeira fase do luto e possui mecânicas únicas de negação da realidade.

## Características do Boss

### Estatísticas Base
- **Vida**: 500 HP (10x mais que fantasmas normais)
- **Velocidade**: 2.5 (mais lento mas imponente)
- **Dano de Ataque**: 40 (2x mais que fantasmas normais)
- **Escala**: 2.5x maior que fantasmas normais
- **Alcance de Ataque**: 2.5 unidades

### Sistema de Fases
O boss possui duas fases distintas:

#### **Fase 1: Negação Básica** (100% - 50% vida)
- Cor: Verde intenso
- Cooldowns normais para habilidades especiais
- Pode invocar até 3 fantasmas
- Mecânicas básicas de negação

#### **Fase 2: Negação Desesperada** (50% - 0% vida)
- Cor: Verde mais brilhante
- Velocidade aumentada em 30%
- Cooldowns reduzidos (30-40% mais rápido)
- Pode invocar até 5 fantasmas
- Cura 15% da vida máxima na transição
- Mecânicas mais agressivas

## Mecânicas Especiais

### 1. **Estado de Negação** 🌫️
- **Ativação**: 25% de chance ao receber dano
- **Duração**: 3 segundos
- **Efeito**: Reduz dano recebido em 70%
- **Visual**: Shader com efeitos intensificados

### 2. **Invocação de Fantasmas** 👻
- **Cooldown**: 8 segundos (Fase 1) / 5.6 segundos (Fase 2)
- **Quantidade**: 3 fantasmas (Fase 1) / 5 fantasmas (Fase 2)
- **Tipo**: Fantasmas da Negação menores (escala 0.8x)
- **Posicionamento**: Ao redor do boss em formação triangular

### 3. **Teletransporte de Negação** 💨
- **Cooldown**: 6 segundos (Fase 1) / 4.8 segundos (Fase 2)
- **Ativação**: Quando jogador está muito próximo (< 3 unidades)
- **Efeito**: Desaparece e reaparece em posição estratégica
- **Visual**: Fade out/in com animação

### 4. **Ondas de Negação** 🌊
- **Cooldown**: 12 segundos (Fase 1) / 7.2 segundos (Fase 2)
- **Ativação**: Jogador em distância média (3-8 unidades)
- **Efeito**: 3 ondas concêntricas de dano
- **Dano**: 60% do ataque normal por onda
- **Delay**: 0.5 segundos entre ondas

## Interface de Usuário

### Barra de Vida do Boss
- **Posição**: Canto superior direito
- **Informações**: Nome, vida atual/máxima, fase atual
- **Animações**: 
  - Aparição deslizante
  - Mudança de cor por fase
  - Efeitos de dano (flash vermelho)
  - Efeitos de mudança de fase (escala + cor)
  - Sequência de morte (piscar múltiplas vezes)

### Elementos Visuais
- **Background**: Painel escuro com bordas
- **Barra de Vida**: Verde (Fase 1) / Vermelho (Fase 2)
- **Texto**: Nome em destaque, vida numérica, indicador de fase
- **Responsividade**: Atualização em tempo real

## Integração com Sistemas

### Sistema de Pontuação
- **Derrota do Boss**: +10 pontos de lucidez
- **Fantasmas Invocados**: +1 ponto cada (padrão)
- **Integração**: LucidityManager automático

### Sistema de UI
- **Gerenciamento**: UIManager integrado
- **Métodos Disponíveis**:
  - `show_boss_health_bar(nome, vida_maxima)`
  - `update_boss_health(vida_atual, vida_maxima)`
  - `update_boss_phase(fase)`
  - `hide_boss_health_bar()`

### Sistema de Navegação
- **NavigationAgent3D**: Configurado para boss grande
- **Raio**: 1.5 unidades
- **Evitação**: Habilitada com múltiplos vizinhos
- **Distância máxima**: 20 unidades

## Implementação Técnica

### Estrutura de Classes
```gdscript
DenialBoss extends GhostBase
├── Propriedades do Boss (vida, dano, escala)
├── Sistema de Fases (enum BossPhase)
├── Mecânicas Especiais (negação, invocação, teleporte)
├── Gerenciamento de UI (barra de vida)
└── Sistema de Morte (sequência épica)
```

### Arquivos Principais
- **Script**: `scripts/enemies/DenialBoss.gd`
- **Cena**: `scenes/enemies/DenialBoss.tscn`
- **UI**: `scenes/ui/BossHealthBar.tscn`
- **UI Script**: `scripts/ui/boss_health_bar.gd`

### Componentes da Cena
- **CharacterBody3D**: Corpo físico principal
- **CollisionShape3D**: Colisão cilíndrica grande
- **NavigationAgent3D**: IA de navegação otimizada
- **AttackArea**: Área de ataque expandida
- **GhostCylinder**: Modelo visual com shader
- **Billboard/Sprite3D**: Sprite 2D como billboard
- **BossEffects**: Efeitos visuais especiais
- **AuraEffect**: Aura ao redor do boss

## Balanceamento

### Dificuldade Progressiva
- **Fase 1**: Introduz mecânicas básicas
- **Fase 2**: Intensifica pressão com cooldowns reduzidos
- **Estado de Negação**: Contrabalança alto dano com resistência temporária
- **Cura de Fase**: Prolonga a luta sem ser frustrante

### Recompensas
- **Alto valor de lucidez**: Justifica a dificuldade
- **Progressão clara**: Fases visualmente distintas
- **Feedback imediato**: UI responsiva e efeitos visuais

## Posicionamento no Mapa
- **Localização**: `map_2.tscn` - Posição (0, 2.0, -120.0)
- **Área**: Zona final do estágio, espaço amplo para combate
- **Contexto**: Após outros fantasmas, como culminação do estágio

## Debugging e Logs
O sistema inclui logs extensivos para debugging:
- `👑 BOSS DA NEGAÇÃO DESPERTOU!`
- `🩸 Vida: X/Y`
- `⚡ Fase atual: FASE_X`
- `🌫️ BOSS ENTROU EM ESTADO DE NEGAÇÃO!`
- `👻 X fantasmas invocados!`
- `💨 Boss teletransportou para: posição`
- `🌊 Onda de negação atingiu o jogador!`
- `👑 BOSS ENTROU NA FASE 2: NEGAÇÃO DESESPERADA!`
- `👑 CHEFE DA NEGAÇÃO FOI DERROTADO!`

## Expansibilidade
O sistema foi projetado para fácil expansão:
- **Novas Fases**: Enum BossPhase extensível
- **Novas Habilidades**: Sistema modular de ataques especiais
- **Outros Bosses**: Classe base reutilizável
- **UI Customizável**: Componentes de UI modulares

## Testes Recomendados
1. **Teste de Fases**: Verificar transição aos 50% de vida
2. **Teste de Mecânicas**: Cada habilidade especial individualmente
3. **Teste de UI**: Responsividade da barra de vida
4. **Teste de Balanceamento**: Tempo médio de combate
5. **Teste de Performance**: Múltiplos fantasmas invocados
6. **Teste de Integração**: Sistemas de pontuação e UI

## Conclusão
O Boss Chefão da Negação oferece uma experiência de combate épica e memorável, servindo como culminação adequada para o primeiro estágio do Nightmare Loop. O sistema balanceia desafio, mecânicas interessantes e feedback visual para criar um encontro de boss satisfatório. 