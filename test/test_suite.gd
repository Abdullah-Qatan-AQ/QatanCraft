extends Node

var _checks := 0
var _failures := PackedStringArray()

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "QatanCraft", "project identity is QatanCraft")
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/main.tscn", "main scene is configured")
	_check(FileAccess.file_exists("res://scripts/qatancraft_main.gd"), "voxel controller exists")
	_check(FileAccess.file_exists("res://audio/block_break.wav"), "block break audio exists")
	_check(FileAccess.file_exists("res://audio/block_place.wav"), "block place audio exists")
	_check(FileAccess.file_exists("res://audio/ui_confirm.wav"), "UI confirmation audio exists")
	_check(AudioDirector != null, "audio director autoload exists")
	var packed: PackedScene = load("res://scenes/main.tscn")
	_check(packed != null, "main scene loads")
	if packed != null:
		var instance := packed.instantiate()
		get_tree().root.add_child(instance)
		await get_tree().process_frame
		_check(instance.get("_title_screen") != null, "title screen is created")
		_check(bool((instance.get("_title_screen") as Control).visible), "title screen is visible on boot")
		_check(str((instance.get("_title_screen") as Control).get_child(1).get_child(0).get_child(1).text) == "QATANCRAFT", "title text is branded")
		instance.queue_free()
		await get_tree().process_frame
	if _failures.is_empty():
		print("[qatancraft-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
	else:
		for failure in _failures: push_error("[qatancraft-tests] " + failure)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
