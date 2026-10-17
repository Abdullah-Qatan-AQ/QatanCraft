extends Control

const SAVE_PATH := "user://qatancraft_world.json"
const WORLD_RADIUS := 9
const MAX_BUILD_HEIGHT := 7
const BLOCK_SIZE := 1.0
const PLAYER_SPEED := 4.5
const BLOCK_COLORS := {
	"grass": Color("#6fbf73"), "dirt": Color("#9b6b43"), "stone": Color("#8a96a3"),
	"wood": Color("#bd7c45"), "leaves": Color("#4d9d65"), "sand": Color("#d8bd73"),
	"water": Color("#4a9fd4"), "coal": Color("#252b35")
}
const BLOCK_LABELS := {"grass":"عشب", "dirt":"تراب", "stone":"حجر", "wood":"خشب", "leaves":"أوراق", "sand":"رمل", "coal":"فحم"}

var _blocks: Dictionary = {}
var _block_nodes: Dictionary = {}
var _player: Node3D
var _camera: Camera3D
var _world_root: Node3D
var _selected_block := "grass"
var _inventory := {"grass": 24, "dirt": 16, "stone": 10, "wood": 8, "sand": 12}
var _title_screen: Control
var _game_ui: Control
var _toast: Label
var _inventory_label: Label
var _coords_label: Label
var _save_label: Label
var _touch_layer: Control
var _moving := Vector2.ZERO
var _move_target := Vector3.ZERO
var _moving_now := false
var _last_move := 0.0
var _toast_tween: Tween
var _day_time := 0.2
var _world_seed := 7331

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#13263a"))
	_build_environment()
	_build_title()
	_load_world()
	_build_audio()

func _build_environment() -> void:
	_world_root = Node3D.new()
	_world_root.name = "VoxelWorld"
	add_child(_world_root)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	sun.light_color = Color("#ffe7ba")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5c9fc5")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b6d9ed")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)
	_camera = Camera3D.new()
	_camera.current = true
	_camera.fov = 58.0
	add_child(_camera)

