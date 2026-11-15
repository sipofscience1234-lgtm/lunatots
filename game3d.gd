extends Node3D
## The 3D world for Moon Base Rescue. One script runs all four missions.

signal finished(score, detail)
signal quit_requested

const STORM_AT = 120.0
const STORM_LEN = 40.0
const SHELTER = Vector3(-18, 0, 16)
const O2_STATION = Vector3(0, 0, 5)
const MODEL_PATHS = ["res://models/astronaut.glb", "res://models/astronaut.gltf", "res://models/scene.gltf", "res://models/scene.glb", "res://models/astronaut.fbx"]
const MODEL_HEIGHT = 1.9
const MODEL_SHADER = """
shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float rough = 0.6;
uniform float phase = 0.0;
uniform float amp = 0.0;
uniform float air = 0.0;

vec3 rot_x(vec3 p, float pz, float a) {
    float c = cos(a);
    float s = sin(a);
    float y = p.y;
    float z = p.z - pz;
    return vec3(p.x, y * c - z * s, y * s + z * c + pz);
}

vec3 rot_y(vec3 p, vec2 pv, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = p.x - pv.x;
    float z = p.z - pv.y;
    return vec3(x * c + z * s + pv.x, p.y, -x * s + z * c + pv.y);
}

vec3 rot_z(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}

vec3 leg(vec3 p, float knee, float knee_w, float hip) {
    return rot_x(rot_x(p, 0.42, knee * knee_w), 0.75, hip);
}

void vertex() {
    vec3 v0 = VERTEX;
    vec3 d = vec3(0.0);
    float sw = sin(phase);
    float cw = cos(phase);
    float swing = 0.85 * amp;

    float leg_x = 1.0 - smoothstep(0.45, 0.55, abs(v0.x));
    float leg_w = (1.0 - smoothstep(0.55, 0.85, v0.z)) * leg_x;
    float knee_w = 1.0 - smoothstep(0.30, 0.50, v0.z);
    float w_r = smoothstep(-0.05, 0.05, v0.x);
    float w_l = 1.0 - w_r;
    float hip_r = -sw * swing - air * 0.40;
    float hip_l = sw * swing + air * 0.28;
    float knee_r = max(cw, 0.0) * 0.9 * amp + air * 0.75;
    float knee_l = max(-cw, 0.0) * 0.9 * amp + air * 0.55;
    d += (leg(v0, knee_r, knee_w, hip_r) - v0) * (w_r * leg_w);
    d += (leg(v0, knee_l, knee_w, hip_l) - v0) * (w_l * leg_w);

    float arm_r = smoothstep(0.50, 0.62, v0.x) * smoothstep(1.05, 1.25, v0.z);
    float arm_l = (1.0 - smoothstep(-0.62, -0.50, v0.x)) * (1.0 - smoothstep(1.35, 1.50, v0.z));
    float idle = sin(TIME * 1.8) * 0.06 * (1.0 - amp);
    vec3 ar = rot_x(v0, 1.5, sw * 0.9 * amp + idle);
    ar = rot_y(ar, vec2(0.45, 1.5), -air * (0.40 + 0.25 * sin(TIME * 9.0)));
    vec3 al = rot_x(v0, 1.5, -sw * 0.9 * amp - idle);
    al = rot_y(al, vec2(-0.45, 1.5), air * (0.40 + 0.25 * sin(TIME * 9.0 + 1.5)));
    d += (ar - v0) * arm_r + (al - v0) * arm_l;

    float up = smoothstep(0.75, 1.0, v0.z);
    d += (rot_z(v0, sw * 0.10 * amp) - v0) * up;

    VERTEX = v0 + d;
}

void fragment() {
    ALBEDO = albedo.rgb;
    ROUGHNESS = rough;
    METALLIC = 0.0;
}
"""
const MODEL_COLORS = {
    "Object_2": [0.0442, 0.2831, 0.7410, 0.20],
    "Object_3": [0.6994, 0.6855, 0.6855, 0.22],
    "Object_4": [0.8000, 0.0908, 0.0767, 0.22],
    "Object_5": [0.7991, 0.2122, 0.0844, 0.50],
    "Object_6": [0.6643, 0.7896, 0.8000, 0.66],
    "Object_7": [0.6643, 0.7896, 0.8000, 0.66]
}
const MODEL_YAW = PI  # set to 0.0 if your astronaut walks backwards
const NAMES = ["Moonwalk Training", "Find the Water Ice", "Repair the Base", "Solar Storm Run"]
const TUT_TEXT = [
    "Walk to the green beacon. Move: W A S D. Look around: move the mouse (or use the arrow keys).",
    "Climb the hill! Hold W and press SPACE to hop. HOLD SPACE for a big, floaty Moon jump (tap it for a small hop).",
    "Sprint to the far beacon: hold SHIFT while walking. Sprinting burns oxygen much faster!",
    "Head back to base and stand in the blue circle by the habitat to refill your oxygen."
]
const TUT_DONE = [
    "Nice walking! In a heavy suit the Apollo astronauts found that bounding like a kangaroo was often easier.",
    "Great jump! On the Moon you weigh only about one-sixth of what you weigh on Earth.",
    "Sprint complete. Your oxygen drains faster when you hurry, so plan your trips!",
    "Training complete!"
]
const ICE_FACTS = [
    "Ice found! Some craters near the Moon's poles never see sunlight, so they stay colder than -200 C and can trap ice for billions of years.",
    "Water ice can be melted for drinking, split into oxygen to breathe, and into hydrogen for rocket fuel.",
    "In 2009 NASA's LCROSS mission crashed a rocket stage into a south polar crater and detected water in the debris.",
    "Launching water from Earth is very expensive. Using ice found on the Moon is called in-situ resource utilization.",
    "A person needs about 2 to 3 liters of drinking water every day, plus water for food and washing.",
    "Ice is mixed with Moon dust, so it has to be heated and cleaned before anyone can drink it.",
    "That was the last sample! Carry the ice back to the water processor at the base."
]
const QUIZ = {
    "SOLAR CELLS": {"q": "Why does a Moon base with solar panels need big batteries?", "a": "The lunar night lasts about 14 Earth days", "w": ["The Sun is much weaker on the Moon", "Moon dust drains the power"],
        "e": "Panels make no power at night, so batteries (and careful load shedding) carry the base through two weeks of darkness."},
    "OXYGEN VALVE": {"q": "An oxygen generator splits water into oxygen and what else?", "a": "Hydrogen", "w": ["Carbon dioxide", "Helium"],
        "e": "This is called electrolysis. The hydrogen can be stored, or even used as fuel."},
    "ANTENNA FEED": {"q": "Why must a base antenna be pointed at Earth?", "a": "Radio signals travel in straight beams", "w": ["Earth pulls the signal toward it", "Radio only works in daylight"],
        "e": "A dish focuses the signal into a narrow beam, so it has to aim at the receiver. Signals take about 1.3 seconds to reach Earth."}
}

