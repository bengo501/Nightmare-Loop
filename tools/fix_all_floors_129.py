#!/usr/bin/env python3
"""
Script para garantir que TODOS os pisos do map_2.tscn tenham collision_layer = 129
129 = layers 1 + 8 (colisão física + detecção de mouse)
"""

import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

def fix_all_floors_to_129():
    file_path = PROJECT_ROOT / "scenes" / "levels" / "map_2.tscn"
    
    print("🔧 Corrigindo collision_layer de todos os pisos para 129...")
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    lines = content.split('\n')
    changes = 0
    
    # Processa linha por linha
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Se encontrar um piso
        if 'name="Piso' in line and 'type="CSGBox3D"' in line:
            print(f"📍 Encontrado: {line.strip()}")
            
            # Procura pelas próximas linhas até encontrar collision_layer
            j = i + 1
            found_collision_layer = False
            
            while j < len(lines) and j < i + 15:  # Busca nas próximas 15 linhas
                if 'collision_layer = ' in lines[j]:
                    current_value = lines[j].strip()
                    
                    if 'collision_layer = 129' not in lines[j]:
                        # Substitui o valor atual por 129
                        lines[j] = re.sub(r'collision_layer = \d+', 'collision_layer = 129', lines[j])
                        print(f"  ✅ {current_value} → collision_layer = 129")
                        changes += 1
                    else:
                        print(f"  ℹ️ Já correto: collision_layer = 129")
                    
                    found_collision_layer = True
                    break
                
                # Se chegou ao próximo nó, para de procurar
                if lines[j].startswith('[node '):
                    break
                    
                j += 1
            
            if not found_collision_layer:
                print(f"  ⚠️ collision_layer não encontrado para este piso")
        
        i += 1
    
    # Salva o arquivo modificado
    content = '\n'.join(lines)
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    print(f"\n✅ Correção concluída!")
    print(f"📊 Total de pisos corrigidos: {changes}")
    print(f"🎯 Todos os pisos agora têm collision_layer = 129 (layers 1 + 8)")
    
    return changes

if __name__ == "__main__":
    fix_all_floors_to_129() 