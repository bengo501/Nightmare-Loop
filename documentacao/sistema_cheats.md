# Sistema de Cheats e Item de Vida - Nightmare Loop

## 📋 Visão Geral

Este documento descreve o sistema de cheats implementado no jogo Nightmare Loop e o novo item de recuperação de vida.

## ❤️ Item de Vida

### Características
- **Recuperação**: +20 HP quando coletado
- **Visual**: Cápsula verde brilhante com luz pulsante
- **Animação**: Rotação contínua e flutuação suave
- **Interação**: Pressione E para coletar quando próximo

### Arquivos Criados
- `scripts/items/HealthItem.gd` - Script do item de vida
- `scenes/items/HealthItem.tscn` - Cena do item individual
- `scenes/items/HealthItemsCollection.tscn` - Coleção de 10 itens para teste

### Como Usar
1. Adicione `HealthItem.tscn` ou `HealthItemsCollection.tscn` em suas cenas
2. O item detectará automaticamente quando o player se aproximar
3. Pressione E para coletar e recuperar 20 HP
4. O item será removido da cena após a coleta

## 🎮 Sistema de Cheats

### Teclas de Cheat

| Tecla | Função | Descrição |
|-------|--------|-----------|
| **G** | God Mode | Ativa/desativa vida infinita e muda a barra de vida para amarelo |
| **K** | All Gifts | Dá 99 de cada gift de todos os estágios do luto |
| **J** | Goto Map2 | Vai direto para a cena `map_2.tscn` |
| **H** | Skill Tree | Abre o menu da árvore de habilidades |
| **L** | Goto World | Vai para a cena `world.tscn` |
| **Ç** | Instant Death | Mata o jogador instantaneamente |

### Detalhes dos Cheats

#### 🔱 God Mode (Tecla G)
- **Ativação**: Vida infinita - todo dano é ignorado
- **Visual**: Barra de vida fica amarela quando ativo
- **Restauração**: Vida é restaurada ao máximo quando ativado
- **Desativação**: Vida volta ao normal e barra de vida volta à cor original

#### 🎁 All Gifts (Tecla K)
- **Função**: Define todos os gifts para 99 unidades
- **Tipos**: Negação, Raiva, Barganha, Depressão, Aceitação
- **Uso**: Permite tiro ilimitado em todos os modos de ataque
- **Debug**: Mostra no console a quantidade de cada gift após aplicar

#### 🗺️ Navegação de Cenas (Teclas J e L)
- **Tecla J**: Vai para `map_2.tscn`
- **Tecla L**: Vai para `world.tscn`
- **Sistema**: Usa o SceneManager para mudanças seguras de cena
- **Fallback**: Mostra erro no console se SceneManager não for encontrado

#### 🌳 Skill Tree (Tecla H)
- **Prioridade**: Tenta usar UIManager primeiro
- **Fallback**: Busca diretamente por skill trees na cena
- **Métodos**: Suporta `show_skill_tree()` e `show_menu()`
- **Debug**: Mostra no console qual método foi usado

#### 💀 Instant Death (Tecla Ç)
- **Função**: Mata o jogador instantaneamente
- **Segurança**: Desativa god mode se estiver ativo
- **Processo**: Define HP como 0 e chama função `die()`
- **Resultado**: Ativa o Game Over normalmente

### Implementação Técnica

#### Integração com Sistema Existente
- **Localização**: Adicionado ao `_input()` do player
- **Condição**: Só funciona durante `GameState.PLAYING`
- **Compatibilidade**: Mantém todas as funcionalidades originais
- **God Mode**: Integrado à função `take_damage()` existente

#### Segurança e Debug
- **Estado do Jogo**: Cheats só funcionam quando está jogando
- **Logs Detalhados**: Todos os cheats mostram informações no console
- **Fallbacks**: Sistemas alternativos quando managers não são encontrados
- **Validações**: Verifica existência de nós antes de usar

#### Estrutura do Código
```gdscript
# Variáveis de estado
var god_mode: bool = false
var original_health_bar_color: Color

# Detecção de teclas no _input()
if event is InputEventKey and event.pressed:
    match event.keycode:
        KEY_G: toggle_god_mode()
        KEY_K: cheat_give_all_gifts()
        # ... outros cheats

# Implementação individual de cada cheat
func toggle_god_mode():
    # Lógica do god mode
    
func cheat_give_all_gifts():
    # Lógica dos gifts
    
# ... outras funções
```

## 🔧 Como Testar

### Item de Vida
1. Abra uma cena com o player
2. Adicione `HealthItemsCollection.tscn` à cena
3. Execute o jogo e aproxime-se dos itens verdes
4. Pressione E para coletar e verificar a recuperação de HP

### Cheats
1. Execute o jogo e entre em modo de jogo (não menu)
2. Teste cada tecla de cheat individualmente
3. Verifique o console para mensagens de debug
4. Observe as mudanças visuais (barra de vida amarela no god mode)

## 📝 Notas de Desenvolvimento

### Compatibilidade
- ✅ Integrado com sistema de vida existente
- ✅ Compatível com sistema de gifts
- ✅ Funciona com SceneManager
- ✅ Suporta UIManager e fallbacks

### Limitações
- Cheats só funcionam durante gameplay
- God mode afeta apenas `take_damage()` - outras formas de morte podem não ser bloqueadas
- Skill tree cheat depende da estrutura da UI existente

### Futuras Melhorias
- [ ] Cheat para teleporte para posições específicas
- [ ] Cheat para alterar velocidade do player
- [ ] Cheat para spawnar inimigos
- [ ] Interface visual para ativar/desativar cheats
- [ ] Salvamento do estado dos cheats

## 🎯 Conclusão

O sistema de cheats e item de vida foram implementados com sucesso, mantendo compatibilidade total com o sistema existente e fornecendo ferramentas úteis para desenvolvimento e teste do jogo. 