var mission = 0
var model_loaded = false
var bob_t = 0.0
var model_mats = []
var coyote = 0.0
var jump_buf = 0.0
var jump_prev = false
var was_floor = false
var fall_v = 0.0
var squash = 0.0
var squash_v = 0.0
var shake = 0.0
var walk_phase = 0.0
var air_blend = 0.0
var last_step = -1
var turn_amt = 0.0
var dust_mesh = null
var anim_player = null
var anim_idle = ""
var anim_walk = ""
var anim_run = ""
var anim_air = ""
var player
var player_mesh
var pivot
var cam
var yaw = 0.0
var pitch = -0.35
var vy = 0.0
var hvel = Vector3.ZERO
var oxygen = 100.0
var blackouts = 0
var wrong = 0
var t = 0.0
var ended = false
var paused = true
var intro_instructions = true
var intro_time_left = 5.0
var sprinting = false
var in_crater = false
var warned_low = false
var targets = []
var craters = []
var beacons = []
var processor = null
var carrying = ""
var hold = 0.0
var last_id = -1
var step = 0
var collected = 0
var need_ice = 7
var repaired = 0
var sensors = 0
var dose = 0.0
var storm_active = false
var alerted = [false, false, false]
var quiz = null
var msg_t = 0.0
var pending = null
var pending_t = 0.0

var hud
var l_title
var l_obj
var l_o2
var bar_o2
var l_prompt
var interact_pill
var l_msg
var bar_hold
var arrow
var quiz_panel
var l_quiz
var overlay
var l_overlay
var storm_tint
var l_dose
var bar_dose
var jump_sfx: AudioStreamPlayer
var run_sfx: AudioStreamPlayer
var run_sfx_clock = 0.0


# ------------------------------------------------------------ helpers
func mat(c, emissive = false, unshaded = false):
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.9
    if emissive:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = 1.4
    if unshaded:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m


func add_mesh(parent, mesh, m, pos, rot = Vector3.ZERO):
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = m
    mi.position = pos
    mi.rotation = rot
    parent.add_child(mi)
    return mi


func add_solid(parent, shape, pos, rot = Vector3.ZERO):
    var sb = StaticBody3D.new()
    var cs = CollisionShape3D.new()
    cs.shape = shape
    sb.add_child(cs)
    sb.position = pos
    sb.rotation = rot
    parent.add_child(sb)
    return sb


func tag(text, pos, color = Color.WHITE, fsize = 56):
    var l = Label3D.new()
    l.text = text
    l.position = pos
    l.font_size = fsize
    l.pixel_size = 0.012
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.modulate = color
    l.outline_size = 12
    l.no_depth_test = true
    add_child(l)
    return l


func box_mesh(x, y, z):
    var b = BoxMesh.new()
    b.size = Vector3(x, y, z)
    return b


func cyl_mesh(r, h):
    var c = CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    return c


func rand_ring(rmin, rmax):
    var a = randf() * TAU
    var r = randf_range(rmin, rmax)
    return Vector3(cos(a) * r, 0, sin(a) * r)


# ------------------------------------------------------------ world
func _ready():
    jump_sfx = AudioStreamPlayer.new()
    jump_sfx.name = "JumpSqueak"
    jump_sfx.stream = load("res://audio/jump_squeak.wav")
    jump_sfx.volume_db = -5.0
    add_child(jump_sfx)
    run_sfx = AudioStreamPlayer.new()
    run_sfx.name = "CartoonFootsteps"
    run_sfx.stream = load("res://audio/cartoon_footsteps.wav")
    run_sfx.volume_db = -9.0
    add_child(run_sfx)
    build_environment()
    build_ground()
    build_scatter()
    build_base()
    build_player()
    build_hud()
    match mission:
        0:
            setup_tutorial()
        1:
            setup_ice()
        2:
            setup_repair()
        3:
            setup_storm()
    show_instructions()


func _exit_tree():
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func build_environment():
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.0, 0.0, 0.015)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.4, 0.43, 0.6)
    env.ambient_light_energy = 0.7
    var we = WorldEnvironment.new()
    we.environment = env
    add_child(we)
    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-28, 55, 0)
    sun.light_energy = 1.7
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 120.0
    add_child(sun)
    # stars
    var sm = SphereMesh.new()
    sm.radius = 3.0
    sm.height = 6.0
    sm.radial_segments = 6
    sm.rings = 3
    sm.material = mat(Color.WHITE, false, true)
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = sm
    mm.instance_count = 350
    for i in range(350):
        var d = Vector3(randf_range(-1, 1), randf_range(0.02, 1), randf_range(-1, 1)).normalized() * 1500.0
        mm.set_instance_transform(i, Transform3D(Basis(), d))
    var mmi = MultiMeshInstance3D.new()
    mmi.multimesh = mm
    add_child(mmi)
    # Earth in the sky
    var em = SphereMesh.new()
    em.radius = 150.0
    em.height = 300.0
    var earth_m = mat(Color(0.15, 0.4, 0.9), true)
    earth_m.emission_energy_multiplier = 0.5
    add_mesh(self, em, earth_m, Vector3(-700, 420, -1000))


func build_ground():
    # Layered lunar regolith: mottled albedo plus a fine bump map so the
    # surface catches the hard sunlight instead of reading as a flat plane.
    var pm = PlaneMesh.new()
    pm.size = Vector2(3000, 3000)
    pm.subdivide_width = 160
    pm.subdivide_depth = 160

    var base_noise = FastNoiseLite.new()
    base_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    base_noise.frequency = 0.018
    base_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    base_noise.fractal_octaves = 5
    base_noise.fractal_lacunarity = 2.1
    base_noise.fractal_gain = 0.48

    var albedo_noise = NoiseTexture2D.new()
    albedo_noise.noise = base_noise
    albedo_noise.width = 1024
    albedo_noise.height = 1024
    albedo_noise.seamless = true
    albedo_noise.seamless_blend_skirt = 0.15

    var fine_noise = FastNoiseLite.new()
    fine_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
    fine_noise.frequency = 0.11
    fine_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    fine_noise.fractal_octaves = 3
    var bump_noise = NoiseTexture2D.new()
    bump_noise.noise = fine_noise
    bump_noise.width = 1024
    bump_noise.height = 1024
    bump_noise.seamless = true
    bump_noise.as_normal_map = true
    bump_noise.bump_strength = 3.2

    var m = mat(Color(0.48, 0.48, 0.50))
    m.albedo_texture = albedo_noise
    m.uv1_scale = Vector3(210, 210, 1)
    m.roughness = 1.0
    m.normal_enabled = true
    m.normal_texture = bump_noise
    m.normal_scale = 1.35
    add_mesh(self, pm, m, Vector3.ZERO)

    # Fine dust ridges and shallow impact-scoured patches around the play area.
    var dust_dark = mat(Color(0.27, 0.28, 0.30))
    var dust_light = mat(Color(0.61, 0.60, 0.58))
    for i in range(42):
        var p = rand_ring(18, 190)
        var patch = SphereMesh.new()
        var radius = randf_range(2.5, 9.0)
        patch.radius = radius
        patch.height = 0.12
        patch.radial_segments = 18
        patch.rings = 5
        var patch_mat = dust_dark if i % 3 == 0 else dust_light
        add_mesh(self, patch, patch_mat, Vector3(p.x, 0.015, p.z), Vector3(0, randf() * TAU, 0))

    var bs = BoxShape3D.new()
    bs.size = Vector3(3000, 2, 3000)
    add_solid(self, bs, Vector3(0, -1, 0))


func add_hill(p, R, h, m):
    var sm = SphereMesh.new()
    sm.radius = R
    sm.height = R * 2.0
    sm.radial_segments = 28
    sm.rings = 14
    var c = Vector3(p.x, h - R, p.z)
    add_mesh(self, sm, m, c)
    var sh = SphereShape3D.new()
    sh.radius = R
    add_solid(self, sh, c)


