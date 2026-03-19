## 用于跨场景、解耦通信的全局事件总线
extends Node

# 游戏流程事件
signal game_started
signal game_over(won: bool)
signal victory_achieved

# 玩家事件
signal player_hp_changed(new_hp: int, max_hp: int)
signal player_gold_changed(new_amount: int)
signal player_class_selected(class_id: int)
signal inventory_changed

# 战斗事件
signal battle_started(enemy_data: EnemyData)
signal battle_ended(won: bool)
signal player_moved(move_type: int)
signal enemy_moved(move_type: int)
signal round_result(result: String, player_move: int, enemy_move: int)
signal combo_triggered(combo_name: String, effect: String)

# 地图事件
signal floor_advanced(floor_num: int)
signal node_selected(node_type: int)

# 商店事件
signal item_purchased(item_type: String, cost: int)
