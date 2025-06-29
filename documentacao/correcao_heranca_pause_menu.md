# Correção do Erro de Herança - Menu de Pause

## Problema Identificado

Erro ao pressionar ESC no map_2.tscn:
\\\
Script inherits from native type 'Control', so it can't be assigned to an object of type: 'CanvasLayer'
\\\

## Causa do Problema

- **Script**: \pause_menu.gd\ herdava de \ase_menu.gd\
- **base_menu.gd**: Herda de \Control\
- **Nó na cena**: \PauseMenu\ é do tipo \CanvasLayer\
- **Conflito**: Tentativa de aplicar script Control em nó CanvasLayer

## Solução Implementada

### Alteração na Herança
\\\gdscript
# ANTES
extends \
res://scripts/ui/base_menu.gd\  # Control

# DEPOIS
extends CanvasLayer  # Compatível com o nó
\\\

### Implementação Direta das Funções
- Removida dependência do \ase_menu.gd\
- Implementada função \nimate_button_press()\ diretamente
- Mantidas todas as funcionalidades do menu

## Funcionalidades Mantidas

✅ **Botão Continuar**: Despausa o jogo corretamente
✅ **Botão Menu Principal**: Vai para o menu principal
✅ **Botão Sair**: Fecha o jogo
✅ **Animações**: Efeitos visuais dos botões
✅ **Compatibilidade**: Funciona em world.tscn e map_2.tscn

## Arquivos Modificados

- \scripts/ui/pause_menu.gd\: Herança alterada e funções implementadas
- \documentacao/correcao_heranca_pause_menu.md\: Esta documentação

## Teste e Validação

1. Pressione ESC no map_2.tscn - Menu deve abrir sem erro
2. Teste botão \Continuar\ - Jogo deve despausar
3. Teste botão \Menu
Principal\ - Deve ir para menu
4. Teste botão \Sair\ - Jogo deve fechar
