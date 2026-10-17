extends Node
## Bind the imported UI composites (Latin body face + Noto Sans SC) at runtime, after the editor's first import pass.
const GameFonts = preload("res://scripts/manus/game_fonts.gd")
var _regular: Font
var _theme: Theme

func _enter_tree() -> void:
	var catalog_font_path := "res://assets/template/fonts/ui_regular.tres"
	var catalog_body_path := "res://assets/template/fonts/Figtree-VF.subset.woff2"
	if FileAccess.file_exists(catalog_font_path) and FileAccess.file_exists(catalog_body_path):
		_regular = load(catalog_font_path) as Font
	if _regular == null:
		# Catalog fonts are optional presentation assets. Keep Android startup
		# alive when an imported catalog font is unavailable.
		_regular = load("res://assets/fonts/DejaVuSans.ttf") as Font
	if _regular == null:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(["Noto Sans Arabic", "Noto Sans", "DejaVu Sans"])
		_regular = system_font
	_theme = GameFonts.create_theme(_regular, _regular, _regular)
	get_tree().node_added.connect(_bind_node)
	_bind_tree(get_tree().root)

func _bind_tree(node: Node) -> void:
	_bind_node(node)
	for child in node.get_children():
		_bind_tree(child)

func _bind_node(node: Node) -> void:
	if node is Control:
		if node.theme != null:
			if node.theme.default_font == null:
				node.theme = node.theme.duplicate()
				node.theme.default_font = _regular
		elif node.get_parent_control() == null:
			node.theme = _theme
	elif node is Label3D and node.font == null:
		GameFonts.apply_world_label(node, _regular)
