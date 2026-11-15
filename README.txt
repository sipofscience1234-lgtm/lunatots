ASTRONAUT MODEL (already included)
==================================
This folder contains the astronaut used in the game, unmodified:
    scene.gltf, scene.bin, license.txt

Credit (required by the license):
This work is based on "3D Cute Astronaut made in Blender"
(https://sketchfab.com/3d-models/3d-cute-astronaut-made-in-blender-796a83aef2cd40978d34bb184a15eacc)
by Naomifz (https://sketchfab.com/naomifz)
licensed under CC-BY-NC-ND-4.0 (http://creativecommons.org/licenses/by-nc-nd/4.0/)

License terms in short: credit the author, NO commercial use, and modified versions of the
model may not be distributed. Do not edit scene.gltf / scene.bin before sharing the project.
The game scales and colours the model in code only.

If the astronaut walks backwards, open game3d.gd and change
    const MODEL_YAW = PI
to
    const MODEL_YAW = 0.0

If Godot cannot import the model, the game uses a simple built-in astronaut instead.