func add_crater(p, r):
    # Dark, shallow bowl with an irregular raised ejecta rim.
    var bowl_mesh = SphereMesh.new()
    bowl_mesh.radius = r
    bowl_mesh.height = 0.20
    bowl_mesh.radial_segments = 32
    bowl_mesh.rings = 8
    add_mesh(self, bowl_mesh, mat(Color(0.20, 0.21, 0.23)), Vector3(p.x, 0.035, p.z))

    var rim = TorusMesh.new()
    rim.inner_radius = r * 0.88
    rim.outer_radius = r * 1.16
    rim.rings = 12
    rim.ring_segments = 40
    add_mesh(self, rim, mat(Color(0.66, 0.65, 0.62)), Vector3(p.x, 0.16, p.z))

    # Broken ejecta fragments around the crater edge make the silhouette less perfect.
    var ejecta_mat = mat(Color(0.43, 0.43, 0.44))
    for i in range(18):
        var a = TAU * float(i) / 18.0 + randf_range(-0.12, 0.12)
        var rr = r * randf_range(1.05, 1.45)
        var size = randf_range(0.35, 1.15)
        var rock = SphereMesh.new()
        rock.radius = size
        rock.height = size * randf_range(0.55, 1.0)
        rock.radial_segments = 10
        rock.rings = 5
        add_mesh(self, rock, ejecta_mat, Vector3(p.x + cos(a) * rr, size * 0.22, p.z + sin(a) * rr), Vector3(randf(), randf() * TAU, randf()))
    craters.append({"pos": p, "r": r})


func build_scatter():
    var rock_m = mat(Color(0.39, 0.39, 0.41))
    for i in range(36):
        var p = rand_ring(42, 320)
        var R = randf_range(10.0, 22.0)
        add_hill(p, R, R * randf_range(0.10, 0.25), rock_m)
    var bm = SphereMesh.new()
    for i in range(190):
        var p = rand_ring(12, 310)
        var r = randf_range(0.35, 2.8)
        var sm = SphereMesh.new()
        sm.radius = r
        sm.height = r * 2.0
        sm.radial_segments = 12
        sm.rings = 6
        var c = Vector3(p.x, r * 0.3, p.z)
        add_mesh(self, sm, rock_m, c)
        var sh = SphereShape3D.new()
        sh.radius = r
        add_solid(self, sh, c)
    for i in range(16):
        add_crater(rand_ring(45, 270), randf_range(7.0, 14.0))


func build_base():
    var white = mat(Color(0.88, 0.88, 0.92))
    var gray = mat(Color(0.45, 0.46, 0.5))
    var glass = mat(Color(0.3, 0.7, 1.0), true)
    # main habitat
    add_mesh(self, cyl_mesh(3.5, 14.0), white, Vector3(0, 3.5, -4), Vector3(0, 0, PI / 2.0))
    var hs = CylinderShape3D.new()
    hs.radius = 3.5
    hs.height = 14.0
    add_solid(self, hs, Vector3(0, 3.5, -4), Vector3(0, 0, PI / 2.0))
    for i in range(-2, 3):
        add_mesh(self, box_mesh(1.4, 1.0, 0.2), glass, Vector3(i * 2.6, 4.2, -0.6))
    tag("MOON BASE ALPHA", Vector3(0, 10, -4), Color(1, 0.9, 0.5))
    # oxygen refill circle
    var disc_m = mat(Color(0.3, 0.8, 1.0, 0.5), true, true)
    disc_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    disc_m.albedo_color = Color(0.3, 0.8, 1.0, 0.45)
    add_mesh(self, cyl_mesh(6.0, 0.06), disc_m, Vector3(O2_STATION.x, 0.06, O2_STATION.z))
    add_mesh(self, box_mesh(1.2, 2.4, 1.2), gray, Vector3(O2_STATION.x + 5.5, 1.2, O2_STATION.z))
    tag("OXYGEN REFILL", Vector3(O2_STATION.x, 5, O2_STATION.z), Color(0.5, 0.9, 1.0))
    # water processor
    add_mesh(self, box_mesh(3.0, 2.2, 2.2), gray, Vector3(-8, 1.1, 8))
    add_solid(self, BoxShape3D.new(), Vector3(-8, 0.5, 8))
    add_mesh(self, cyl_mesh(0.7, 3.0), white, Vector3(-9.2, 2.6, 8))
    tag("WATER PROCESSOR", Vector3(-8, 4.5, 8), Color(0.6, 0.9, 1.0), 48)
    # solar array
    var panel_m = mat(Color(0.1, 0.15, 0.4), true)
    panel_m.emission_energy_multiplier = 0.3
    add_mesh(self, cyl_mesh(0.25, 3.0), gray, Vector3(22, 1.5, -10))
    add_mesh(self, box_mesh(9.0, 0.2, 5.0), panel_m, Vector3(22, 3.2, -10), Vector3(-0.5, 0, 0))
    tag("SOLAR ARRAY", Vector3(22, 7, -10), Color(1, 0.9, 0.5), 48)
    # oxygen generator
    add_mesh(self, box_mesh(4.0, 3.0, 3.0), white, Vector3(-20, 1.5, -12))
    add_mesh(self, cyl_mesh(0.9, 3.4), gray, Vector3(-17.5, 1.7, -12))
    var gb = BoxShape3D.new()
    gb.size = Vector3(4, 3, 3)
    add_solid(self, gb, Vector3(-20, 1.5, -12))
    tag("OXYGEN GENERATOR", Vector3(-20, 6, -12), Color(1, 0.9, 0.5), 48)
    # antenna
    add_mesh(self, cyl_mesh(0.3, 10.0), gray, Vector3(8, 5, 22))
    var dish = SphereMesh.new()
    dish.radius = 2.4
    dish.height = 2.4
    dish.is_hemisphere = true
    add_mesh(self, dish, white, Vector3(8, 10, 22), Vector3(-1.0, 0, 0))
    tag("ANTENNA", Vector3(8, 14, 22), Color(1, 0.9, 0.5), 48)
    # storm shelter dome
    var dome = SphereMesh.new()
    dome.radius = 7.0
    dome.height = 7.0
    dome.is_hemisphere = true
    var dm = mat(Color(0.3, 0.55, 1.0))
    dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    dm.albedo_color = Color(0.3, 0.55, 1.0, 0.45)
    add_mesh(self, dome, dm, SHELTER)
    add_mesh(self, cyl_mesh(7.0, 0.1), mat(Color(0.6, 0.75, 1.0)), SHELTER + Vector3(0, 0.05, 0))
    tag("STORM SHELTER", SHELTER + Vector3(0, 10, 0), Color(0.6, 0.85, 1.0))
    # parked lander
    add_mesh(self, box_mesh(3.0, 2.0, 3.0), mat(Color(0.85, 0.7, 0.3)), Vector3(-30, 2.5, 6))
    for sx in [-1, 1]:
        for sz in [-1, 1]:
            add_mesh(self, cyl_mesh(0.12, 2.6), gray, Vector3(-30 + sx * 1.8, 1.2, 6 + sz * 1.8), Vector3(sz * 0.3, 0, -sx * 0.3))


func build_player():
    player = CharacterBody3D.new()
    var cs = CollisionShape3D.new()
    var cap = CapsuleShape3D.new()
    cap.radius = 0.5
    cap.height = 1.8
    cs.shape = cap
    cs.position = Vector3(0, 0.9, 0)
    player.add_child(cs)
    player.position = Vector3(0, 0.3, 12)
    player.floor_max_angle = deg_to_rad(50.0)
    add_child(player)
    player_mesh = Node3D.new()
    player.add_child(player_mesh)
    if not try_load_model():
        build_default_astronaut()
    pivot = Node3D.new()
    add_child(pivot)
    cam = Camera3D.new()
    cam.position = Vector3(0, 0.8, 6.5)
    cam.fov = 70.0
    cam.far = 4000.0
    pivot.add_child(cam)
    cam.current = true


