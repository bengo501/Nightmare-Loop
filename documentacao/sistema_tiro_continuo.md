# Sistema de Tiro Contínuo - Nightmare Loop

## Visão Geral
Sistema implementado que permite ao jogador atirar continuamente segurando o botão de tiro no modo primeira pessoa, com consumo automático de munição e sistema de dano baseado na correspondência de cores.

## Funcionalidades Implementadas

### 1. Tiro Contínuo
- **Ativação**: Segure o botão esquerdo do mouse ou tecla F no modo primeira pessoa
- **Desativação**: Solte o botão ou saia do modo primeira pessoa
- **Taxa de Tiro**: 0.3 segundos entre disparos (configurável via `ammo_consumption_rate`)
- **Interrupção Automática**: Para automaticamente quando a munição acaba

### 2. Sistema de Dano Aprimorado
- **Dano Base**: 20 pontos por disparo
- **Dano Crítico**: 40 pontos quando a cor da munição corresponde ao estágio do fantasma
- **Correspondência de Cores**:
  - Negação (Azul) vs Fantasma Negação = 40 dano
  - Raiva (Verde) vs Fantasma Raiva = 40 dano
  - Barganha (Cinza) vs Fantasma Barganha = 40 dano
  - Depressão (Roxo) vs Fantasma Depressão = 40 dano
  - Aceitação (Amarelo) vs Fantasma Aceitação = 40 dano

### 3. Sistema de Munição Inteligente
- **Consumo por Disparo**: 1 ponto do estágio correspondente
- **Verificação Automática**: Sistema verifica munição antes de cada disparo
- **Bloqueio Visual**: Laser fica invisível quando não há munição
- **Troca de Modo**: Ao trocar para um modo sem munição, o laser é automaticamente escondido

## Controles

### Modo Primeira Pessoa
- **Botão Direito do Mouse**: Entra/sai do modo primeira pessoa
- **Botão Esquerdo do Mouse**: Segure para tiro contínuo
- **Tecla F**: Alternativa para tiro contínuo
- **Teclas 1-5**: Seleciona tipo de munição/ataque

### Seleção de Munição
- **1**: Negação (Azul) - Efetivo contra fantasmas de Negação
- **2**: Raiva (Verde) - Efetivo contra fantasmas de Raiva
- **3**: Barganha (Cinza) - Efetivo contra fantasmas de Barganha
- **4**: Depressão (Roxo) - Efetivo contra fantasmas de Depressão
- **5**: Aceitação (Amarelo) - Efetivo contra fantasmas de Aceitação

## Mecânicas de Segurança

### Proteção de Modo
- Tiro só funciona no modo primeira pessoa
- Sistema para automaticamente ao sair do modo primeira pessoa
- Verificações múltiplas para evitar ataques acidentais no modo terceira pessoa

### Gerenciamento de Munição
- Verificação contínua de munição disponível
- Interrupção automática quando munição acaba
- Feedback visual através da visibilidade do laser
- Mensagens de debug para acompanhar o consumo

## Feedback Visual e Sonoro

### Laser
- **Cor Dinâmica**: Muda conforme o tipo de munição selecionado
- **Visibilidade**: Só aparece quando há munição disponível
- **Estado**: Ativo apenas durante o tiro contínuo

### Mensagens de Debug
- `🔫 Iniciando tiro contínuo...`
- `🛑 Parando tiro contínuo...`
- `🎯 ACERTO! Dano: X (modo: Y)`
- `💥 DANO CRÍTICO! Modo X vs fantasma Y = Z dano`
- `🚫 Tiro contínuo interrompido: Sem munição de X`
- `⚔️ Dano normal: X (modo Y vs fantasma estágio Z)`

## Configurações Técnicas

### Variáveis Principais
```gdscript
@export var attack_damage: float = 20.0  # Dano base
@export var ammo_consumption_rate: float = 0.3  # Taxa de tiro
var is_shooting: bool = false  # Estado do tiro contínuo
var can_shoot_continuous: bool = true  # Controle de permissão
```

### Funções Principais
- `start_continuous_shooting()`: Inicia o tiro contínuo
- `stop_continuous_shooting()`: Para o tiro contínuo
- `shoot_first_person()`: Executa um disparo individual
- `calculate_damage_against_target()`: Calcula dano com base na correspondência

## Integração com Outros Sistemas

### GiftManager
- Consulta munição disponível via `get_gift_count()`
- Consome munição via `use_gift()`
- Integração completa com sistema de presentes do luto

### HUD e Interface
- Atualização automática da munição exibida
- Mudança de cor do crosshair conforme o modo
- Feedback visual em tempo real

### Sistema de Fantasmas
- Integração com `take_damage()` dos fantasmas
- Verificação de estágio de luto via `get_grief_stage()`
- Cálculo automático de dano crítico

## Melhorias Futuras Sugeridas
1. Efeitos sonoros para cada tipo de disparo
2. Animações de recarga quando munição acaba
3. Efeitos visuais diferenciados para dano crítico
4. Sistema de aquecimento da arma com uso contínuo
5. Feedback háptico (vibração) para controladores

## Troubleshooting

### Problemas Comuns
1. **Laser não aparece**: Verificar se há munição do tipo selecionado
2. **Tiro não funciona**: Confirmar se está no modo primeira pessoa
3. **Dano incorreto**: Verificar correspondência entre munição e fantasma
4. **Tiro não para**: Verificar se `is_shooting` está sendo resetado corretamente

### Debug
Use as mensagens de console para acompanhar:
- Estado do tiro contínuo
- Consumo de munição
- Cálculos de dano
- Mudanças de modo de ataque 