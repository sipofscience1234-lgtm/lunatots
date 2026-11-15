# Moon Base Rescue 3D (Godot 4)

A 3D third-person astronaut training game for the NASA Space Apps Challenge
"Build a Junior Astronaut Mission Trainer". About 20 minutes, 4 missions:

1. Moonwalk Training - low gravity, sprinting, suit oxygen.
2. Find the Water Ice - explore dark craters, drill ice, use the scanner.
3. Repair the Base - carry parts to solar, oxygen and antenna modules; answer quiz questions.
4. Solar Storm Run - deploy sensors and reach the shielded shelter before radiation hits.

## How to play
1. Install Godot 4.2 or newer: https://godotengine.org/download
2. Import project.godot, then press F5.
3. In a mission, click the window to capture the mouse.

## Astronaut model
The astronaut is included in models/. This work is based on "3D Cute Astronaut made in Blender"
(https://sketchfab.com/3d-models/3d-cute-astronaut-made-in-blender-796a83aef2cd40978d34bb184a15eacc)
by Naomifz (https://sketchfab.com/naomifz), licensed under CC-BY-NC-ND-4.0
(http://creativecommons.org/licenses/by-nc-nd/4.0/). Non-commercial use only; do not distribute
a modified copy of the model.


## Interface typography
The interface requests **Showcard Gothic** first (if installed on the computer), then falls back
to Orbitron / Eurostile / Bank Gothic / Rajdhani / Arial. Showcard Gothic is a system font and
is not bundled with this project; install it on the computer if you want that exact typeface.

## Audio
- The lobby uses an original, looping playful sci-fi synth cue (not the Among Us track).
- Jumping plays a short cute squeaky/boing sound.
- Walking and sprinting play quick original cartoon-style footfalls; sprint steps are brighter and louder.
- Audio assets are in `audio/`.
