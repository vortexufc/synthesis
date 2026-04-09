import re

file_path = 'scenes/teste_player.tscn'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

ext_resources = []
for line in content.split('\n'):
    if '[ext_resource' in line:
        if 'player.gd' in line or 'run.png' in line or 'idle.png' in line:
            ext_resources.append(line)

subresources = []
in_sub = False
curr_sub = []
for line in content.split('\n'):
    if line.startswith('[sub_resource'):
        if in_sub:
            subresources.append('\n'.join(curr_sub))
        in_sub = True
        curr_sub = [line]
    elif in_sub and line.startswith('['):
        if not line.startswith('[sub_resource'):
            in_sub = False
            subresources.append('\n'.join(curr_sub))
            curr_sub = []
        else:
            subresources.append('\n'.join(curr_sub))
            curr_sub = [line]
    elif in_sub:
        curr_sub.append(line)
if in_sub:
    subresources.append('\n'.join(curr_sub))

player_nodes = """[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_uhc0a")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_2lcu3")

[node name="Camera2D" type="Camera2D" parent="."]
limit_left = 0
limit_top = 0
limit_right = 2048
limit_bottom = 1410
position_smoothing_enabled = true

[node name="AudioStreamPlayer2D" type="AudioStreamPlayer2D" parent="."]

[node name="sprite" type="AnimatedSprite2D" parent="."]
position = Vector2(0, -7)
scale = Vector2(1.5, 1.5)
sprite_frames = SubResource("SpriteFrames_iy05v")
animation = &"idle_baixo"
autoplay = "idle_baixo"
frame_progress = 0.97908"""

player_file = '[gd_scene load_steps=38 format=3 uid="uid://cpnkk3h1t02uy"]\n\n'
player_file += '\n'.join(ext_resources) + '\n\n'
player_file += '\n\n'.join(subresources) + '\n\n'
player_file += player_nodes

with open('scenes/player.tscn', 'w', encoding='utf-8') as f:
    f.write(player_file)
print('player.tscn created!')
