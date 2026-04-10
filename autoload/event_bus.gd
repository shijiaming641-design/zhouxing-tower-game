## 用于跨场景、解耦通信的全局事件总线
extends Node

# 游戏流程事件
@warning_ignore("unused_signal")
signal game_started
@warning_ignore("unused_signal")
signal game_over(won: bool)
@warning_ignore("unused_signal")
signal victory_achieved

# 玩家事件
@warning_ignore("unused_signal")
signal player_hp_changed(new_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal player_gold_changed(new_amount: int)
@warning_ignore("unused_signal")
signal materials_changed(new_amount: int)
@warning_ignore("unused_signal")
signal combo_energy_changed(current: int, maximum: int)  # 连击能量变化
@warning_ignore("unused_signal")
signal player_class_selected(class_id: int)
@warning_ignore("unused_signal")
signal inventory_changed

# 战斗事件
@warning_ignore("unused_signal")
signal battle_started(enemy_data: EnemyData)
@warning_ignore("unused_signal")
signal battle_ended(won: bool)
@warning_ignore("unused_signal")
signal player_moved(move_type: int)
@warning_ignore("unused_signal")
signal enemy_moved(move_type: int)
@warning_ignore("unused_signal")
signal round_result(result: String, player_move: int, enemy_move: int)
@warning_ignore("unused_signal")
signal combo_triggered(combo_name: String, effect: String)

# 地图事件
@warning_ignore("unused_signal")
signal floor_advanced(floor_num: int)
@warning_ignore("unused_signal")
signal node_selected(node_type: int)

# 商店事件
@warning_ignore("unused_signal")
signal item_purchased(item_type: String, cost: int)

# ===== 随机事件系统信号 =====
# 好事件信号
@warning_ignore("unused_signal")
signal good_event_triggered(event_type: String, event_data: Dictionary)
@warning_ignore("unused_signal")
signal bad_event_triggered(event_type: String, event_data: Dictionary)

# 事件战斗信号
@warning_ignore("unused_signal")
signal event_battle_started(is_good_event: bool, context: Dictionary)
@warning_ignore("unused_signal")
signal event_battle_round_result(round_num: int, player_move: int, enemy_move: int, won: bool)
@warning_ignore("unused_signal")
signal event_battle_ended(wins: int, is_good_event: bool, context: Dictionary)

# 事件结算信号
@warning_ignore("unused_signal")
signal event_attribute_changed(attribute: String, value: int)
@warning_ignore("unused_signal")
signal event_gold_changed(amount: int)
@warning_ignore("unused_signal")
signal event_discount_changed(discount: float)
@warning_ignore("unused_signal")
signal event_equipment_lost(item: Dictionary, via_battle: bool)
@warning_ignore("unused_signal")
signal event_skill_disabled(combo_id: String)
@warning_ignore("unused_signal")
signal event_battle_reward(reward_type: String, item_data: Dictionary)

# 事件完成信号（用于切换回地图）
@warning_ignore("unused_signal")
signal event_completed