func build_default_astronaut():
    var suit = mat(Color(0.95, 0.95, 0.98))
    var cm = CapsuleMesh.new()
    cm.radius = 0.45
    cm.height = 1.4
    add_mesh(player_mesh, cm, suit, Vector3(0, 0.8, 0))
    var hm = SphereMesh.new()
    hm.radius = 0.42
    hm.height = 0.84
    add_mesh(player_mesh, hm, suit, Vector3(0, 1.6, 0))
    var vm = SphereMesh.new()
    vm.radius = 0.3
    vm.height = 0.6
    add_mesh(player_mesh, vm, mat(Color(0.9, 0.7, 0.2), true), Vector3(0, 1.62, -0.2))
    add_mesh(player_mesh, box_mesh(0.6, 0.8, 0.3), mat(Color(0.6, 0.6, 0.65)), Vector3(0, 1.0, 0.45))


func try_load_model():
    for p in MODEL_PATHS:
        if ResourceLoader.exists(p):
            var res = load(p)
            if res is PackedScene:
                var inst = res.instantiate()
                if inst is Node3D:
                    inst.rotation.y = MODEL_YAW
                    player_mesh.add_child(inst)
                    apply_model_colors(inst)
                    fit_model(inst)
                    anim_player = find_anim_player(inst)
                    setup_anims()
                    model_loaded = true
                    print("Loaded astronaut model: ", p)
                    return true
    print("No custom astronaut found in res://models/ - using the built-in astronaut.")
    return false


func apply_model_colors(inst):
    var shader = Shader.new()
    shader.code = MODEL_SHADER
    for mi in inst.find_children("*", "MeshInstance3D", true, false):
        var key = String(mi.name)
        if MODEL_COLORS.has(key):
            var c = MODEL_COLORS[key]
            var sm = ShaderMaterial.new()
            sm.shader = shader
            sm.set_shader_parameter("albedo", Color(c[0], c[1], c[2]).linear_to_srgb())
            sm.set_shader_parameter("rough", 1.0 - c[3])
            mi.material_override = sm
            mi.extra_cull_margin = 3.0
            model_mats.append(sm)


func model_aabb(inst):
    var total = null
    for mi in inst.find_children("*", "MeshInstance3D", true, false):
        var box = mi.global_transform * mi.get_aabb()
        if total == null:
            total = box
        else:
            total = total.merge(box)
    return total


func fit_model(inst):
    var box = model_aabb(inst)
    if box == null:
        return
    var h = maxf(box.size.y, 0.001)
    inst.scale = Vector3.ONE * (MODEL_HEIGHT / h)
    box = model_aabb(inst)
    var base = player_mesh.global_position
    var c = box.get_center()
    inst.position += Vector3(base.x - c.x, base.y - box.position.y, base.z - c.z)


func find_anim_player(inst):
    var list = inst.find_children("*", "AnimationPlayer", true, false)
    if list.size() > 0:
        return list[0]
    return null


func find_anim(words):
    if anim_player == null:
        return ""
    var names = anim_player.get_animation_list()
    for w in words:
        for n in names:
            if String(n).to_lower() == w:
                return String(n)
    for w in words:
        for n in names:
            if String(n).to_lower().contains(w):
                return String(n)
    return ""


func setup_anims():
    if anim_player == null:
        return
    anim_idle = find_anim(["idle"])
    anim_walk = find_anim(["walking", "walk"])
    anim_run = find_anim(["jogging forward", "run forward", "medium run", "run", "jog"])
    anim_air = find_anim(["floating", "falling", "float", "fall"])
    for n in [anim_idle, anim_walk, anim_run, anim_air]:
        if n != "":
            anim_player.get_animation(n).loop_mode = Animation.LOOP_LINEAR
    if anim_idle != "":
        anim_player.play(anim_idle)


func puff(pos, count, speed):
    if dust_mesh == null:
        var sm = SphereMesh.new()
        sm.radius = 0.12
        sm.height = 0.24
        sm.radial_segments = 6
        sm.rings = 3
        sm.material = mat(Color(0.72, 0.71, 0.70))
        dust_mesh = sm
    var p = CPUParticles3D.new()
    p.position = pos
    p.mesh = dust_mesh
    p.amount = count
    p.lifetime = 1.1
    p.one_shot = true
    p.explosiveness = 0.95
    p.direction = Vector3(0, 1, 0)
    p.spread = 80.0
    p.gravity = Vector3(0, -1.6, 0)
    p.initial_velocity_min = speed * 0.4
    p.initial_velocity_max = speed
    p.scale_amount_min = 0.5
    p.scale_amount_max = 1.3
    add_child(p)
    p.emitting = true
    var tm = Timer.new()
    tm.wait_time = 2.0
    tm.one_shot = true
    tm.autostart = true
    p.add_child(tm)
    tm.timeout.connect(p.queue_free)


func update_anim(dir, delta):
    var hs = Vector2(hvel.x, hvel.z).length()
    var on_floor = player.is_on_floor()
    var target_air = 0.0
    if not on_floor and coyote <= 0.0:
        target_air = 1.0
    air_blend = move_toward(air_blend, target_air, 7.0 * delta)
    if on_floor:
        walk_phase += hs * 1.25 * delta
    var amp = clampf(hs / 7.0, 0.0, 1.4) * (1.0 - air_blend)
    for m in model_mats:
        m.set_shader_parameter("phase", walk_phase)
        m.set_shader_parameter("amp", amp)
        m.set_shader_parameter("air", air_blend)
    # footstep dust
    var step_idx = int(floor(walk_phase / PI))
    if step_idx != last_step:
        last_step = step_idx
        if on_floor and hs > 1.2:
            puff(player.position + Vector3(randf_range(-0.2, 0.2), 0.05, randf_range(-0.2, 0.2)), 3, 1.2)
            if run_sfx != null and not run_sfx.playing:
                run_sfx.pitch_scale = 1.12 if sprinting else 0.88
                run_sfx.volume_db = -8.0 if sprinting else -11.0
                run_sfx.play()
    # squash and stretch (spring)
    squash_v += (-squash * 140.0 - squash_v * 11.0) * delta
    squash += squash_v * delta
    squash = clampf(squash, -0.35, 0.35)
    player_mesh.scale = Vector3(1.0 - squash * 0.5, 1.0 + squash, 1.0 - squash * 0.5)
    # lean forward with speed, roll into turns
    var lean = -0.20 * clampf(hs / 7.0, 0.0, 1.4) * (1.0 - 0.5 * air_blend)
    player_mesh.rotation.x = lerpf(player_mesh.rotation.x, lean, 8.0 * delta)
    var roll = clampf(-turn_amt * 0.25, -0.25, 0.25) * clampf(hs / 7.0, 0.0, 1.0)
    player_mesh.rotation.z = lerpf(player_mesh.rotation.z, roll, 8.0 * delta)
    if model_mats.size() == 0 and anim_player == null:
        var bob = 0.0
        if on_floor and hs > 0.5:
            bob = absf(sin(walk_phase * 2.0)) * 0.12
        player_mesh.position.y = lerpf(player_mesh.position.y, bob, 12.0 * delta)
    if anim_player != null:
        var want = anim_idle
        if not on_floor and anim_air != "":
            want = anim_air
        elif dir.length() > 0.1:
            if sprinting and anim_run != "":
                want = anim_run
            elif anim_walk != "":
                want = anim_walk
            elif anim_run != "":
                want = anim_run
        if want != "" and anim_player.current_animation != want:
            anim_player.play(want, 0.2)


