  A Basic User Interaction Monitor for Godot fully written in GDScript

# Pre-requisites:
Keep the default project setting for Emulate Mouse From Touch to ON:
  Project -> Project Settings -> Input Devices -> Pointing -> Emulate Mouse From Touch * ON *

# How to install ? 

Download the basic_user_interaction_monitor folder and put it inside of your Godot's project 'addons' folder. 

Then, go to Project -> Project Settings -> Plugins and enable the plugin.

The plugin automatically adds the necessary global variables.

# What does it do ?

* Updates global booleans related to mouse or touch input events
* Updates global variable global_cursor_position 
* Emits signals related to mouse or touch input events, passing the value for global_cursor_position 

# Features:

* Works for both mouse gestures and touchscreen
  
# How to use ?

Integrate the following variables and/or signals into your project:

## Global boolean variables: 

BasicUserInteractionMonitorGlobal.is_user_clicking_on_screen

BasicUserInteractionMonitorGlobal.is_user_dragging_on_screen

BasicUserInteractionMonitorGlobal.is_cursor_moving_on_screen

* Boolean Example:

```
if BasicUserInteractionMonitorGlobal.is_user_clicking_on_screen == false:

  *do something*
```

## Global signalbus signals:

BasicUserInteractionMonitorSignalbus.signal_user_started_clicking.connect()

BasicUserInteractionMonitorSignalbus.signal_user_stopped_clicking.connect()

BasicUserInteractionMonitorSignalbus.signal_user_started_moving_cursor.connect()

BasicUserInteractionMonitorSignalbus.signal_user_stopped_moving_cursor.connect()

BasicUserInteractionMonitorSignalbus.signal_user_started_dragging.connect()

BasicUserInteractionMonitorSignalbus.signal_user_stopped_dragging.connect()

  
* Signal Example:

```
BasicUserInteractionMonitorSignalbus.signal_user_started_clicking.connect(_function_called_to_do_something)

func _function_called_to_do_something(passed_from_signal_global_cursor_position: Vector2) -> void:
	print("global_cursor_position = ", passed_from_signal_global_cursor_position) 
```
# How does it work ?

