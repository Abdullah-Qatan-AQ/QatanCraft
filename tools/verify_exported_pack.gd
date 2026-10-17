extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "QatanCraft", "exported identity")
	for path: String in ["scripts/qatancraft_main.gd", "scenes/main.tscn", "audio/block_break.wav", "audio/block_place.wav", "audio/ui_confirm.wav"]:
		_check(ResourceLoader.exists("res://" + path), "pack resource: " + path)
	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "test scene excluded")
	_check(not ResourceLoader.exists("res://tools/capture_native.gd"), "native capture tool excluded")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		_check(main.get("_title_screen") != null, "pack creates title")
		_check(bool((main.get("_title_screen") as Control).visible), "pack boots to title")
		main.call("_start_game")
		await process_frame
		_check(main.get("_player") != null, "pack starts player")
		_check(main.get("_world_root") != null, "pack starts voxel world")
		_check(int((main.get("_blocks") as Dictionary).size()) > 100, "pack creates explorable world")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, resources, boot, voxel world, mobile loop")
		quit(0)
	else:
		for failure: String in _failures: push_error("[exported-pack] " + failure)
		quit(1)

func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures: _failures.append(context)
