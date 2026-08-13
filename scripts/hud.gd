extends CanvasLayer
class_name SpiderHUD

var objective_label: Label
var stats_label: Label
var alert_label: Label
var swing_label: Label
var mission_bar: ProgressBar
var message_time := 0.0


func _ready() -> void:
	layer = 20
	_build_ui()


func _panel(parent: Control, position: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.18, 0.44, 0.72, 0.65)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_left := _panel(root, Vector2(28, 24), Vector2(405, 104), Color(0.015, 0.025, 0.07, 0.84))
	_label(top_left, "SPIDER-VERSE", Vector2(18, 12), Vector2(370, 30), 24, Color(0.98, 0.98, 1.0))
	_label(top_left, "MIDTOWN AFTER DARK  //  TRAVERSAL LAB", Vector2(19, 46), Vector2(370, 22), 11, Color(0.36, 0.73, 1.0))
	objective_label = _label(top_left, "OBJECTIVE  //  Reach the beacon", Vector2(19, 72), Vector2(370, 22), 12, Color(0.9, 0.93, 1.0))

	var top_right := _panel(root, Vector2(1492, 24), Vector2(400, 118), Color(0.015, 0.025, 0.07, 0.84))
	stats_label = _label(top_right, "HEALTH  100     COMBO  x0     XP  0000", Vector2(18, 14), Vector2(365, 26), 14, Color(0.95, 0.97, 1.0))
	mission_bar = ProgressBar.new()
	mission_bar.position = Vector2(18, 54)
	mission_bar.size = Vector2(365, 10)
	mission_bar.max_value = 1.0
	mission_bar.value = 0.0
	mission_bar.show_percentage = false
	top_right.add_child(mission_bar)
	_label(top_right, "CITY THREAT  //  HUNTER DRONES ACTIVE", Vector2(18, 78), Vector2(365, 24), 11, Color(1.0, 0.27, 0.32))

	var center := Control.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_label(center, "+", Vector2(-12, -22), Vector2(24, 44), 30, Color(0.8, 0.94, 1.0, 0.9)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	swing_label = _label(root, "", Vector2(28, 154), Vector2(420, 30), 13, Color(0.45, 0.82, 1.0))
	alert_label = _label(root, "", Vector2(0, 172), Vector2(1920, 40), 18, Color(1.0, 0.82, 0.35))
	alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var controls := _panel(root, Vector2(28, 930), Vector2(600, 94), Color(0.015, 0.025, 0.07, 0.78))
	_label(controls, "WASD  MOVE     SHIFT  SPRINT     SPACE  JUMP / WALL-JUMP", Vector2(18, 13), Vector2(560, 22), 11, Color(0.74, 0.82, 0.94))
	_label(controls, "F / LMB  WEB     Z / X  REEL     Q / RMB  STRIKE     ESC  RELEASE MOUSE", Vector2(18, 44), Vector2(560, 22), 11, Color(0.45, 0.75, 1.0))


func update_state(health: int, combo: int, xp: int, objective: String, progress: float, drones: int, shards: int, swinging: bool, model_loaded: bool) -> void:
	if stats_label != null:
		stats_label.text = "HEALTH  %03d     COMBO  x%d     XP  %04d" % [health, combo, xp]
	if objective_label != null:
		objective_label.text = "OBJECTIVE  //  " + objective
	if mission_bar != null:
		mission_bar.value = clampf(progress, 0.0, 1.0)
	if swing_label != null:
		swing_label.text = "WEB LINK  //  TETHERED" if swinging else "WEB LINK  //  READY"
	if alert_label != null and message_time <= 0.0:
		alert_label.text = "%d HUNTER DRONES  //  %d DATA SHARDS" % [drones, shards]
	if not model_loaded and alert_label != null and message_time <= 0.0:
		alert_label.text = "SUIT IMPORT UNAVAILABLE  //  TRAINING SILHOUETTE ACTIVE"


func flash_message(message: String) -> void:
	if alert_label == null:
		return
	alert_label.text = message
	message_time = 3.0


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time = maxf(message_time - delta, 0.0)