```mermaid
flowchart TB
    %% ═══════════════════════════════════════════════════════════════
    %% MAIN ENTRY POINTS
    %% ═══════════════════════════════════════════════════════════════
    subgraph ENTRY_POINTS ["Entry Points"]
        direction TB
        EP1["_input(event)"] 
        EP2["_physics_process(delta)"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% _input() FLOW
    %% ═══════════════════════════════════════════════════════════════
    subgraph INPUT_FLOW ["_input(passed_event)"]
        direction TB
        I1["Receive InputEvent"] --> I2{"Event Relevant?<br/>MouseButton / MouseMotion<br/>ScreenTouch / ScreenDrag"}
        I2 -->|No| I3["Return / Ignore"]
        I2 -->|Yes| I4["_set_global_cursor_position()"]
        
        I4 --> I5["_check_if_user_is_clicking_on_screen()"]
        I5 --> I6["_check_if_cursor_is_moving_on_screen()"]
        I6 --> I7["_check_if_user_is_dragging_on_screen()"]
        I7 --> I8["End _input"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% _physics_process() FLOW - Cursor Motion Timeout
    %% ═══════════════════════════════════════════════════════════════
    subgraph PHYSICS_FLOW ["_physics_process(delta)"]
        direction TB
        P1["Start Frame"] --> P2{"is_cursor_moving_on_screen?"}
        P2 -->|false| P3["Return Early"]
        P2 -->|true| P4["elapsed_time += delta"]
        P4 --> P5["_set_elapsed_time_since_last_motion()"]
        P5 --> P6{"elapsed_time > 0.1s?"}
        P6 -->|No| P7["End Frame - Cursor Still Moving"]
        P6 -->|Yes| P8["_set_cursor_is_not_moving_on_screen()"]
        P8 --> P9["Setter triggers →<br/>_called_by_setter_for_is_cursor_moving_on_screen()"]
        P9 --> P10["Emit signal_user_stopped_moving_cursor"]
        P10 --> P11["End Frame"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% CLICK CHECK LOGIC
    %% ═══════════════════════════════════════════════════════════════
    subgraph CHECK_CLICK ["_check_if_user_is_clicking_on_screen()"]
        direction LR
        CC1{"Input.is_mouse_button_pressed(LEFT)?"}
        CC1 -->|Yes| CC2{"is_user_clicking_on_screen == true?"}
        CC1 -->|No| CC3{"is_user_clicking_on_screen == false?"}
        
        CC2 -->|Yes| CC4["Skip - State Unchanged"]
        CC2 -->|No| CC5["is_user_clicking_on_screen = true<br/>(setter emits started_clicking)"]
        
        CC3 -->|Yes| CC6["Skip - State Unchanged"]
        CC3 -->|No| CC7["is_user_clicking_on_screen = false<br/>(setter emits stopped_clicking)"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% CURSOR MOVEMENT CHECK LOGIC
    %% ═══════════════════════════════════════════════════════════════
    subgraph CHECK_CURSOR ["_check_if_cursor_is_moving_on_screen(event)"]
        direction LR
        CM1{"Event is MouseMotion<br/>OR ScreenDrag?"}
        CM1 -->|Yes| CM2["Reset elapsed_time = 0.0"]
        CM2 --> CM3{"is_cursor_moving_on_screen == true?"}
        CM3 -->|Yes| CM4["Skip - State Unchanged"]
        CM3 -->|No| CM5["is_cursor_moving_on_screen = true<br/>(setter emits started_moving_cursor)"]
        
        CM1 -->|No| CM6["No Action - Timeout handled in _physics_process"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% DRAG CHECK LOGIC
    %% ═══════════════════════════════════════════════════════════════
    subgraph CHECK_DRAG ["_check_if_user_is_dragging_on_screen()"]
        direction LR
        CD1{"cursor_moving AND<br/>clicking?"}
        CD1 -->|Yes| CD2{"is_user_dragging_on_screen == true?"}
        CD1 -->|No| CD3{"is_user_dragging_on_screen == false?"}
        
        CD2 -->|Yes| CD4["Skip - State Unchanged"]
        CD2 -->|No| CD5["is_user_dragging_on_screen = true<br/>(setter emits started_dragging)"]
        
        CD3 -->|Yes| CD6["Skip - State Unchanged"]
        CD3 -->|No| CD7["is_user_dragging_on_screen = false<br/>(setter emits stopped_dragging)"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% UNIVERSAL SETTER PATTERN
    %% ═══════════════════════════════════════════════════════════════
    subgraph SETTER_PATTERN ["Setter Pattern (All 3 State Variables)"]
        direction LR
        SP1["Variable Setter Called"] --> SP2["Assign New Value"]
        SP2 --> SP3["_called_by_setter_for_*()"]
        SP3 --> SP4{"New Value == true?"}
        SP4 -->|Yes| SP5["Emit *_started_* signal"]
        SP4 -->|No| SP6["Emit *_stopped_* signal"]
    end

    %% ═══════════════════════════════════════════════════════════════
    %% CONNECTIONS
    %% ═══════════════════════════════════════════════════════════════
    EP1 --> INPUT_FLOW
    EP2 --> PHYSICS_FLOW
    
    I5 --> CHECK_CLICK
    I6 --> CHECK_CURSOR
    I7 --> CHECK_DRAG
    
    %% All state changes route through setter pattern
    CC5 & CC7 & CM5 & CD5 & CD7 & P9 -.-> SETTER_PATTERN

    %% Styling
    classDef entry fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef process fill:#e8f5e9,stroke:#2e7d32
    classDef decision fill:#fff3e0,stroke:#ef6c00
    classDef signal fill:#f3e5f5,stroke:#7b1fa2
    classDef subgraphStyle fill:#fafafa,stroke:#9e9e9e,stroke-dasharray:5 5
    
    class EP1,EP2 entry
    class I4,I5,I6,I7,P4,P5,P8,P9,CC2,CC3,CC5,CC7,CM3,CM5,CD2,CD3,CD5,CD7 process
    class I2,P2,P6,CC1,CM1,CD1,SP4 decision
    class SP5,SP6,P10 signal
    class INPUT_FLOW,PHYSICS_FLOW,CHECK_CLICK,CHECK_CURSOR,CHECK_DRAG,SETTER_PATTERN subgraphStyle
