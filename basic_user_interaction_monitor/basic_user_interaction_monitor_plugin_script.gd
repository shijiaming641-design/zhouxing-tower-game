@tool
extends EditorPlugin

#region Constants
const AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORGLOBAL = (
	"BasicUserInteractionMonitorGlobal"
)
const AUTOLOAD_PATH_BASICUSERINTERACTIONMONITORGLOBAL = (
	#"uid://cv7vlb0vy484m" 
	"res://addons/basic_user_interaction_monitor/basic_user_interaction_monitor_autoload/basic_user_interaction_monitor_global_script.gd"
)
const AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORSIGNALBUS = (
	"BasicUserInteractionMonitorSignalbus"
)
const AUTOLOAD_PATH_BASICUSERINTERACTIONMONITORSIGNALBUS = (
	#"uid://b6ebuqy605533" 
	"res://addons/basic_user_interaction_monitor/basic_user_interaction_monitor_autoload/basic_user_interaction_monitor_signalbus_script.gd"
)
#endregion

#region Functions to enable and disable plugin
func _enable_plugin(
) -> void:
	# Add the Autoloads to Project Settings
	add_autoload_singleton(
		AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORGLOBAL,
		AUTOLOAD_PATH_BASICUSERINTERACTIONMONITORGLOBAL,
	)

	add_autoload_singleton(
		AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORSIGNALBUS,
		AUTOLOAD_PATH_BASICUSERINTERACTIONMONITORSIGNALBUS,
	)


func _disable_plugin(
) -> void:
	# Remove the Autoloads when the plugin is disabled
	remove_autoload_singleton(
		AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORGLOBAL,
	)

	remove_autoload_singleton(
		AUTOLOAD_NAME_BASICUSERINTERACTIONMONITORSIGNALBUS,
	)
#endregion
