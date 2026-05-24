class_name MoveSymbols
extends RefCounted

const TIAN := 0
const REN := 1
const DI := 2

const MOVE_NAMES: Array[String] = ["天", "人", "地"]
const MOVE_COLORS: Array[Color] = [
	Color("#D8C17B"),
	Color("#C56A5B"),
	Color("#6D8A5A")
]

static func move_name(move_type: int) -> String:
	if move_type < 0 or move_type >= MOVE_NAMES.size():
		return "?"
	return MOVE_NAMES[move_type]

static func sequence_to_text(sequence: Array, separator: String = "→") -> String:
	var result := ""
	for i in range(sequence.size()):
		if i > 0:
			result += separator
		result += move_name(int(sequence[i]))
	return result

static func matchup_hint() -> String:
	return "天克人，人克地，地克天"
