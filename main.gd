extends Control
## Moon Base Rescue 3D - menus, briefings, scoring and certificate.

const MISSIONS = [
    {"title": "Moonwalk Training",
     "brief": "Welcome to Moon Base Alpha! Before any real work, a trainee must learn to move in a spacesuit on the Moon. Follow the scanner arrow to the green beacons: walk, climb a hill, sprint, and refill your oxygen at the base. Everything you do uses oxygen, so watch the bar!",
     "skills": "Low gravity, suit oxygen, and navigating with a scanner.",
     "controls": "W A S D = move.  Mouse = look.  SPACE = jump (hold for a higher jump).  SHIFT = sprint.  E (hold) = interact.  ESC = pause.",
     "time": "about 3 minutes",
     "lesson": "Moon gravity is only about one-sixth of Earth's. Apollo astronauts in their heavy suits often found that bounding along was easier than walking."},
    {"title": "Find the Water Ice",
     "brief": "The base needs water! Scientists believe ice hides in permanently dark craters near the Moon's poles. Follow the scanner to seven blue beacons, drill out an ice sample at each one, then carry everything back to the water processor. Dusty craters slow you down and use more oxygen.",
     "skills": "Where water on the Moon comes from and why it matters.",
     "controls": "Hold E near a beacon to drill. Return to the blue circle at the base to refill oxygen.",
     "time": "about 6 minutes",
     "lesson": "Scientists think there is water ice in dark craters near the Moon's poles. NASA's Artemis program plans to land astronauts near the south pole to study it."},
    {"title": "Repair the Base",
     "brief": "A meteoroid shower damaged three modules: the solar array, the oxygen generator and the antenna. Find the matching supply crates out on the surface and carry them back, one part at a time. After each repair, Mission Control will ask you a quick question.",
     "skills": "How a base's power, air and communications systems work together.",
     "controls": "Hold E at a crate to pick up a part. Hold E at the right module to install it. Press 1, 2 or 3 to answer questions.",
     "time": "about 6 minutes",
     "lesson": "Every part of a base depends on the others: power runs the air generator, air keeps the crew alive, and the antenna keeps them connected to home."},
    {"title": "Solar Storm Run",
     "brief": "Space weather forecasters have spotted a huge solar flare! In two minutes a radiation storm will hit the Moon. Deploy three radiation sensors on the surface, then race back to the storm shelter dome. Crew outside the shelter take radiation quickly, but the shelter protects you well.",
     "skills": "Space weather, radiation safety, and deciding under time pressure.",
     "controls": "Hold E at orange beacons to deploy sensors. Run into the blue shelter dome before the storm timer ends. SHIFT sprints, but costs oxygen!",
     "time": "about 4 minutes",
     "lesson": "Space weather forecasters watch the Sun to warn crews. Away from Earth's magnetic field, astronauts need shielded shelters when a big solar storm arrives."}
]

var scores = []
var cur = 0
var callsign = "Cadet"
var screen = null
var game = null
var stars = []
var clock = 0.0
var deco = true
var in_game = false
var title_astronaut = false
var ui_font = null
var lobby_music: AudioStreamPlayer


func _ready():
    lobby_music = AudioStreamPlayer.new()
    lobby_music.name = "LobbyMusic"
    lobby_music.stream = load("res://audio/lobby_space_loop.wav")
    lobby_music.volume_db = -4.0
    lobby_music.finished.connect(_on_lobby_music_finished)
    add_child(lobby_music)
    lobby_music.play()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(1280, 720)
    var rng = RandomNumberGenerator.new()
    rng.seed = 42
    for i in range(170):
        stars.append([Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720)), rng.randf_range(0.6, 2.0), rng.randf_range(0.4, 1.0)])
    for i in range(MISSIONS.size()):
        scores.append(-1)
    ui_font = SystemFont.new()
    ui_font.font_names = PackedStringArray(["Showcard Gothic", "Orbitron", "Eurostile", "Bank Gothic", "Rajdhani", "Arial"])
    show_title()


