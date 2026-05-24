extends SceneTree

func _finish(code: int, combo_db: Node = null) -> void:
	if combo_db != null:
		combo_db.free()
	quit(code)

func _initialize() -> void:
	var combo_db = load("res://resources/combo_database.gd").new()
	combo_db._init_database()

	var ids := {}
	var names := {}
	var sequences := {}
	for combo in combo_db.get_all_combos():
		var id := str(combo.id)
		var name := str(combo.name)
		var seq_parts := PackedStringArray()
		for move in combo.sequence:
			seq_parts.append(str(move))
		var seq_key := ",".join(seq_parts)

		if combo.sequence.size() != 3 and combo.sequence.size() != 4:
			push_error("Layout sequences must stay 3-step or 4-step: %s = %s" % [id, seq_key])
			_finish(1, combo_db)
			return
		if ids.has(id):
			push_error("Duplicate layout id: %s" % id)
			_finish(1, combo_db)
			return
		if names.has(name):
			push_error("Duplicate layout name: %s / %s" % [name, id])
			_finish(1, combo_db)
			return
		var typed_seq_key := "%d:%s" % [combo.sequence.size(), seq_key]
		if sequences.has(typed_seq_key):
			push_error("Duplicate layout sequence: %s used by %s and %s" % [typed_seq_key, sequences[typed_seq_key], id])
			_finish(1, combo_db)
			return

		ids[id] = true
		names[name] = true
		sequences[typed_seq_key] = id

	var three_step_count := 0
	var four_step_count := 0
	for combo in combo_db.get_all_combos():
		if combo.sequence.size() == 3:
			three_step_count += 1
		elif combo.sequence.size() == 4:
			four_step_count += 1
	if three_step_count > 27:
		push_error("3-step layouts can only provide 27 unique sequences.")
		_finish(1, combo_db)
		return
	if four_step_count < 7:
		push_error("Expected at least seven 4-step terminal layouts, got: %d" % four_step_count)
		_finish(1, combo_db)
		return

	print("combo_layout_uniqueness_smoke: ok")
	_finish(0, combo_db)