# ------------------------------------------------------------ HUD
func lab(parent, text, pos, fsize = 18, color = Color.WHITE, width = 0, center = false):
    var l = Label.new()
    l.text = text
    l.position = pos
    l.add_theme_font_size_override("font_size", fsize)
    var hud_font = SystemFont.new()
    hud_font.font_names = PackedStringArray(["Showcard Gothic", "Orbitron", "Eurostile", "Bank Gothic", "Rajdhani", "Arial"])
    l.add_theme_font_override("font", hud_font)
    l.add_theme_color_override("font_color", color)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 6)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if width > 0:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(width, 0)
        l.size = Vector2(width, 0)
    if center:
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(l)
    return l


func rect(parent, pos, sz, color):
    var r = ColorRect.new()
    r.position = pos
    r.size = sz
    r.color = color
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(r)
    return r


func build_hud():
    hud = CanvasLayer.new()
    add_child(hud)
    storm_tint = rect(hud, Vector2(0, 0), Vector2(1280, 720), Color(1, 0.1, 0.05, 0.0))
    # Floating top-left control guide: intentionally no panel or background behind it.
    lab(hud, "FLIGHT CONTROLS", Vector2(20, 14), 14, Color(0.55, 0.83, 1.0))
    lab(hud, "W A S D  MOVE     MOUSE  LOOK", Vector2(20, 36), 13, Color(0.91, 0.96, 1.0))
    lab(hud, "SPACE  JUMP     SHIFT  SPRINT", Vector2(20, 56), 13, Color(0.91, 0.96, 1.0))
    lab(hud, "E  INTERACT     ESC  PAUSE", Vector2(20, 76), 13, Color(0.91, 0.96, 1.0))
    l_title = lab(hud, "", Vector2(20, 112), 20, Color(1, 0.85, 0.4))
    l_obj = lab(hud, "", Vector2(20, 140), 15, Color.WHITE, 450)
    l_o2 = lab(hud, "", Vector2(20, 190), 15, Color(0.6, 0.9, 1))
    bar_o2 = ProgressBar.new()
    bar_o2.position = Vector2(150, 192)
    bar_o2.size = Vector2(310, 16)
    bar_o2.max_value = 100.0
    bar_o2.show_percentage = false
    hud.add_child(bar_o2)
    l_dose = lab(hud, "RADIATION", Vector2(20, 216), 13, Color(1, 0.7, 0.4))
    bar_dose = ProgressBar.new()
    bar_dose.position = Vector2(150, 218)
    bar_dose.size = Vector2(310, 12)
    bar_dose.max_value = 100.0
    bar_dose.show_percentage = false
    hud.add_child(bar_dose)
    l_dose.visible = false
    bar_dose.visible = false
    interact_pill = Panel.new()
    interact_pill.position = Vector2(390, 532)
    interact_pill.size = Vector2(500, 64)
    var pill_style = StyleBoxFlat.new()
    pill_style.bg_color = Color(0.035, 0.085, 0.16, 0.68)
    pill_style.corner_radius_top_left = 32
    pill_style.corner_radius_top_right = 32
    pill_style.corner_radius_bottom_left = 32
    pill_style.corner_radius_bottom_right = 32
    pill_style.border_color = Color(0.35, 0.68, 0.95, 0.65)
    pill_style.set_border_width_all(2)
    pill_style.shadow_color = Color(0.12, 0.45, 0.8, 0.25)
    pill_style.shadow_size = 12
    pill_style.shadow_offset = Vector2(0, 4)
    interact_pill.add_theme_stylebox_override("panel", pill_style)
    hud.add_child(interact_pill)
    interact_pill.visible = false
    l_prompt = lab(hud, "", Vector2(400, 548), 22, Color(0.88, 0.94, 1.0), 480, true)
    bar_hold = ProgressBar.new()
    bar_hold.position = Vector2(540, 590)
    bar_hold.size = Vector2(200, 14)
    bar_hold.max_value = 100.0
    bar_hold.show_percentage = false
    bar_hold.visible = false
    hud.add_child(bar_hold)
    l_msg = lab(hud, "", Vector2(190, 620), 20, Color.WHITE, 900, true)
    arrow = Control.new()
    arrow.set_script(load("res://arrow.gd"))
    arrow.position = Vector2(1130, 40)
    arrow.size = Vector2(110, 110)
    hud.add_child(arrow)
    lab(hud, "SCANNER", Vector2(1150, 12), 14, Color(0.7, 0.85, 1))
    if model_loaded:
        lab(hud, "Astronaut: 3D Cute Astronaut made in Blender by Naomifz (CC BY-NC-ND 4.0, Sketchfab)", Vector2(14, 696), 12, Color(0.7, 0.8, 1))
    quiz_panel = rect(hud, Vector2(240, 140), Vector2(800, 400), Color(0, 0.05, 0.15, 0.93))
    l_quiz = lab(quiz_panel, "", Vector2(26, 20), 24, Color.WHITE, 750)
    quiz_panel.visible = false
    overlay = rect(hud, Vector2(0, 0), Vector2(1280, 720), Color(0.005, 0.015, 0.045, 0.82))
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var card = Panel.new()
    card.position = Vector2(250, 145)
    card.size = Vector2(780, 430)
    var card_style = StyleBoxFlat.new()
    card_style.bg_color = Color(0.025, 0.075, 0.14, 0.96)
    card_style.border_color = Color(0.25, 0.68, 0.95, 0.9)
    card_style.set_border_width_all(2)
    card_style.corner_radius_top_left = 28
    card_style.corner_radius_top_right = 28
    card_style.corner_radius_bottom_left = 28
    card_style.corner_radius_bottom_right = 28
    card.add_theme_stylebox_override("panel", card_style)
    overlay.add_child(card)
    l_overlay = lab(card, "", Vector2(42, 42), 23, Color.WHITE, 696, true)


func show_instructions():
    intro_instructions = true
    intro_time_left = 5.0
    paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    l_overlay.text = "MISSION BRIEFING\n\n" + NAMES[mission].to_upper() + "\n\n" + objective_text() + "\n\nW A S D  MOVE     MOUSE  LOOK\nSPACE  JUMP     SHIFT  SPRINT\nE  HOLD TO INTERACT     ESC  PAUSE\n\nStarting in 5 seconds  •  Press any key to begin"
    overlay.visible = true


func show_overlay(text):
    intro_instructions = false
    paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    l_overlay.text = text
    overlay.visible = true


func resume():
    intro_instructions = false
    paused = false
    overlay.visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func say(text, secs = 6.0):
    l_msg.text = text
    msg_t = secs


# ------------------------------------------------------------ mission setup
func add_target(kind, pos, r, hold_s, node, data):
    var tg = {"id": targets.size(), "kind": kind, "pos": pos, "r": r, "hold": hold_s, "node": node, "data": data, "active": true, "done": false}
    targets.append(tg)
    return tg


func make_beacon(pos, color, tall = 16.0):
    var n = Node3D.new()
    n.position = pos
    var m = mat(color, true, true)
    m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.albedo_color = Color(color.r, color.g, color.b, 0.4)
    add_mesh(n, cyl_mesh(0.7, tall), m, Vector3(0, tall / 2.0, 0))
    var tor = TorusMesh.new()
    tor.inner_radius = 2.6
    tor.outer_radius = 3.1
    add_mesh(n, tor, mat(color, true, true), Vector3(0, 0.2, 0))
    add_child(n)
    return n


