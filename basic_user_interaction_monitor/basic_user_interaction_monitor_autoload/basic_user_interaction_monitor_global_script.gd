extends Node2D

#region Constants
const REQUIRED_AMOUNT_OF_TIME_ELAPSED_FOR_MOTION_TO_BE_CONSIDERED_STOPPED: float = (
	0.1 # In seconds
)
#endregion

#region Variables with setters
var is_user_clicking_on_screen: bool = (
	false
):
	set(new_value_for_is_user_clicking_on_screen):
		is_user_clicking_on_screen = new_value_for_is_user_clicking_on_screen
		_called_by_setter_for_is_user_clicking_on_screen(
		)
var is_user_dragging_on_screen: bool = (
	false
):
	set(new_value_for_is_user_dragging_on_screen):
		is_user_dragging_on_screen = new_value_for_is_user_dragging_on_screen
		_called_by_setter_for_is_user_dragging_on_screen(
		)
var is_cursor_moving_on_screen: bool = (
	false
):
	set(new_value_for_is_cursor_moving_on_screen):
		is_cursor_moving_on_screen = new_value_for_is_cursor_moving_on_screen
		_called_by_setter_for_is_cursor_moving_on_screen(
		)
#endregion

#region Variables
var elapsed_time_since_last_motion: float = (
	0.0
)
var global_cursor_position: Vector2 = (
	Vector2.ZERO
)
#endregion 

#region Built-in Function: _physics_process
func _physics_process(
		delta: float,
) -> void:
	if (
		is_cursor_moving_on_screen == (
			false
		)
	):
		return

	var new_elapsed_time_since_last_motion: float = (
		elapsed_time_since_last_motion
		+
		delta
	)

	_set_elapsed_time_since_last_motion(
		new_elapsed_time_since_last_motion,
	)

	if (
		elapsed_time_since_last_motion
		>
		REQUIRED_AMOUNT_OF_TIME_ELAPSED_FOR_MOTION_TO_BE_CONSIDERED_STOPPED
	):
		_set_cursor_is_not_moving_on_screen(
		)
#endregion

#region Built-in Function: _input
func _input(
		passed_event: InputEvent,
) -> void:
	if _get_is_event_relevant(
		passed_event,
	) == (
		false
	):
		return

	_set_global_cursor_position(
	)

	_check_if_user_is_clicking_on_screen(
	)

	_check_if_cursor_is_moving_on_screen(
		passed_event,
	)

	_check_if_user_is_dragging_on_screen(
	)
#endregion 

#region Functions called by setters
func _called_by_setter_for_is_user_clicking_on_screen(
) -> void:
	if (
		is_user_clicking_on_screen
	) == (
		true
	):
		_signal_user_is_clicking_on_screen(
		)
	else:
		_signal_user_is_not_clicking_on_screen(
		)


func _called_by_setter_for_is_user_dragging_on_screen(
) -> void:
	if (
		is_user_dragging_on_screen
	) == (
		true
	):
		_signal_user_is_dragging_on_screen(
		)
	else:
		_signal_user_is_not_dragging_on_screen(
		)


func _called_by_setter_for_is_cursor_moving_on_screen(
) -> void:
	if (
		is_cursor_moving_on_screen
	) == (
		true
	):
		_signal_cursor_is_moving_on_screen(
		)
	else:
		_signal_cursor_is_not_moving_on_screen(
		)
#endregion

#region Functions _get
func _get_global_cursor_position(
) -> Vector2:
	_set_global_cursor_position(
	)
	return global_cursor_position

func _get_is_event_relevant(
		passed_event: InputEvent,
):
	if (
		passed_event is InputEventMouseButton
		or
		passed_event is InputEventMouseMotion
		or
		passed_event is InputEventScreenTouch
		or
		passed_event is InputEventScreenDrag
	):
		return (
			true
		)
	else:
		return (
			false
		)
#endregion

#region Functions _set
func _set_elapsed_time_since_last_motion(
		passed_time: float,
):
	elapsed_time_since_last_motion = (
		passed_time
	)


func _set_user_is_clicking_on_screen(
) -> void:
	if (
		is_user_clicking_on_screen == (
			true
		)
	):
		return
	is_user_clicking_on_screen = (
		true
	)


func _set_user_is_not_clicking_on_screen(
) -> void:
	if (
		is_user_clicking_on_screen == (
			false
		)
	):
		return
	is_user_clicking_on_screen = (
		false
	)


func _set_cursor_is_moving_on_screen(
) -> void:
	if (
		is_cursor_moving_on_screen == (
			true
		)
	):
		return
	is_cursor_moving_on_screen = (
		true
	)


func _set_cursor_is_not_moving_on_screen(
) -> void:
	if (
		is_cursor_moving_on_screen == (
			false
		)
	):
		return
	is_cursor_moving_on_screen = (
		false
	)


func _set_user_is_dragging_on_screen(
) -> void:
	if (
		is_user_dragging_on_screen == (
			true
		)
	):
		return
	is_user_dragging_on_screen = (
		true
	)


func _set_user_is_not_dragging_on_screen(
) -> void:
	if (
		is_user_dragging_on_screen == (
			false
		)
	):
		return
	is_user_dragging_on_screen = (
		false
	)


func _set_global_cursor_position(
) -> void:
	global_cursor_position = (
		get_global_mouse_position(
		)
	)
#endregion

#region Functions _check
func _check_if_user_is_clicking_on_screen(
) -> void:
	if Input.is_mouse_button_pressed(
		MOUSE_BUTTON_LEFT,
	) == true:
		_set_user_is_clicking_on_screen(
		)
	else:
		_set_user_is_not_clicking_on_screen(
		)


func _check_if_cursor_is_moving_on_screen(
		passed_event: InputEvent,
) -> void:
	if (
		passed_event is InputEventMouseMotion
		or
		passed_event is InputEventScreenDrag # InputEventScreenDrag for it to work on touchscreens
	):
		_set_elapsed_time_since_last_motion(
			0.0,
		)
		_set_cursor_is_moving_on_screen(
		)


func _check_if_user_is_dragging_on_screen(
) -> void:
	if (
		is_cursor_moving_on_screen == (
			true
		)
		and
		is_user_clicking_on_screen == (
			true
		)
	):
		_set_user_is_dragging_on_screen(
		)
	else:
		_set_user_is_not_dragging_on_screen(
		)
#endregion

#region Functions emitting signals
func _signal_user_is_clicking_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_started_clicking.emit(
		global_cursor_position,
	)


func _signal_user_is_not_clicking_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_stopped_clicking.emit(
		global_cursor_position,
	)


func _signal_cursor_is_moving_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_started_moving_cursor.emit(
		global_cursor_position,
	)


func _signal_cursor_is_not_moving_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_stopped_moving_cursor.emit(
		global_cursor_position,
	)


func _signal_user_is_dragging_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_started_dragging.emit(
		global_cursor_position,
	)


func _signal_user_is_not_dragging_on_screen(
) -> void:
	BasicUserInteractionMonitorSignalbus.signal_user_stopped_dragging.emit(
		global_cursor_position,
	)
#endregion 
