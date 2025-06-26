# Sistema de Munição Baseado nos Pontos do Luto

## Visão Geral
O sistema de munição foi implementado para utilizar os pontos dos estágios do luto como munição para a arma do jogador. Cada tiro consome 1 ponto do estágio correspondente ao modo de ataque atual, com um cooldown de 0.5 segundos entre tiros.

## Funcionamento

### Consumo de Munição
- **Taxa de Consumo**: 1 ponto por tiro
- **Cooldown**: 0.5 segundos entre tiros
- **Tipos de Munição**: Cada modo de ataque usa um tipo específico de ponto do luto

### Mapeamento Modo de Ataque → Munição
| Modo de Ataque | Tecla | Cor | Tipo de Munição |
|----------------|-------|-----|-----------------|
| Negação | 1 | Azul | pontos de "negacao" |
| Raiva | 2 | Verde | pontos de "raiva" |
| Barganha | 3 | Cinza | pontos de "barganha" |
| Depressão | 4 | Roxo | pontos de "depressao" |
| Aceitação | 5 | Amarelo | pontos de "aceitacao" |

## Mecânicas Implementadas

### Verificação de Munição
1. **can_shoot()**: Verifica se o jogador pode atirar
   - Checa se o cooldown terminou
   - Verifica se há munição disponível

2. **has_ammo_for_current_mode()**: Verifica se há pontos suficientes
   - Consulta o GiftManager
   - Retorna true se há pelo menos 1 ponto do tipo necessário

### Consumo de Pontos
1. **consume_ammo()**: Consome 1 ponto do estágio correspondente
   - Verifica disponibilidade antes de consumir
   - Atualiza o GiftManager (remove 1 ponto)
   - Inicia o timer de cooldown
   - Exibe feedback no console

### Integração com Sistema de Ataque
- **perform_attack()**: Modificada para incluir verificação de munição
- **shoot_first_person()**: Modificada para incluir verificação de munição
- Ambas as funções verificam munição ANTES de executar o ataque

## Feedback Visual e de Console

### Mensagens de Status
- ✅ **Tiro Bem-sucedido**: "💥 MUNIÇÃO CONSUMIDA: -1 ponto de [MODO] (Restante: X)"
- 🚫 **Sem Munição**: "🚫 SEM MUNIÇÃO! Não há pontos de [MODO] disponíveis"
- ⏱️ **Cooldown**: "⏱️ TIRO BLOQUEADO: Aguarde o cooldown de 0.5 segundos"

### Troca de Modo de Ataque
Quando o jogador troca de modo (teclas 1-5), exibe:
```
========================================
MODO DE ATAQUE ALTERADO PARA: Raiva
Cor: (0.2, 1, 0.2, 1)
Munição disponível: 15 pontos ✅
========================================
```

Se sem munição:
```
⚠️ ATENÇÃO: Sem munição! Colete presentes de Raiva para atirar
```

## Funções Auxiliares Implementadas

### Verificação
- `can_shoot() -> bool`: Verifica se pode atirar (cooldown + munição)
- `has_ammo_for_current_mode() -> bool`: Verifica munição disponível
- `get_current_ammo_count() -> int`: Retorna quantidade atual de munição

### Utilitários
- `get_ammo_type_for_mode(mode) -> String`: Mapeia modo para tipo de gift
- `consume_ammo() -> bool`: Consome munição e inicia cooldown

## Integração com Sistemas Existentes

### GiftManager
- Utiliza `get_gift_count(type)` para verificar munição
- Utiliza `use_gift(type, amount)` para consumir pontos
- Mantém compatibilidade total com sistema de coleta

### Sistema de Modos de Ataque
- Cada modo usa seu tipo específico de munição
- Cores e nomes mantidos inalterados
- Eficácia contra fantasmas mantida

### Sistema de Presentes Especiais
- Presentes coletados (+5 pontos) servem como munição
- Presentes normais (+1 ponto) também servem como munição
- Sistema totalmente integrado

## Configurações

### Variáveis Ajustáveis
```gdscript
@export var ammo_consumption_rate: float = 0.5  # Cooldown entre tiros
```

### Timer de Munição
- `ammo_timer`: Timer para controlar cooldown
- `wait_time`: 0.5 segundos
- `one_shot`: true (não repete)

## Comportamento Especial

### Modo Terceira Pessoa
- Sistema de munição desabilitado (não consome pontos)
- Ataques bloqueados completamente

### Modo Primeira Pessoa
- Sistema de munição ativo
- Todos os tiros consomem munição
- Bloqueio automático quando sem munição

## Estratégia de Jogo
1. **Coleta de Presentes**: Jogador deve coletar presentes para ter munição
2. **Gestão de Recursos**: Diferentes tipos de munição para diferentes fantasmas
3. **Eficiência**: Usar o modo correto contra o fantasma correspondente
4. **Planejamento**: Gerenciar munição limitada durante combates

## Logs de Debug
O sistema gera logs detalhados para facilitar debugging:
- Inicialização do sistema
- Consumo de munição
- Bloqueios por falta de munição
- Troca de modos de ataque
- Status de cooldown

Este sistema transforma os pontos do luto em um recurso estratégico, adicionando uma camada de gestão de recursos ao combate do jogo. 