func setup_tutorial():
    add_hill(Vector3(36, 0, -24), 16.0, 4.0, mat(Color(0.52, 0.5, 0.49)))
    var pts = [Vector3(24, 0, 14), Vector3(36, 4, -24), Vector3(95, 0, -50), Vector3(0, 0, 5)]
    for i in range(pts.size()):
        var n = make_beacon(pts[i], Color(0.3, 1.0, 0.5))
        var tg = add_target("beacon", pts[i], 4.0, 0.0, n, null)
        tg["active"] = (i == 0)
        n.visible = (i == 0)
        beacons.append(tg)
    say("Welcome to Moon Base Alpha, trainee! Follow the scanner arrow (top right) to each green beacon.", 8.0)


func setup_ice():
    for i in range(need_ice):
        var a = (TAU / need_ice) * i + randf_range(-0.25, 0.25)
        var r = randf_range(60.0, 170.0)
        var p = Vector3(cos(a) * r, 0, sin(a) * r)
        add_crater(p, 9.0)
        var n = make_beacon(p, Color(0.4, 0.8, 1.0), 12.0)
        var cm = mat(Color(0.6, 0.9, 1.0), true)
        add_mesh(n, box_mesh(0.9, 1.8, 0.9), cm, Vector3(0, 0.9, 0), Vector3(0.3, 0.6, 0.2))
        add_mesh(n, box_mesh(0.6, 1.2, 0.6), cm, Vector3(1.0, 0.6, 0.6), Vector3(-0.2, 0.2, 0.4))
        add_target("ice", p, 3.8, 2.0, n, null)
    processor = add_target("processor", Vector3(-8, 0, 8), 5.0, 2.0, null, null)
    processor["active"] = false
    say("Water is life! Scientists think ice hides in dark craters. Follow the scanner to the blue beacons and drill for ice samples.", 9.0)


func setup_repair():
    var parts = ["SOLAR CELLS", "OXYGEN VALVE", "ANTENNA FEED"]
    var mods = [Vector3(22, 0, -10), Vector3(-20, 0, -12), Vector3(8, 0, 22)]
    var names = ["Solar array", "Oxygen generator", "Antenna"]
    var heights = [8.0, 7.0, 15.0]
    for i in range(3):
        var tl = tag("BROKEN! needs " + parts[i], mods[i] + Vector3(0, heights[i] + 2.5, 0), Color(1, 0.4, 0.3), 44)
        add_target("module", mods[i], 6.0, 2.5, null, {"need": parts[i], "name": names[i], "tag": tl})
    var base_a = randf() * TAU
    for i in range(3):
        var a = base_a + i * TAU / 3.0 + randf_range(-0.3, 0.3)
        var r = randf_range(60.0, 125.0)
        var p = Vector3(cos(a) * r, 0, sin(a) * r)
        var n = Node3D.new()
        n.position = p
        add_mesh(n, box_mesh(1.8, 1.4, 1.4), mat(Color(0.95, 0.5, 0.15)), Vector3(0, 0.7, 0))
        add_mesh(n, box_mesh(1.9, 0.25, 1.5), mat(Color(1, 1, 1)), Vector3(0, 1.0, 0))
        add_child(n)
        tag(parts[i], p + Vector3(0, 3.2, 0), Color(1, 0.8, 0.3), 44)
        var tg = add_target("crate", p, 3.2, 0.5, n, {"part": parts[i]})
    say("A meteoroid shower damaged the base! Three modules are broken. Find the matching supply crates and carry one part at a time.", 9.0)


func setup_storm():
    var base_a = randf() * TAU
    for i in range(3):
        var a = base_a + i * TAU / 3.0 + randf_range(-0.3, 0.3)
        var r = randf_range(65.0, 100.0)
        var p = Vector3(cos(a) * r, 0, sin(a) * r)
        var n = make_beacon(p, Color(1.0, 0.6, 0.15))
        tag("SENSOR SITE", p + Vector3(0, 6, 0), Color(1, 0.7, 0.3), 44)
        add_target("sensor", p, 3.8, 2.0, n, null)
    l_dose.visible = true
    bar_dose.visible = true


# ------------------------------------------------------------ input
func _input(event):
    if event is InputEventMouseMotion and not paused and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.003
        pitch = clampf(pitch - event.relative.y * 0.003, -1.1, 0.15)
    elif event is InputEventMouseButton and event.pressed and paused and not ended:
        resume()
    elif event is InputEventKey and event.pressed and not event.echo:
        if intro_instructions:
            resume()
            return
        if event.keycode == KEY_ESCAPE and not paused:
            show_overlay("PAUSED\n\nClick to resume\nBackspace = quit to menu")
        elif event.keycode == KEY_BACKSPACE and paused:
            quit_requested.emit()
        elif quiz != null and not paused:
            if event.keycode == KEY_1:
                answer_quiz(0)
            elif event.keycode == KEY_2:
                answer_quiz(1)
            elif event.keycode == KEY_3:
                answer_quiz(2)


# ------------------------------------------------------------ simulation
func in_station():
    var dx = player.position.x - O2_STATION.x
    var dz = player.position.z - O2_STATION.z
    return dx * dx + dz * dz < 36.0


func in_shelter():
    var dx = player.position.x - SHELTER.x
    var dz = player.position.z - SHELTER.z
    return dx * dx + dz * dz < 42.0


func _physics_process(delta):
    if ended or paused:
        return
    var ix = 0.0
    var iz = 0.0
    if quiz == null:
        if Input.is_key_pressed(KEY_A):
            ix -= 1.0
        if Input.is_key_pressed(KEY_D):
            ix += 1.0
        if Input.is_key_pressed(KEY_W):
            iz -= 1.0
        if Input.is_key_pressed(KEY_S):
            iz += 1.0
    var dir = Basis(Vector3.UP, yaw) * Vector3(ix, 0, iz)
    if dir.length() > 1.0:
        dir = dir.normalized()
    sprinting = Input.is_key_pressed(KEY_SHIFT) and dir.length() > 0.1
    var spd = 7.0
    if sprinting:
        spd = 12.0
    in_crater = false
    for c in craters:
        var dx = player.position.x - c["pos"].x
        var dz = player.position.z - c["pos"].z
        if dx * dx + dz * dz < c["r"] * c["r"]:
            in_crater = true
    if in_crater:
        spd *= 0.55
    if carrying != "":
        spd *= 0.85
    var on_floor = player.is_on_floor()
    if on_floor:
        coyote = 0.12
    else:
        coyote = maxf(0.0, coyote - delta)
    var jump_down = Input.is_key_pressed(KEY_SPACE) and quiz == null
    if jump_down and not jump_prev:
        jump_buf = 0.14
    jump_prev = jump_down
    jump_buf = maxf(0.0, jump_buf - delta)
    # smooth acceleration: strong on the ground, floaty in the air (momentum!)
    var accel = 40.0
    if dir.length() < 0.1:
        accel = 32.0
    if not on_floor:
        accel = 9.0
        if dir.length() < 0.1:
            accel = 2.0
    hvel = hvel.move_toward(dir * spd, accel * delta)
    if jump_buf > 0.0 and coyote > 0.0:
        vy = 5.0
        jump_buf = 0.0
        coyote = 0.0
        squash_v = 3.0
        if jump_sfx != null:
            jump_sfx.pitch_scale = randf_range(0.94, 1.06)
            jump_sfx.play()
        puff(player.position, 6, 2.0)
    elif on_floor and vy <= 0.0:
        vy = -1.0
    else:
        # hold SPACE = higher, floatier jump. Tap = short hop. Falling is a bit quicker.
        var g = 10.0
        if vy < 0.0:
            g = 6.5
        elif jump_down:
            g = 4.0
        vy = maxf(vy - g * delta, -25.0)
    fall_v = vy
    player.velocity = Vector3(hvel.x, vy, hvel.z)
    player.move_and_slide()
    vy = player.velocity.y
    var now_floor = player.is_on_floor()
    if now_floor and not was_floor and fall_v < -3.0:
        var impact = clampf(-fall_v / 8.0, 0.2, 1.0)
        squash_v = -6.0 * impact
        shake = impact * 0.25
        puff(player.position, int(6 + impact * 12.0), 2.0 + impact * 3.0)
    was_floor = now_floor
    # turn smoothly toward where we are moving
    turn_amt = 0.0
    var hs = Vector2(hvel.x, hvel.z).length()
    var face = Vector3.ZERO
    if dir.length() > 0.1:
        face = dir
    elif hs > 1.5:
        face = Vector3(hvel.x, 0, hvel.z)
    if face.length() > 0.1:
        var ang = atan2(-face.x, -face.z)
        turn_amt = wrapf(ang - player_mesh.rotation.y, -PI, PI)
        player_mesh.rotation.y = lerp_angle(player_mesh.rotation.y, ang, 12.0 * delta)
    update_anim(dir, delta)
    var flat = Vector2(player.position.x, player.position.z)
    if flat.length() > 340.0:
        var f = 340.0 / flat.length()
        player.position = Vector3(player.position.x * f, player.position.y, player.position.z * f)
        say("You are too far from the base! Turn back.", 3.0)


