extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node("/root/GameState")
	var original_era := str(game_state.selected_era_id)
	game_state.selected_era_id = "qin"

	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main._show_main_menu()
	await process_frame
	main._show_meta_panel("codex")
	await process_frame

	var codex_text := _collect_labels(main.current_ui.get_node_or_null("MetaOverlay"))
	for required_text in ["卷首", "百代同震", "执卷人", "天不自明", "秦卷重军功"]:
		if codex_text.find(required_text) < 0:
			push_error("Codex lore should include %s, got: %s" % [required_text, codex_text])
			_finish(1, game_state, original_era, main)
			return

	print("codex_lore_smoke: ok")
	_finish(0, game_state, original_era, main)

func _collect_labels(node: Node) -> String:
	if node == null:
		return ""
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	for child in node.get_children():
		var child_text := _collect_labels(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)

func _finish(code: int, game_state: Node, original_era: String, main: Node) -> void:
	game_state.selected_era_id = original_era
	if main != null:
		main.queue_free()
	quit(code)