func _build_title() -> void:
	_title_screen = Control.new()
	_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_title_screen)
	var shade := ColorRect.new()
	shade.color = Color("#0b1422cc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title_screen.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(70, 90)
	panel.size = Vector2(580, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#12263ae8")
	style.border_color = Color("#75d8c0")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color("#06101acc")
	style.shadow_size = 24
	panel.add_theme_stylebox_override("panel", style)
	_title_screen.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var eyebrow := _label("عالمك. قواعدك.", 20, Color("#75d8c0"))
	box.add_child(eyebrow)
	var title := _label("QATANCRAFT", 52, Color("#f4e2b7"))
	title.add_theme_color_override("font_shadow_color", Color("#00000088"))
	title.add_theme_constant_override("shadow_offset_y", 5)
	box.add_child(title)
	var author := _label("Abdullah Qatan", 25, Color("#ffffff"))
	box.add_child(author)
	box.add_child(_label("استكشف • اجمع • ابنِ • اصنع", 18, Color("#a9c7d4")))
	box.add_child(Control.new())
	var start := Button.new()
	start.text = "ابدأ المغامرة"
	start.custom_minimum_size = Vector2(360, 66)
	start.add_theme_font_size_override("font_size", 26)
	start.add_theme_color_override("font_color", Color("#0d2230"))
	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color("#75d8c0")
	start_style.corner_radius_top_left = 18; start_style.corner_radius_top_right = 18
	start_style.corner_radius_bottom_left = 18; start_style.corner_radius_bottom_right = 18
	start.add_theme_stylebox_override("normal", start_style)
	start.pressed.connect(_start_game)
	box.add_child(start)
	box.add_child(_label("لعبة جوال أصلية — تحفظ عالمك تلقائيًا", 15, Color("#83a5b4")))

func _start_game() -> void:
	_title_screen.hide()
	_build_player()
	_build_world()
	_build_game_ui()
	_show_toast("مرحبًا بك في QatanCraft — ابنِ عالمك!")
	AudioDirector.unlock_audio()
	AudioDirector.play_cue("ui.confirm")

func _build_player() -> void:
	_player = Node3D.new()
	_player.name = "Player"
	_player.position = Vector3(0.0, 2.2, 0.0)
	add_child(_player)
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = Vector3(0.7, 1.0, 0.7)
	body.mesh = mesh; body.material_override = _material(Color("#f0c27b"))
	_player.add_child(body)
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new(); cap_mesh.size = Vector3(0.78, 0.28, 0.78)
	cap.mesh = cap_mesh; cap.position.y = 0.55; cap.material_override = _material(Color("#2a6670"))
	_player.add_child(cap)

func _build_world() -> void:
	if not _blocks.is_empty():
		for pos in _blocks.keys(): _create_block(Vector3i(pos))
		return
	for x in range(-WORLD_RADIUS, WORLD_RADIUS + 1):
		for z in range(-WORLD_RADIUS, WORLD_RADIUS + 1):
			var h := 1 + int(abs(sin(float(x * 2 + z) * 0.38)) * 2.0)
			for y in range(h): _set_block(Vector3i(x, y, z), "grass" if y == h - 1 else "dirt", true)
			if (x * 13 + z * 7 + _world_seed) % 31 == 0 and abs(x) > 2 and abs(z) > 2:
				_build_tree(Vector3i(x, h, z))
	for x in range(-3, 4):
		for z in range(-2, 3):
			_set_block(Vector3i(x, 0, z), "sand", true)
	_save_world()

func _build_tree(base: Vector3i) -> void:
	for y in range(3): _set_block(base + Vector3i(0, y, 0), "wood", true)
	for x in range(-2, 3):
		for z in range(-2, 3):
			for y in range(2, 4):
				if abs(x) + abs(z) + y < 6: _set_block(base + Vector3i(x, y, z), "leaves", true)

func _set_block(pos: Vector3i, kind: String, silent := false) -> void:
	_blocks[pos] = kind
	_create_block(pos)
	if not silent: _save_world()

func _create_block(pos: Vector3i) -> void:
	if _block_nodes.has(pos): return
	var block := StaticBody3D.new()
	block.position = Vector3(pos) + Vector3(0.5, 0.5, 0.5)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new(); box.size = Vector3.ONE * 0.98
	mesh.mesh = box
	mesh.material_override = _material(BLOCK_COLORS.get(str(_blocks[pos]), Color.WHITE))
	block.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = Vector3.ONE
	collision.shape = shape; block.add_child(collision)
	_world_root.add_child(block); _block_nodes[pos] = block

func _remove_block(pos: Vector3i) -> void:
	if not _blocks.has(pos) or pos.y <= 0: return
	_blocks.erase(pos)
	if _block_nodes.has(pos): _block_nodes[pos].queue_free(); _block_nodes.erase(pos)
	_save_world()

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player): return
	_day_time = fmod(_day_time + delta * 0.004, 1.0)
	_update_player(delta)
	_update_camera(delta)
	_update_hud()

func _update_player(delta: float) -> void:
	var dir := Vector3(_moving.x, 0.0, _moving.y)
	if dir.length() > 0.1:
		dir = dir.normalized(); _player.position += dir * PLAYER_SPEED * delta
		_player.position.x = clampf(_player.position.x, -WORLD_RADIUS + 0.6, WORLD_RADIUS - 0.6)
		_player.position.z = clampf(_player.position.z, -WORLD_RADIUS + 0.6, WORLD_RADIUS - 0.6)
		_player.position.y = _ground_y(_player.position) + 1.25
		_last_move = Time.get_ticks_msec() / 1000.0

func _update_camera(delta: float) -> void:
	var target := _player.position + Vector3(0, 0.8, 0)
	var desired := target + Vector3(9.0, 8.5, 10.0)
	_camera.position = _camera.position.lerp(desired, minf(delta * 5.0, 1.0))
	_camera.look_at(target, Vector3.UP)

func _ground_y(p: Vector3) -> float:
	var best := 1.0
	for pos in _blocks.keys():
		var v := Vector3i(pos)
		if absf(float(v.x) + 0.5 - p.x) < 0.6 and absf(float(v.z) + 0.5 - p.z) < 0.6:
			best = maxf(best, float(v.y) + 1.0)
	return best

func _build_game_ui() -> void:
	_game_ui = Control.new(); _game_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _game_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_game_ui)
	var top := PanelContainer.new(); top.position = Vector2(18, 18); top.size = Vector2(590, 84); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new(); st.bg_color = Color("#102436cc"); st.corner_radius_top_left = 18; st.corner_radius_top_right = 18; st.corner_radius_bottom_left = 18; st.corner_radius_bottom_right = 18; top.add_theme_stylebox_override("panel", st)
	_game_ui.add_child(top)
	var top_box := VBoxContainer.new(); top_box.add_theme_constant_override("separation", 1); top.add_child(top_box)
	_coords_label = _label("", 20, Color("#f4e2b7")); top_box.add_child(_coords_label)
	_inventory_label = _label("", 16, Color("#a9d8d0")); top_box.add_child(_inventory_label)
	_save_label = _label("حفظ تلقائي", 13, Color("#83a5b4")); top_box.add_child(_save_label)
	_toast = _label("", 22, Color("#ffffff")); _toast.position = Vector2(175, 120); _toast.size = Vector2(420, 60); _toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _game_ui.add_child(_toast)
	_touch_layer = Control.new(); _touch_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE; _game_ui.add_child(_touch_layer)
	_make_touch_button("▲", Vector2(92, 610), Vector2(72, 62), Vector2(0, -1))
	_make_touch_button("◀", Vector2(16, 678), Vector2(72, 62), Vector2(-1, 0))
	_make_touch_button("▼", Vector2(92, 678), Vector2(72, 62), Vector2(0, 1))
	_make_touch_button("▶", Vector2(168, 678), Vector2(72, 62), Vector2(1, 0))
	var action := Button.new(); action.text = "كسر"; action.position = Vector2(525, 620); action.size = Vector2(115, 62); action.add_theme_font_size_override("font_size", 22); action.pressed.connect(_break_front); _style_button(action, Color("#e28a66")); _game_ui.add_child(action)
	var place := Button.new(); place.text = "بناء"; place.position = Vector2(525, 692); place.size = Vector2(115, 62); place.add_theme_font_size_override("font_size", 22); place.pressed.connect(_place_front); _style_button(place, Color("#75d8c0")); _game_ui.add_child(place)
	var cycle := Button.new(); cycle.text = "المادة: عشب"; cycle.position = Vector2(250, 692); cycle.size = Vector2(250, 62); cycle.add_theme_font_size_override("font_size", 18); cycle.pressed.connect(_cycle_block); _style_button(cycle, Color("#536b7d")); _game_ui.add_child(cycle)

