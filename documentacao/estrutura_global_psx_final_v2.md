# Estrutura Global PSX + CRT - Versão 2.0

## Nova Estrutura de Árvore

```
Root
├── Autoloads Essenciais
│   ├── GlobalPSXManager (gerencia estrutura)
│   ├── SceneManager (gerencia cenas)
│   └── GameStateManager (gerencia estados)
│
├── PSXEffect (Control)
│   └── SubViewportContainer (com material PSX)
│       └── SubViewport
│           └── GameContent (Node)
│               ├── Managers de Jogo
│               │   ├── UIManager
│               │   ├── GameManager
│               │   ├── LucidityManager
│               │   ├── GiftManager
│               │   ├── SkillManager
│               │   ├── PlayerReferenceManager
│               │   └── TransitionManager
│               │
│               └── Cenas do Jogo
│                   ├── SplashScreen
│                   ├── MainMenu
│                   ├── World
│                   ├── Map2
│                   └── [outras cenas]
│
└── CRTOverlay (CanvasLayer layer=1001)
```

## Separação de Managers

### Managers no Root (Essenciais)
- **GlobalPSXManager**: Gerencia a estrutura PSX global
- **SceneManager**: Gerencia carregamento de cenas
- **GameStateManager**: Gerencia estados do jogo

### Managers no GameContent (Jogo)
- **UIManager**: Interface do usuário
- **GameManager**: Lógica do jogo
- **LucidityManager**: Sistema de lucidez
- **GiftManager**: Sistema de presentes
- **SkillManager**: Sistema de habilidades
- **PlayerReferenceManager**: Referências do player
- **TransitionManager**: Sistema de transições

## Funcionamento

### Inicialização
1. GlobalPSXManager cria estrutura PSX
2. Move managers específicos para GameContent
3. Move cenas existentes para GameContent
4. Ativa interceptação automática

### Carregamento de Cenas
1. SceneManager (no Root) carrega nova cena
2. GlobalPSXManager intercepta e move para GameContent
3. Managers no GameContent processam a cena
4. Efeitos PSX são aplicados via SubViewportContainer

### UI e Gerenciamento
1. UIManager (no GameContent) gerencia interfaces
2. GameManager (no GameContent) gerencia lógica
3. Outros managers (no GameContent) processam sistemas específicos

## Benefícios da Nova Estrutura

✅ **Organização Lógica**: Managers relacionados ao jogo dentro do GameContent
✅ **Efeitos Consistentes**: PSX afeta tanto cenas quanto UIs
✅ **Gerenciamento Limpo**: Apenas managers essenciais no Root
✅ **Melhor Performance**: Redução de chamadas entre Root e GameContent
✅ **Debug Facilitado**: Estrutura clara e organizada

## Debug e Monitoramento

### Comando F5 mostra:
```
📌 Autoloads no Root:
  ├── GlobalPSXManager
  ├── SceneManager
  └── GameStateManager

🎮 PSXEffect:
  └── GameContent:
      📊 Managers:
        ├── UIManager
        ├── GameManager
        └── [outros managers]
      
      🎬 Cenas:
        ├── SplashScreen
        └── [outras cenas]

📺 CRTOverlay
```

## Arquivos Modificados

- `scripts/managers/GlobalPSXManager.gd`
  - Nova separação de managers
  - Sistema de interceptação atualizado
  - Debug aprimorado

## Notas Importantes

1. **Autoloads Essenciais**: Apenas 3 managers no Root
2. **GameContent Completo**: Contém tanto managers quanto cenas
3. **Efeitos PSX**: Aplicados a todo conteúdo do GameContent
4. **Interceptação**: Move automaticamente novas cenas e managers
5. **Debug**: F5 mostra estrutura completa e organizada

## Controles

- **F5**: Mostra estrutura atual completa
- **F2-F4**: Controles PSX (sempre ativos)
- **F6-F9**: Controles CRT (opcional)

Esta nova estrutura garante que:
- Todos os managers relacionados ao jogo estão dentro do GameContent
- Apenas managers essenciais permanecem no Root
- Efeitos PSX são aplicados consistentemente em todo o conteúdo
- A organização é mais lógica e eficiente 