func _on_lobby_music_finished():
    if is_instance_valid(lobby_music) and not in_game:
        lobby_music.play()


func _process(delta):
    clock += delta
    if not in_game:
        queue_redraw()


func _draw():
    if in_game:
        return
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.03, 0.09))
    for s in stars:
        var a = s[2] * (0.65 + 0.35 * sin(clock * s[1] * 1.5 + s[0].x))
        draw_circle(s[0], s[1], Color(1, 1, 1, a))
    if deco and title_astronaut:
        # Deep-space lobby: distant lunar horizon, orbital rings and a softly glowing planet.
        draw_circle(Vector2(1080, 620), 300.0, Color(0.07, 0.11, 0.22, 0.96))
        draw_circle(Vector2(1040, 604), 250.0, Color(0.20, 0.25, 0.36, 0.98))
        draw_arc(Vector2(930, 340), 248.0, -0.8, 2.75, 120, Color(0.32, 0.72, 1.0, 0.52), 3.0)
        draw_arc(Vector2(930, 340), 270.0, 2.9, 5.65, 120, Color(0.62, 0.82, 1.0, 0.24), 2.0)
        draw_circle(Vector2(250, 540), 118.0, Color(0.18, 0.38, 0.72, 0.08))
        draw_circle(Vector2(930, 340), 220.0, Color(0.16, 0.40, 0.86, 0.10))
        draw_circle(Vector2(930, 340), 170.0, Color(0.30, 0.62, 1.0, 0.08))
        var bob = sin(clock * 1.25) * 14.0
        var a = Vector2(930, 326 + bob)
        # A thin tether/orbit trail makes the character feel weightless.
        draw_line(Vector2(770, 520), Vector2(1100, 150), Color(0.48, 0.76, 1.0, 0.18), 2.0)
        draw_set_transform(a, -0.20 + sin(clock * 0.7) * 0.035, Vector2.ONE)
        # Backpack and padded arms/legs, with dark suit seams.
        draw_rect(Rect2(-102, -48, 52, 116), Color(0.38, 0.48, 0.62))
        draw_circle(Vector2(-76, -48), 25.0, Color(0.38, 0.48, 0.62))
        draw_circle(Vector2(-76, 68), 25.0, Color(0.38, 0.48, 0.62))
        draw_rect(Rect2(-108, -42, 44, 104), Color(0.78, 0.83, 0.91))
        draw_circle(Vector2(-86, -42), 21.0, Color(0.78, 0.83, 0.91))
        draw_circle(Vector2(-86, 62), 21.0, Color(0.78, 0.83, 0.91))
        draw_line(Vector2(-48, 30), Vector2(-116, 76), Color(0.12, 0.18, 0.28), 31.0)
        draw_line(Vector2(-48, 30), Vector2(-116, 76), Color(0.88, 0.91, 0.97), 25.0)
        draw_line(Vector2(48, 30), Vector2(112, 72), Color(0.12, 0.18, 0.28), 31.0)
        draw_line(Vector2(48, 30), Vector2(112, 72), Color(0.88, 0.91, 0.97), 25.0)
        draw_line(Vector2(-30, 105), Vector2(-68, 172), Color(0.12, 0.18, 0.28), 34.0)
        draw_line(Vector2(-30, 105), Vector2(-68, 172), Color(0.86, 0.90, 0.97), 27.0)
        draw_line(Vector2(30, 105), Vector2(76, 164), Color(0.12, 0.18, 0.28), 34.0)
        draw_line(Vector2(30, 105), Vector2(76, 164), Color(0.86, 0.90, 0.97), 27.0)
        # Rounded suit body and helmet.
        draw_circle(Vector2(0, 42), 83.0, Color(0.12, 0.18, 0.29))
        draw_circle(Vector2(0, 38), 76.0, Color(0.91, 0.93, 0.97))
        draw_circle(Vector2(0, -83), 68.0, Color(0.12, 0.18, 0.29))
        draw_circle(Vector2(0, -87), 61.0, Color(0.94, 0.96, 1.0))
        draw_circle(Vector2(9, -91), 46.0, Color(0.035, 0.10, 0.20))
        draw_arc(Vector2(9, -91), 46.0, 3.55, 5.45, 36, Color(0.40, 0.78, 1.0, 0.9), 5.0)
        draw_circle(Vector2(27, -108), 13.0, Color(0.43, 0.77, 1.0, 0.75))
        draw_circle(Vector2(-10, -72), 7.0, Color(0.76, 0.90, 1.0, 0.7))
        draw_rect(Rect2(-24, 18, 48, 42), Color(0.95, 0.58, 0.18))
        draw_circle(Vector2(-24, 39), 10.0, Color(0.95, 0.58, 0.18))
        draw_circle(Vector2(24, 39), 10.0, Color(0.95, 0.58, 0.18))
        draw_rect(Rect2(-9, 25, 18, 7), Color(1.0, 0.84, 0.53))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func mk(parent, text, pos, fsize = 20, color = Color.WHITE, width = 0):
    var l = Label.new()
    l.text = text
    l.position = pos
    l.add_theme_font_size_override("font_size", fsize)
    if ui_font != null:
        l.add_theme_font_override("font", ui_font)
    l.add_theme_color_override("font_color", color)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if width > 0:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(width, 0)
        l.size = Vector2(width, 0)
    parent.add_child(l)
    return l


