extends SceneTree

func _finish(code: int, scene: Node = null) -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://scenes/ui/character_select.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var text := _collect_labels(scene)
	if text.find("专属被动") < 0 or text.find("命数归零") < 0:
		push_error("Character select should show the selected role passive in the dossier, got: %s" % text)
		_finish(1, scene)
		return
	var dossier: Node = scene.get_node_or_null("ComboPanel")
	var dossier_text := _collect_labels(dossier)
	if dossier_text.find("出征倾向") >= 0 or dossier_text.find("生命：") >= 0 or dossier_text.find("攻击：") >= 0 or dossier_text.find("定位") >= 0:
		push_error("Character dossier should only show passive details, not duplicate stats/tendency. got: %s" % dossier_text)
		_finish(1, scene)
		return

	print("character_passive_display_smoke: ok")
	_finish(0, scene)

func _collect_labels(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	for child in node.get_children():
		parts.append(_collect_labels(child))
	return "\n".join(parts)