func _process(delta):
    if intro_instructions:
        intro_time_left -= delta
        if intro_time_left <= 0.0:
            resume()
        return
    if ended or paused:
        return
    t += delta
    if Input.is_key_pressed(KEY_LEFT):
        yaw += 1.8 * delta
    if Input.is_key_pressed(KEY_RIGHT):
        yaw -= 1.8 * delta
    if Input.is_key_pressed(KEY_UP):
        pitch = clampf(pitch + 1.2 * delta, -1.1, 0.15)
    if Input.is_key_pressed(KEY_DOWN):
        pitch = clampf(pitch - 1.2 * delta, -1.1, 0.15)
    pivot.position = player.position + Vector3(0, 1.7, 0)
    pivot.rotation = Vector3(pitch, yaw, 0)
    var fov_goal = 70.0
    var fov_response = 8.0
    if sprinting:
        fov_goal = 102.0
        fov_response = 18.0
    cam.fov = lerpf(cam.fov, fov_goal, clampf(fov_response * delta, 0.0, 1.0))
    if shake > 0.001:
        cam.position = Vector3(randf_range(-1.0, 1.0) * shake, 0.8 + randf_range(-1.0, 1.0) * shake, 6.5)
        shake = maxf(0.0, shake - 0.9 * delta)
    else:
        cam.position = Vector3(0, 0.8, 6.5)
    update_oxygen(delta)
    update_targets(delta)
    if mission == 3:
        update_storm(delta)
    if pending != null:
        pending_t -= delta
        if pending_t <= 0.0:
            finish_mission(pending["score"], pending["detail"])
    update_hud(delta)


func update_oxygen(delta):
    if in_station() or (mission == 3 and in_shelter()):
        oxygen = minf(100.0, oxygen + 25.0 * delta)
        if oxygen > 60.0:
            warned_low = false
        return
    var drain = 0.6
    if sprinting:
        drain *= 1.8
    if in_crater:
        drain *= 2.0
    oxygen -= drain * delta
    if oxygen < 25.0 and not warned_low:
        warned_low = true
        say("OXYGEN LOW! Return to the blue refill circle at the base.", 6.0)
    if oxygen <= 0.0:
        blackout()


func blackout():
    blackouts += 1
    oxygen = 45.0
    player.position = Vector3(0, 0.5, 11)
    hvel = Vector3.ZERO
    vy = 0.0
    warned_low = false
    say("You ran out of oxygen and blacked out! A crewmate dragged you back to base. Always keep a safety margin.", 8.0)


func update_targets(delta):
    var pp = player.position
    var near = null
    var best = 9999.0
    for tg in targets:
        if tg["done"] or not tg["active"]:
            continue
        var dx = pp.x - tg["pos"].x
        var dz = pp.z - tg["pos"].z
        var d = sqrt(dx * dx + dz * dz)
        if d < tg["r"] and absf(pp.y - tg["pos"].y) < 4.0 and d < best:
            best = d
            near = tg
    l_prompt.text = ""
    interact_pill.visible = false
    bar_hold.visible = false
    if near == null or quiz != null:
        hold = 0.0
        last_id = -1
        return
    if near["id"] != last_id:
        hold = 0.0
        last_id = near["id"]
    if near["kind"] == "beacon":
        complete(near)
        return
    var info = interact_info(near)
    l_prompt.text = info["text"]
    interact_pill.visible = info["text"] != ""
    if info["ok"] and Input.is_key_pressed(KEY_E):
        hold += delta / near["hold"]
        bar_hold.visible = true
        bar_hold.value = minf(hold, 1.0) * 100.0
        if hold >= 1.0:
            hold = 0.0
            complete(near)
    else:
        hold = 0.0


func interact_info(tg):
    var k = tg["kind"]
    if k == "ice":
        return {"ok": true, "text": "HOLD  E   •   DRILL FOR ICE"}
    if k == "processor":
        return {"ok": true, "text": "HOLD  E   •   PROCESS ICE"}
    if k == "sensor":
        return {"ok": true, "text": "HOLD  E   •   DEPLOY SENSOR"}
    if k == "crate":
        if carrying != "":
            return {"ok": false, "text": "Your hands are full! Deliver the " + carrying + " first."}
        return {"ok": true, "text": "HOLD  E   •   PICK UP " + tg["data"]["part"].to_upper()}
    if k == "module":
        var need = tg["data"]["need"]
        if carrying == need:
            return {"ok": true, "text": "HOLD  E   •   INSTALL " + need.to_upper()}
        if carrying == "":
            return {"ok": false, "text": tg["data"]["name"] + " needs: " + need + ". Find the crate!"}
        return {"ok": false, "text": "Wrong part! " + tg["data"]["name"] + " needs " + need}
    return {"ok": false, "text": ""}


func complete(tg):
    var k = tg["kind"]
    tg["done"] = true
    if tg["node"] != null:
        tg["node"].visible = false
    if k == "beacon":
        say(TUT_DONE[step], 7.0)
        step += 1
        if step < beacons.size():
            beacons[step]["active"] = true
            beacons[step]["node"].visible = true
        else:
            var sc = 100.0 - blackouts * 20.0 - maxf(0.0, t - 240.0) / 4.0
            schedule_finish(clampf(sc, 40.0, 100.0), "Training time: %d s. Blackouts: %d." % [int(t), blackouts], 4.0)
    elif k == "ice":
        collected += 1
        say(ICE_FACTS[mini(collected - 1, ICE_FACTS.size() - 1)], 10.0)
        if collected >= need_ice:
            processor["active"] = true
    elif k == "processor":
        var sc = 100.0 - blackouts * 15.0 - maxf(0.0, t - 360.0) / 8.0
        say("The ice is melting into clean water. The base has a new supply!", 5.0)
        schedule_finish(clampf(sc, 40.0, 100.0), "Collected %d ice samples in %d s. Blackouts: %d." % [collected, int(t), blackouts], 3.0)
    elif k == "crate":
        carrying = tg["data"]["part"]
        say("Picked up: " + carrying + ". Carry it to the base module that needs it. You walk slower while carrying it.", 7.0)
    elif k == "module":
        carrying = ""
        repaired += 1
        tg["data"]["tag"].text = "REPAIRED"
        tg["data"]["tag"].modulate = Color(0.4, 1.0, 0.5)
        start_quiz(tg["data"]["need"])
    elif k == "sensor":
        sensors += 1
        if sensors < 3:
            say("Sensor deployed! %d of 3. Keep an eye on the storm timer." % sensors, 5.0)
        else:
            say("All 3 sensors are online! Now RUN to the storm shelter dome!", 7.0)