func mkb(parent, text, pos, sz, callable, fsize = 22):
    var b = Button.new()
    b.text = text
    b.position = pos
    b.size = sz
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", fsize)
    if ui_font != null:
        b.add_theme_font_override("font", ui_font)
    var normal = StyleBoxFlat.new()
    normal.bg_color = Color(0.84, 0.91, 1.0, 0.92)
    normal.corner_radius_top_left = 36
    normal.corner_radius_top_right = 36
    normal.corner_radius_bottom_left = 36
    normal.corner_radius_bottom_right = 36
    normal.content_margin_left = 20
    normal.content_margin_right = 20
    normal.shadow_color = Color(0.15, 0.35, 0.65, 0.35)
    normal.shadow_size = 10
    normal.shadow_offset = Vector2(0, 5)
    var hover = normal.duplicate()
    hover.bg_color = Color(0.97, 0.985, 1.0)
    var pressed = normal.duplicate()
    pressed.bg_color = Color(0.68, 0.82, 0.99)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_color_override("font_color", Color(0.07, 0.15, 0.28))
    b.add_theme_color_override("font_hover_color", Color(0.03, 0.1, 0.2))
    b.add_theme_color_override("font_pressed_color", Color(0.03, 0.1, 0.2))
    b.pressed.connect(callable)
    parent.add_child(b)
    return b


func new_screen():
    var c = Control.new()
    c.size = Vector2(1280, 720)
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return c


func set_screen(node):
    if screen != null:
        screen.queue_free()
    screen = node
    add_child(node)


