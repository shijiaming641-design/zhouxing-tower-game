extends Node # Not refcounted because it is an autoload 

#region Signals for user clicking
signal signal_user_started_clicking(
		passed_global_cursor_position: Vector2,
)
signal signal_user_stopped_clicking(
		passed_global_cursor_position: Vector2,
)
#endregion

#region Signals for user moving the cursor
signal signal_user_started_moving_cursor(
		passed_global_cursor_position: Vector2,
)
signal signal_user_stopped_moving_cursor(
		passed_global_cursor_position: Vector2,
)
#endregion

#region Signals for user dragging
signal signal_user_started_dragging(
		passed_global_cursor_position: Vector2,
)
signal signal_user_stopped_dragging(
		passed_global_cursor_position: Vector2,
)
#endregion