func start_quiz(part):
    var q = QUIZ[part]
    var opts = [q["a"], q["w"][0], q["w"][1]]
    opts.shuffle()
    quiz = {"opts": opts, "right": opts.find(q["a"]), "e": q["e"]}
    l_quiz.text = "REPAIR QUIZ\n\n" + q["q"] + "\n\n1) " + opts[0] + "\n2) " + opts[1] + "\n3) " + opts[2] + "\n\nPress 1, 2 or 3"
    quiz_panel.visible = true
    hvel = Vector3.ZERO


func answer_quiz(i):
    var good = (i == quiz["right"])
    if good:
        say("Correct! " + quiz["e"], 9.0)
    else:
        wrong += 1
        say("Not quite. The answer: " + quiz["opts"][quiz["right"]] + ". " + quiz["e"], 10.0)
    quiz = null
    quiz_panel.visible = false
    if repaired >= 3:
        var sc = 100.0 - wrong * 8.0 - blackouts * 15.0 - maxf(0.0, t - 420.0) / 6.0
        schedule_finish(clampf(sc, 30.0, 100.0), "All 3 modules repaired in %d s. Quiz mistakes: %d. Blackouts: %d." % [int(t), wrong, blackouts], 4.0)


func fmt_time(sec):
    var s = int(maxf(sec, 0.0))
    return "%d:%02d" % [s / 60, s % 60]


func update_storm(delta):
    var left = STORM_AT - t
    if not alerted[0] and t > 4.0:
        alerted[0] = true
        say("SPACE WEATHER ALERT! A huge solar flare erupted. Radiation arrives in 2 minutes. Deploy the 3 sensors, then run to the STORM SHELTER (blue dome).", 12.0)
    if not alerted[1] and left < 45.0 and left > 0.0:
        alerted[1] = true
        say("45 seconds until the radiation storm! Head for the shelter!", 6.0)
    if not alerted[2] and t >= STORM_AT:
        alerted[2] = true
        say("RADIATION STORM! Get inside the shelter dome NOW!", 8.0)
    storm_active = t >= STORM_AT and t < STORM_AT + STORM_LEN
    var inside = in_shelter()
    if storm_active:
        if inside:
            dose += 0.15 * delta
        else:
            dose += 4.0 * delta
        storm_tint.color = Color(1, 0.1, 0.05, 0.1 + 0.05 * sin(t * 6.0))
    else:
        storm_tint.color = Color(1, 0.1, 0.05, 0.0)
    bar_dose.value = minf(dose, 100.0)
    if pending != null:
        return
    if dose >= 100.0:
        var sc1 = minf(30.0, sensors * 10.0)
        schedule_finish(sc1, "Too much radiation! Crewmates carried you to safety. Sensors deployed: %d of 3." % sensors, 3.0)
    elif sensors >= 3 and inside:
        var sc2 = 50.0 + (1.0 - dose / 100.0) * 40.0
        if t < STORM_AT:
            sc2 += 10.0
        say("Safe in the shelter with all sensors online. Great job!", 5.0)
        schedule_finish(sc2, "All 3 sensors deployed. Radiation dose: %d%%. Blackouts: %d." % [int(dose), blackouts], 3.0)
    elif t >= STORM_AT + STORM_LEN:
        var sc3 = sensors / 3.0 * 50.0 + (1.0 - dose / 100.0) * 40.0
        schedule_finish(sc3, "The storm passed. Sensors deployed: %d of 3. Radiation dose: %d%%." % [sensors, int(dose)], 3.0)


func schedule_finish(score, detail, delay):
    if pending != null:
        return
    pending = {"score": score, "detail": detail}
    pending_t = delay


func finish_mission(score, detail):
    if ended:
        return
    ended = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    finished.emit(int(clampf(score, 0.0, 100.0)), detail)


# ------------------------------------------------------------ HUD update
func objective_text():
    if mission == 0:
        return TUT_TEXT[mini(step, TUT_TEXT.size() - 1)]
    if mission == 1:
        if collected < need_ice:
            return "Collect ice samples: %d of %d. Follow the scanner to the blue beacons in dark craters." % [collected, need_ice]
        return "Carry the ice to the WATER PROCESSOR at the base."
    if mission == 2:
        var s = "Repair the base: %d of 3 modules fixed. " % repaired
        if carrying != "":
            s += "Carrying: " + carrying
        else:
            s += "Pick up a supply crate."
        return s
    var s2 = "Deploy radiation sensors: %d of 3. " % sensors
    if t < STORM_AT:
        s2 += "STORM ARRIVES IN " + fmt_time(STORM_AT - t)
    elif storm_active:
        s2 += "STORM! Shelter in the dome! (%d s left)" % int(STORM_AT + STORM_LEN - t)
    else:
        s2 += "The storm is over."
    return s2


func goal_pos():
    if mission == 0:
        if step < beacons.size():
            return beacons[step]["pos"]
        return null
    var best = null
    var bd = 99999.0
    if mission == 1:
        for tg in targets:
            if tg["active"] and not tg["done"]:
                var d = player.position.distance_to(tg["pos"])
                if d < bd:
                    bd = d
                    best = tg["pos"]
        return best
    if mission == 2:
        if carrying != "":
            for tg in targets:
                if tg["kind"] == "module" and tg["data"]["need"] == carrying:
                    return tg["pos"]
        for tg in targets:
            if tg["kind"] == "crate" and not tg["done"] and carrying == "":
                var d2 = player.position.distance_to(tg["pos"])
                if d2 < bd:
                    bd = d2
                    best = tg["pos"]
        return best
    for tg in targets:
        if tg["kind"] == "sensor" and not tg["done"]:
            var d3 = player.position.distance_to(tg["pos"])
            if d3 < bd:
                bd = d3
                best = tg["pos"]
    if best == null:
        return SHELTER
    return best


func update_hud(delta):
    l_title.text = "MISSION %d: %s" % [mission + 1, NAMES[mission]]
    l_obj.text = objective_text()
    bar_o2.value = oxygen
    l_o2.text = "OXYGEN %d%%" % int(oxygen)
    if oxygen < 25.0:
        l_o2.add_theme_color_override("font_color", Color(1, 0.4, 0.3))
    else:
        l_o2.add_theme_color_override("font_color", Color(0.6, 0.9, 1))
    if msg_t > 0.0:
        msg_t -= delta
        if msg_t <= 0.0:
            l_msg.text = ""
    var g = goal_pos()
    if g == null:
        arrow.visible = false
    else:
        arrow.visible = true
        var dx = g.x - player.position.x
        var dz = g.z - player.position.z
        arrow.angle = yaw - atan2(-dx, -dz)
        arrow.label_text = "%d m" % int(sqrt(dx * dx + dz * dz))
        arrow.queue_redraw()