func clear_game():
    if game != null:
        game.queue_free()
        game = null
    in_game = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_title():
    clear_game()
    if lobby_music != null and not lobby_music.playing:
        lobby_music.play()
    deco = true
    title_astronaut = true
    var c = new_screen()
    mk(c, "MOON BASE", Vector2(70, 78), 68, Color(1, 0.84, 0.43))
    mk(c, "RESCUE 3D", Vector2(70, 150), 68, Color(0.94, 0.97, 1.0))
    mk(c, "MISSION CONTROL  //  LUNAR OPERATIONS", Vector2(76, 238), 18, Color(0.63, 0.81, 1.0))
    mk(c, "Explore the Moon. Complete your objectives. Bring the crew home.", Vector2(76, 274), 18, Color(0.76, 0.85, 0.98))
    mk(c, "CALLSIGN", Vector2(76, 344), 16, Color(0.7, 0.82, 1.0))
    var le = LineEdit.new()
    le.text = callsign
    le.max_length = 16
    le.position = Vector2(76, 372)
    le.size = Vector2(300, 46)
    le.add_theme_font_size_override("font_size", 20)
    if ui_font != null:
        le.add_theme_font_override("font", ui_font)
    var entry_style = StyleBoxFlat.new()
    entry_style.bg_color = Color(0.1, 0.17, 0.3, 0.9)
    entry_style.corner_radius_top_left = 18
    entry_style.corner_radius_top_right = 18
    entry_style.corner_radius_bottom_left = 18
    entry_style.corner_radius_bottom_right = 18
    entry_style.border_color = Color(0.45, 0.67, 0.95, 0.7)
    entry_style.set_border_width_all(1)
    le.add_theme_stylebox_override("normal", entry_style)
    le.text_changed.connect(_on_name)
    c.add_child(le)
    mkb(c, "BEGIN MISSION", Vector2(76, 452), Vector2(300, 62), _start_game, 23)
    mkb(c, "MISSION SELECT", Vector2(76, 530), Vector2(300, 54), _show_select, 20)
    mkb(c, "QUIT", Vector2(76, 600), Vector2(130, 46), _quit, 17)
    mk(c, "Independent learning project • Not an official NASA product", Vector2(76, 674), 13, Color(0.52, 0.63, 0.79))
    set_screen(c)


func _on_name(t):
    callsign = t.strip_edges()
    if callsign == "":
        callsign = "Cadet"


func _quit():
    get_tree().quit()


func _start_game():
    if lobby_music != null:
        lobby_music.stop()
    show_briefing(0)


func _show_select():
    deco = false
    title_astronaut = false
    var c = new_screen()
    mk(c, "MISSION SELECT", Vector2(60, 40), 42, Color(1, 0.85, 0.4))
    for i in range(MISSIONS.size()):
        var best = "not played yet"
        if scores[i] >= 0:
            best = "best score: %d" % scores[i]
        mkb(c, "Mission %d: %s   (%s)" % [i + 1, MISSIONS[i]["title"], best], Vector2(60, 130 + i * 100), Vector2(760, 80), _open_brief.bind(i), 24)
    mkb(c, "BACK", Vector2(60, 560), Vector2(160, 52), show_title, 22)
    set_screen(c)


func _open_brief(i):
    show_briefing(i)


func show_briefing(i):
    clear_game()
    title_astronaut = false
    cur = i
    deco = false
    var m = MISSIONS[i]
    var c = new_screen()
    mk(c, "MISSION %d OF %d" % [i + 1, MISSIONS.size()], Vector2(70, 50), 24, Color(0.7, 0.85, 1))
    mk(c, m["title"].to_upper(), Vector2(70, 90), 56, Color(1, 0.85, 0.4))
    mk(c, "Briefing from Mission Control", Vector2(70, 175), 20, Color(0.6, 1, 0.8))
    mk(c, m["brief"], Vector2(70, 210), 24, Color.WHITE, 1080)
    mk(c, "You will learn: " + m["skills"], Vector2(70, 420), 22, Color(1, 0.9, 0.6), 1080)
    mk(c, "Controls: " + m["controls"], Vector2(70, 480), 21, Color(0.7, 0.9, 1), 1080)
    mk(c, "Time: " + m["time"], Vector2(70, 560), 20, Color(0.7, 0.85, 1))
    mkb(c, "BEGIN MISSION", Vector2(70, 610), Vector2(300, 64), _begin, 26)
    mkb(c, "MENU", Vector2(400, 618), Vector2(130, 50), show_title, 20)
    set_screen(c)


func _begin():
    start_mission(cur)


func start_mission(i):
    cur = i
    if screen != null:
        screen.queue_free()
        screen = null
    var g = Node3D.new()
    g.set_script(load("res://game3d.gd"))
    g.mission = i
    g.finished.connect(_on_done)
    g.quit_requested.connect(show_title)
    in_game = true
    game = g
    add_child(g)


