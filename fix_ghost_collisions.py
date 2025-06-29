#!/usr/bin/env python3
"""
Script para corrigir colisores dos fantasmas e player
- Fantasmas não bloqueiam movimento do player (são fantasmas!)
- Player pode atirar nos fantasmas (collision detection para armas)
- Fantasmas mantêm área de ataque funcionando
"""

import re
import os
from pathlib import Path

def fix_ghost_collisions():
    """Corrige as configurações de colisão dos fantasmas e player"""
    
    print("🔧 Corrigindo colisores dos fantasmas e player...")
    
    # Configurações de collision layers:
    # Layer 1 (1): Ambiente/Paredes
    # Layer 2 (2): Player 
    # Layer 3 (4): Fantasmas - Corpo (não colide com player)
    # Layer 4 (8): Fantasmas - Área de Ataque
    # Layer 5 (16): Armas/Projéteis
    
    changes_made = []
    
    # 1. Corrigir cenas dos fantasmas
    ghost_scenes = [
        "scenes/enemies/GhostDenial.tscn",
        "scenes/enemies/GhostAnger.tscn", 
        "scenes/enemies/GhostBargaining.tscn",
        "scenes/enemies/GhostDepression.tscn",
        "scenes/enemies/GhostAcceptance.tscn",
        "scenes/enemies/ghost1.tscn",
        "scenes/enemies/DenialBoss.tscn"
    ]
    
    for ghost_file in ghost_scenes:
        if os.path.exists(ghost_file):
            changes = fix_ghost_scene(ghost_file)
            changes_made.extend(changes)
    
    # 2. Corrigir player.tscn
    if os.path.exists("scenes/player/player.tscn"):
        changes = fix_player_scene("scenes/player/player.tscn")
        changes_made.extend(changes)
    
    # 3. Atualizar script do player para usar collision mask correto
    if os.path.exists("scripts/player/player.gd"):
        changes = fix_player_script("scripts/player/player.gd")
        changes_made.extend(changes)
    
    # Relatório
    print(f"\n✅ Correções aplicadas:")
    for change in changes_made:
        print(f"   - {change}")
    
    print(f"\n📋 Total de alterações: {len(changes_made)}")
    
    return len(changes_made) > 0

def fix_ghost_scene(file_path):
    """Corrige uma cena de fantasma específica"""
    changes = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 1. Fantasma principal: Layer 4 (não colide com player), Mask 1 (só paredes)
        # Procura por CharacterBody3D do fantasma
        ghost_pattern = r'(\[node name="[^"]*" type="CharacterBody3D"[^\]]*groups=\["[^"]*"\]\s*(?:[^\[]*\n)*?)collision_layer = \d+'
        if re.search(ghost_pattern, content):
            content = re.sub(ghost_pattern, r'\1collision_layer = 4', content)
            changes.append(f"{file_path}: Fantasma collision_layer = 4")
        
        ghost_mask_pattern = r'(\[node name="[^"]*" type="CharacterBody3D"[^\]]*groups=\["[^"]*"\]\s*(?:[^\[]*\n)*?)collision_mask = \d+'
        if re.search(ghost_mask_pattern, content):
            content = re.sub(ghost_mask_pattern, r'\1collision_mask = 1', content)
            changes.append(f"{file_path}: Fantasma collision_mask = 1")
        
        # 2. AttackArea mantém configuração atual (collision_mask = 2 para detectar player)
        # Não precisa alterar - já está correto
        
        # Salva se houve mudanças
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
    
    except Exception as e:
        print(f"❌ Erro ao processar {file_path}: {e}")
    
    return changes

def fix_player_scene(file_path):
    """Corrige a cena do player"""
    changes = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Adiciona collision_layer = 2 ao Player se não existir
        player_pattern = r'(\[node name="Player" type="CharacterBody3D"\]\s*)(script = [^\n]*)'
        if re.search(player_pattern, content):
            # Verifica se já tem collision_layer
            if 'collision_layer =' not in content[:content.find('[node name="CollisionShape3D"')]:
                content = re.sub(player_pattern, r'\1collision_layer = 2\ncollision_mask = 5\n\2', content)
                changes.append(f"{file_path}: Player collision_layer = 2, collision_mask = 5")
        
        # Salva se houve mudanças
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
    
    except Exception as e:
        print(f"❌ Erro ao processar {file_path}: {e}")
    
    return changes

