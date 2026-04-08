import re

file_path = 'scenes/teste_player.tscn'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.read().split('\n')

new_lines = []
skip = False
for line in lines:
    if line.startswith('[node name="Player"'):
        skip = True
        new_lines.append('[ext_resource type="PackedScene" uid="uid://cpnkk3h1t02uy" path="res://scenes/player.tscn" id="5_player"]')
        new_lines.append('')
        new_lines.append('[node name="Player" parent="." instance=ExtResource("5_player")]')
        new_lines.append('position = Vector2(1500, 325)')
        continue
    
    if skip:
        # Stop skipping if we hit the next sibling node
        if line.startswith('[node '):
            skip = False
        else:
            continue
    
    if not skip:
        new_lines.append(line)

with open('scenes/teste_player.tscn', 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))
print('teste_player.tscn updated!')