func _on_done(score, detail):
    if score > scores[cur]:
        scores[cur] = score
    clear_game()
    show_debrief(score, detail)


func show_debrief(score, detail):
    deco = false
    title_astronaut = false
    var c = new_screen()
    mk(c, "MISSION DEBRIEF", Vector2(70, 40), 36, Color(0.7, 0.85, 1))
    mk(c, "Score: %d / 100" % score, Vector2(70, 120), 48, Color(1, 0.85, 0.4))
    var verdict = "Good start! Try again to improve your score."
    var stars_txt = "Stars: 1 of 3"
    if score >= 85:
        verdict = "Outstanding work, " + callsign + "!"
        stars_txt = "Stars: 3 of 3"
    elif score >= 60:
        verdict = "Nice job, " + callsign + "! You passed."
        stars_txt = "Stars: 2 of 3"
    mk(c, stars_txt, Vector2(70, 190), 26, Color(1, 0.9, 0.3))
    mk(c, verdict, Vector2(70, 250), 26, Color(0.6, 1, 0.8), 1100)
    mk(c, detail, Vector2(70, 300), 22, Color.WHITE, 1100)
    mk(c, "DID YOU KNOW?", Vector2(70, 400), 20, Color(1, 0.85, 0.4))
    mk(c, MISSIONS[cur]["lesson"], Vector2(70, 430), 22, Color(0.85, 0.92, 1), 1100)
    var label_next = "NEXT MISSION"
    if cur >= MISSIONS.size() - 1:
        label_next = "FINAL REPORT"
    mkb(c, label_next, Vector2(70, 600), Vector2(300, 60), _next_mission, 24)
    mkb(c, "TRY AGAIN", Vector2(400, 600), Vector2(220, 60), _begin, 22)
    mkb(c, "MENU", Vector2(650, 600), Vector2(140, 60), show_title, 20)
    set_screen(c)


func _next_mission():
    if cur >= MISSIONS.size() - 1:
        show_final()
    else:
        show_briefing(cur + 1)


func show_final():
    deco = true
    title_astronaut = false
    var total = 0.0
    for s in scores:
        if s >= 0:
            total += s
    var avg = int(total / MISSIONS.size())
    var rank = "Astronaut Candidate"
    if avg >= 90:
        rank = "Mission Commander"
    elif avg >= 75:
        rank = "Mission Specialist"
    elif avg >= 55:
        rank = "Junior Astronaut"
    var c = new_screen()
    mk(c, "CERTIFICATE OF COMPLETION", Vector2(70, 50), 44, Color(1, 0.85, 0.4))
    mk(c, "This certifies that", Vector2(70, 120), 22, Color(0.8, 0.9, 1))
    mk(c, callsign.to_upper(), Vector2(70, 150), 54, Color.WHITE)
    mk(c, "has completed Moon Base Rescue 3D training", Vector2(70, 225), 22, Color(0.8, 0.9, 1))
    mk(c, "Rank earned: " + rank, Vector2(70, 270), 36, Color(0.6, 1, 0.8))
    mk(c, "Overall score: %d / 100" % avg, Vector2(70, 320), 28, Color(1, 0.85, 0.4))
    for i in range(MISSIONS.size()):
        var s = "not played"
        if scores[i] >= 0:
            s = str(scores[i])
        mk(c, "%d. %s: %s" % [i + 1, MISSIONS[i]["title"], s], Vector2(70, 385 + i * 34), 21)
    mk(c, "You learned about low gravity, water on the Moon, how a base works, and radiation safety.", Vector2(70, 540), 20, Color(0.85, 0.92, 1), 900)
    mkb(c, "PLAY AGAIN", Vector2(70, 620), Vector2(240, 58), _play_again, 22)
    mkb(c, "MENU", Vector2(330, 620), Vector2(140, 58), show_title, 22)
    set_screen(c)


func _play_again():
    for i in range(scores.size()):
        scores[i] = -1
    show_briefing(0)
