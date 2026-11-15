extends Control
## Little compass arrow that points to the current goal.

var angle = 0.0
var label_text = ""


func _draw():
    var c = size / 2.0
    draw_circle(c, 50.0, Color(0, 0.05, 0.15, 0.6))
    draw_arc(c, 50.0, 0.0, TAU, 32, Color(0.5, 0.8, 1.0), 2.0)
    var d = Vector2(sin(angle), -cos(angle))
    var perp = Vector2(-d.y, d.x)
    var pts = PackedVector2Array([c + d * 38.0, c - d * 18.0 + perp * 16.0, c - d * 6.0, c - d * 18.0 - perp * 16.0])
    draw_colored_polygon(pts, Color(1.0, 0.85, 0.3))
    draw_string(ThemeDB.fallback_font, Vector2(0, size.y + 20), label_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color.WHITE)