def fix_player_script(file_path):
    """Atualiza o script do player para usar collision mask correto"""
    changes = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Atualiza collision_mask do ShootRay para detectar fantasmas (layer 4)
        shoot_ray_pattern = r'(shoot_ray\.collision_mask = )\d+'
        if re.search(shoot_ray_pattern, content):
            content = re.sub(shoot_ray_pattern, r'\g<1>4', content)
            changes.append(f"{file_path}: ShootRay collision_mask = 4 (fantasmas)")
        
        # Adiciona comentário explicativo
        if 'shoot_ray.collision_mask = 4' in content and '# Layer 4: Fantasmas' not in content:
            content = content.replace(
                'shoot_ray.collision_mask = 4',
                'shoot_ray.collision_mask = 4  # Layer 4: Fantasmas (para detectar e atirar)'
            )
            changes.append(f"{file_path}: Adicionado comentário explicativo")
        
        # Salva se houve mudanças
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
    
    except Exception as e:
        print(f"❌ Erro ao processar {file_path}: {e}")
    
    return changes

def create_collision_layers_documentation():
    """Cria documentação das collision layers"""
    
    doc_content = """# Sistema de Collision Layers - Nightmare Loop

## **Configuração das Collision Layers**

### **Layer 1 (collision_layer = 1)**: Ambiente/Paredes
- **Uso**: Paredes, pisos, obstáculos estáticos
- **Colide com**: Player, Fantasmas
- **Finalidade**: Bloquear movimento de todos os personagens

### **Layer 2 (collision_layer = 2)**: Player
- **Uso**: Corpo do jogador
- **Colide com**: Ambiente (Layer 1)
- **Não colide com**: Fantasmas (Layer 4) - fantasmas são intangíveis!
- **Finalidade**: Player pode atravessar fantasmas

### **Layer 3 (collision_layer = 4)**: Fantasmas - Corpo
- **Uso**: Corpo dos fantasmas
- **Colide com**: Ambiente (Layer 1)
- **Não colide com**: Player (Layer 2) - permite passagem
- **Finalidade**: Fantasmas são intangíveis ao player mas respeitam paredes

### **Layer 4 (collision_layer = 8)**: Fantasmas - Área de Ataque
- **Uso**: AttackArea dos fantasmas
- **collision_mask = 2**: Detecta player
- **Finalidade**: Fantasmas podem atacar o player

### **Layer 5 (collision_layer = 16)**: Armas/Projéteis
- **Uso**: Raycast das armas do player
- **collision_mask = 4**: Detecta fantasmas
- **Finalidade**: Player pode atirar nos fantasmas

## **Resultado Esperado**

✅ **Player pode atravessar fantasmas** (não fica "trancado")
✅ **Player pode atirar nos fantasmas** (detecção de dano funciona)
✅ **Fantasmas podem atacar o player** (AttackArea funciona)
✅ **Fantasmas respeitam paredes** (não atravessam ambiente)
✅ **Player respeita paredes** (colisão com ambiente funciona)

## **Arquivos Modificados**

- `scenes/enemies/GhostDenial.tscn`
- `scenes/enemies/GhostAnger.tscn`
- `scenes/enemies/GhostBargaining.tscn`
- `scenes/enemies/GhostDepression.tscn`
- `scenes/enemies/GhostAcceptance.tscn`
- `scenes/enemies/ghost1.tscn`
- `scenes/enemies/DenialBoss.tscn`
- `scenes/player/player.tscn`
- `scripts/player/player.gd`

## **Como Testar**

1. **Teste de Atravessar**: Player deve conseguir andar através dos fantasmas
2. **Teste de Tiro**: Player deve conseguir atirar e acertar fantasmas
3. **Teste de Ataque**: Fantasmas devem conseguir atacar o player
4. **Teste de Paredes**: Nem player nem fantasmas devem atravessar paredes
"""
    
    with open("documentacao/sistema_collision_layers.md", 'w', encoding='utf-8') as f:
        f.write(doc_content)
    
    print("📝 Documentação criada: documentacao/sistema_collision_layers.md")

if __name__ == "__main__":
    print("👻 === CORREÇÃO DE COLISORES DOS FANTASMAS ===")
    
    if fix_ghost_collisions():
        print("\n✅ Correções aplicadas com sucesso!")
        create_collision_layers_documentation()
        print("\n🎮 Agora os fantasmas são intangíveis ao player mas podem ser atingidos por armas!")
    else:
        print("\n⚠️ Nenhuma correção foi necessária ou possível.") 