extends Node

const DEFAULT_ENABLED := false

var enabled: bool = DEFAULT_ENABLED

func _ready() -> void:
	enabled = bool(ProjectSettings.get_setting("debug/zhouxing/verbose_logs", DEFAULT_ENABLED))

func log(
	message: Variant,
	p1: Variant = null,
	p2: Variant = null,
	p3: Variant = null,
	p4: Variant = null,
	p5: Variant = null,
	p6: Variant = null,
	p7: Variant = null,
	p8: Variant = null,
	p9: Variant = null
) -> void:
	if not enabled:
		return
	var parts: Array[String] = [str(message)]
	for value in [p1, p2, p3, p4, p5, p6, p7, p8, p9]:
		if value != null:
			parts.append(str(value))
	print(" ".join(parts))

func warn(message: String) -> void:
	push_warning(message)

func error(message: String) -> void:
	push_error(message)