func _make_touch_button(text: String, pos: Vector2, size: Vector2, dir: Vector2) -> void:
	var b := Button.new(); b.text = text; b.position = pos; b.size = size; b.add_theme_font_size_override("font_size", 28); _style_button(b, Color("#294b60")); b.button_down.connect(func(): _moving = dir); b.button_up.connect(func(): _moving = Vector2.ZERO); _game_ui.add_child(b)

func _style_button(button: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new(); normal.bg_color = Color(color, 0.92); normal.corner_radius_top_left = 16; normal.corner_radius_top_right = 16; normal.corner_radius_bottom_left = 16; normal.corner_radius_bottom_right = 16; normal.border_color = Color("#ffffff44"); normal.set_border_width_all(1); button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("pressed", normal)

func _break_front() -> void:
	var p := _target_block()
	if p == Vector3i(999, 999, 999): _show_toast("لا يوجد مكعب أمامك"); return
	var kind: String = _blocks.get(p, "stone")
	_remove_block(p); _inventory[kind] = int(_inventory.get(kind, 0)) + 1; _show_toast("جمعت " + BLOCK_LABELS.get(kind, kind)); AudioDirector.play_cue("player.action"); _save_world()

func _place_front() -> void:
	if int(_inventory.get(_selected_block, 0)) <= 0: _show_toast("هذه المادة نفدت"); return
	var p := _target_block(true)
	if p == Vector3i(999, 999, 999) or _blocks.has(p): _show_toast("المكان مشغول"); return
	_set_block(p, _selected_block); _inventory[_selected_block] -= 1; _show_toast("بنيت " + BLOCK_LABELS.get(_selected_block, _selected_block)); AudioDirector.play_cue("score.reward"); _save_world()

func _target_block(for_place := false) -> Vector3i:
	var forward := Vector3(0, 0, -1)
	var p := Vector3i(roundi(_player.position.x), floori(_player.position.y - 1.0), roundi(_player.position.z)) + Vector3i(0, 0, -1)
	if for_place: p.y = floori(_player.position.y - 0.2)
	for i in range(4):
		var test := p + Vector3i(0, 0, i)
		if _blocks.has(test): return test + (Vector3i(0, 1, 0) if for_place else Vector3i.ZERO)
	return Vector3i(999, 999, 999)

func _cycle_block() -> void:
	var keys := ["grass", "dirt", "stone", "wood", "sand"]
	_selected_block = keys[(keys.find(_selected_block) + 1) % keys.size()]
	_show_toast("المادة المختارة: " + BLOCK_LABELS[_selected_block])

func _update_hud() -> void:
	if _coords_label == null: return
	_coords_label.text = "QatanCraft  •  موقعك: %d, %d" % [roundi(_player.position.x), roundi(_player.position.z)]
	_inventory_label.text = "المادة: %s   |   مخزون: %d" % [BLOCK_LABELS[_selected_block], int(_inventory.get(_selected_block, 0))]

func _show_toast(text: String) -> void:
	if _toast == null: return
	_toast.text = text; _toast.modulate = Color.WHITE
	if _toast_tween and _toast_tween.is_valid(): _toast_tween.kill()
	_toast_tween = create_tween(); _toast_tween.tween_interval(2.2); _toast_tween.tween_property(_toast, "modulate", Color(1, 1, 1, 0), 0.6)

func _save_world() -> void:
	var data := {"seed": _world_seed, "blocks": {}}
	for pos in _blocks.keys(): data.blocks["%d,%d,%d" % [pos.x, pos.y, pos.z]] = _blocks[pos]
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE); if f: f.store_string(JSON.stringify(data)); f.close()
	if _save_label: _save_label.text = "✓ تم حفظ عالمك تلقائيًا"

func _load_world() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ); if not f: return
	var parsed: Variant = JSON.parse_string(f.get_as_text()); f.close()
	if not parsed is Dictionary: return
	_world_seed = int(parsed.get("seed", 7331)); var saved: Dictionary = parsed.get("blocks", {})
	for key in saved.keys():
		var parts := str(key).split(",")
		if parts.size() == 3: _blocks[Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))] = str(saved[key])

func _build_audio() -> void:
	# Optional project-owned WAV cues are loaded when present; gameplay remains safe when muted.
	var audio_cues := {"ui.confirm":"res://audio/ui_confirm.wav", "player.action":"res://audio/block_break.wav", "score.reward":"res://audio/block_place.wav"}
	for cue_id in audio_cues:
		AudioDirector.register_cue(cue_id, audio_cues[cue_id])

func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.86; return m

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new(); l.text = text; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", color); return l
