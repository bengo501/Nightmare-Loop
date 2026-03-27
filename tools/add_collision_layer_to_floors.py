#!/usr/bin/env python3
"""
Script para adicionar collision_layer = 129 a todos os pisos do map_2.tscn
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

def add_collision_layer_to_floors():
    file_path = PROJECT_ROOT / "scenes" / "levels" / "map_2.tscn"
    
    print("🔧 Adicionando collision_layer = 129 a todos os pisos...")
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Padrão para encontrar pisos com use_collision = true mas sem collision_layer
    # Adiciona collision_layer = 129 após use_collision = true
    pattern = r'(\[node name="Piso[^"]*" type="CSGBox3D"[^]]*\][\s\S]*?use_collision = true)\n(?!.*collision_layer)'
    
    def replacement(match):
        return match.group(1) + '\ncollision_layer = 129'
    
    # Aplica a substituição
    new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # Conta quantas substituições foram feitas
    changes = len(re.findall(pattern, content, flags=re.MULTILINE))
    
    # Método alternativo: processa linha por linha
    lines = content.split('\n')
    added = 0
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Se encontrar um piso
        if 'name="Piso' in line and 'type="CSGBox3D"' in line:
            # Procura por use_collision = true nas próximas linhas
            j = i + 1
            found_use_collision = False
            has_collision_layer = False
            use_collision_line = -1
            
            while j < len(lines) and j < i + 15:
                if 'use_collision = true' in lines[j]:
                    found_use_collision = True
                    use_collision_line = j
                elif 'collision_layer =' in lines[j]:
                    has_collision_layer = True
                elif lines[j].startswith('[node '):
                    break
                j += 1
            
            # Se tem use_collision mas não tem collision_layer, adiciona
            if found_use_collision and not has_collision_layer:
                lines.insert(use_collision_line + 1, 'collision_layer = 129')
                print(f"✅ Adicionado collision_layer = 129 ao piso na linha {i+1}")
                added += 1
                i += 1  # Ajusta o índice devido à inserção
        
        i += 1
    
    # Salva o arquivo
    content = '\n'.join(lines)
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    print(f"\n✅ Processo concluído!")
    print(f"📊 collision_layer = 129 adicionado a {added} pisos")
    print(f"🎯 Todos os pisos agora têm collision_layer = 129 (layers 1 + 8)")
    
    return added

if __name__ == "__main__":
    add_collision_layer_to_floors() 