## 连招数据库
## 存储所有可用的连招数据

class_name ComboDatabase
extends Node

const HIDDEN_COMBO_IDS := [
	"bloodthirsty_slash",
	"reflect_aura",
	"absolute_hit",
	"desperate_counter",
	"iron_fortress",
	"supply_bombard"
]

# 连招序列符号映射
# 0 = ○ (circle)
# 1 = △ (triangle)
# 2 = □ (square)

# 解锁等级
enum UnlockLevel {
	BASIC = 0,    # 基础（初始解锁）
	ADVANCED = 1, # 高级（后续解锁）
	ULTIMATE = 2  # 终极（满级解锁）
}

# 连招数据结构
class ComboInfo:
	var id: String
	var name: String
	var sequence: Array[int]  # [0,0,1] = OO△
	var description: String
	var effect_type: String   # damage, shield, buff, debuff
	var effect_value: int
	var cooldown: int         # 冷却回合数
	var unlock_level: int     # 解锁等级
	var is_unlocked: bool     # 是否已解锁
	var exclusive_class: String
	var role: String
	var usage_hint: String
	
	func _init(
		p_id: String,
		p_name: String,
		p_sequence: Array[int],
		p_desc: String,
		p_effect: String,
		p_value: int,
		p_cooldown: int,
		p_unlock: int,
		p_exclusive_class: String = ""
	):
		id = p_id
		name = p_name
		sequence = p_sequence
		description = p_desc
		effect_type = p_effect
		effect_value = p_value
		cooldown = p_cooldown
		unlock_level = p_unlock
		is_unlocked = p_unlock == UnlockLevel.BASIC  # 初始只有基础解锁
		exclusive_class = p_exclusive_class
		role = ""
		usage_hint = ""

# 所有连招定义
var all_combos: Array[ComboInfo] = []

func _ready():
	_init_database()

func _init_database():
	all_combos.clear()
	
	# ========== 基础可选择连招 ==========
	
	# △→△→□ 全体穿透 - 5伤害, 冷却3
	var combo1 := ComboInfo.new(
		"penetrating_strike",
		"全体穿透",
		[1, 1, 2],
		"全体穿透伤害：造成5点伤害",
		"damage_all",
		5,
		3,
		UnlockLevel.BASIC
	)
	combo1.is_unlocked = true
	all_combos.append(combo1)
	
	# △→□→○ 战术干扰 - 敌人冷却+1, 冷却2
	var combo2 := ComboInfo.new(
		"tactical_interference",
		"战术干扰",
		[1, 2, 0],
		"干扰+减益：敌人下回合出招冷却+1秒",
		"enemy_cooldown",
		1,
		2,
		UnlockLevel.BASIC
	)
	combo2.is_unlocked = true
	all_combos.append(combo2)
	
	# △→○→□ 闪电突袭 - 3伤害, 先攻, 冷却2
	var combo3 := ComboInfo.new(
		"lightning_strike",
		"闪电突袭",
		[1, 0, 2],
		"快速两连击：造成3点伤害，下回合先攻",
		"damage_first",
		3,
		2,
		UnlockLevel.BASIC
	)
	combo3.is_unlocked = true
	all_combos.append(combo3)
	
	# □→□→△ 稳固防御 - 3护甲, 反弹, 冷却3
	var combo4 := ComboInfo.new(
		"solid_defense",
		"稳固防御",
		[2, 2, 1],
		"格挡反击：获得3护甲，反弹下次伤害",
		"shield_reflect",
		3,
		3,
		UnlockLevel.BASIC
	)
	combo4.is_unlocked = true
	all_combos.append(combo4)
	
	# ○→△→△ 能量充能 - 攻击+2持续2回合, 冷却3
	var combo5 := ComboInfo.new(
		"energy_charge",
		"能量充能",
		[0, 1, 1],
		"蓄力强化：下2回合攻击+2",
		"attack_buff",
		2,
		3,
		UnlockLevel.BASIC
	)
	combo5.is_unlocked = true
	all_combos.append(combo5)
	
	# □→○→□ 循环护盾 - 2护甲持续2回合, 冷却3
	var combo6 := ComboInfo.new(
		"cyclic_shield",
		"循环护盾",
		[2, 0, 2],
		"持续防护：获得2护甲，持续2回合",
		"shield_duration",
		2,
		3,
		UnlockLevel.BASIC
	)
	combo6.is_unlocked = true
	all_combos.append(combo6)
	
	# □→△→○ 束缚致命 - 束缚1回合, 3伤害, 冷却3
	var combo7 := ComboInfo.new(
		"bind_fatal",
		"束缚致命",
		[2, 1, 0],
		"束缚+致命：下回合束缚1回合，造成3点伤害",
		"bind_damage",
		3,
		3,
		UnlockLevel.BASIC
	)
	combo7.is_unlocked = true
	all_combos.append(combo7)
	
	# ○→○→□ 双重打击 - 2伤害x2, 冷却2
	var combo8 := ComboInfo.new(
		"double_strike",
		"双重打击",
		[0, 0, 2],
		"连续攻击：连续攻击2次，每次2点伤害",
		"double_hit",
		4,
		2,
		UnlockLevel.BASIC
	)
	combo8.is_unlocked = true
	all_combos.append(combo8)
	
	# ========== 特殊机制连招（仅展示，不在左侧选择列表中）==========
	# 妖刀联动
	var combo_item1 := ComboInfo.new(
		"bloodthirsty_slash",
		"嗜血斩",
		[1, 2, 1],  # △→□→△
		"【妖刀】伤害的50%转化为生命",
		"life_steal_50",
		0,
		3,
		UnlockLevel.BASIC
	)
	combo_item1.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_item1)
	
	# 护心镜联动
	var combo_item2 := ComboInfo.new(
		"reflect_aura",
		"反伤光环",
		[0, 2, 0],  # ○→□→○
		"【护心镜】反弹伤害提升至3倍",
		"reflect_3x",
		0,
		3,
		UnlockLevel.BASIC
	)
	combo_item2.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_item2)
	
	# 精确系统联动
	var combo_item3 := ComboInfo.new(
		"absolute_hit",
		"绝对命中",
		[1, 0, 2],  # △→○→□
		"【精确系统】本次攻击必中且暴击",
		"auto_crit",
		0,
		4,
		UnlockLevel.BASIC
	)
	combo_item3.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_item3)
	
	# 低血量触发
	var combo_state1 := ComboInfo.new(
		"desperate_counter",
		"绝地反击",
		[0, 0, 1],  # ○→○→△
		"【生命≤30%】伤害×2，获得3护甲",
		"desperate",
		0,
		4,
		UnlockLevel.BASIC
	)
	combo_state1.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_state1)
	
	# 高护甲触发
	var combo_state2 := ComboInfo.new(
		"iron_fortress",
		"固若金汤",
		[2, 2, 2],  # □→□→□
		"【护甲≥5】护甲值转化为等量伤害反击",
		"shield_to_damage",
		0,
		4,
		UnlockLevel.BASIC
	)
	combo_state2.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_state2)
	
	# 背包满格触发
	var combo_state3 := ComboInfo.new(
		"supply_bombard",
		"物资轰炸",
		[1, 1, 0],  # △→△→○
		"【背包满格】消耗1件物品，造成8伤害",
		"consume_item_damage",
		8,
		3,
		UnlockLevel.BASIC
	)
	combo_state3.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_state3)
	
	# ========== 高级连招 ==========
	# ○→△→○ 双环共振 - 全体4伤害, 冷却4
	var combo_adv1 := ComboInfo.new(
		"dual_ring_resonance",
		"双环共振",
		[0, 1, 0],
		"范围攻击：对全体敌人造成4点伤害",
		"damage_all",
		4,
		4,
		UnlockLevel.ADVANCED
	)
	all_combos.append(combo_adv1)
	
	# △→△→△ 三角强袭 - 8伤害无视护甲, 冷却4
	var combo_adv2 := ComboInfo.new(
		"triangle_assault",
		"三角强袭",
		[1, 1, 1],
		"单体爆发：造成8点伤害，无视1点护甲",
		"damage_pierce",
		8,
		4,
		UnlockLevel.ADVANCED
	)
	all_combos.append(combo_adv2)
	
	# □→△→□ 方阵壁垒 - 全体3护盾, 冷却4
	var combo_adv3 := ComboInfo.new(
		"square_barrier",
		"方阵壁垒",
		[2, 1, 2],
		"团队防护：全体获得3护盾",
		"shield_all",
		3,
		4,
		UnlockLevel.ADVANCED
	)
	all_combos.append(combo_adv3)
	
	# ○→□→△ 程序过载 - 3伤害+中毒2回合, 冷却3
	var combo_adv4 := ComboInfo.new(
		"program_overload",
		"程序过载",
		[0, 2, 1],
		"持续伤害：造成3点伤害+中毒2回合（每回合2伤害）",
		"damage_poison",
		5,
		3,
		UnlockLevel.ADVANCED
	)
	all_combos.append(combo_adv4)
	
	# △→○→△ 镜像反击 - 复制敌人招式反击, 冷却3
	var combo_adv5 := ComboInfo.new(
		"mirror_counter",
		"镜像反击",
		[1, 0, 1],
		"复制反击：复制敌人上回合招式并反击",
		"mirror",
		4,
		3,
		UnlockLevel.ADVANCED
	)
	all_combos.append(combo_adv5)
	
	# ========== 终极连招 ==========
	# ○→△→□→○ 完美循环 - 4伤害+3护甲+先攻, 冷却5
	var combo_ult1 := ComboInfo.new(
		"perfect_cycle",
		"完美循环",
		[0, 1, 2, 0],
		"全能效果：造成4伤害，获得3护甲，下回合先攻",
		"all_in_one",
		4,
		5,
		UnlockLevel.ULTIMATE
	)
	all_combos.append(combo_ult1)
	
	# △→□→○→△ 毁灭三角 - 终结技, 冷却6
	var combo_ult2 := ComboInfo.new(
		"destructive_triangle",
		"毁灭三角",
		[1, 2, 0, 1],
		"终结技：敌人每损失10%生命，额外+1伤害（最大+10）",
		"execute",
		10,
		6,
		UnlockLevel.ULTIMATE
	)
	all_combos.append(combo_ult2)
	
	# □→○→△→□ 绝对防御 - 无敌+反弹200%, 冷却5
	var combo_ult3 := ComboInfo.new(
		"absolute_defense",
		"绝对防御",
		[2, 0, 1, 2],
		"无敌回合：下回合免疫所有伤害，反弹200%",
		"invincible",
		0,
		5,
		UnlockLevel.ULTIMATE
	)
	all_combos.append(combo_ult3)
	
	# ○→○→○ 三重圆环 - 33%即死, 冷却6
	var combo_ult4 := ComboInfo.new(
		"triple_ring",
		"三重圆环",
		[0, 0, 0],
		"即死判定：33%概率直接击败非BOSS敌人",
		"instant_kill",
		0,
		6,
		UnlockLevel.ULTIMATE
	)
	all_combos.append(combo_ult4)
	
	# △→△→○→□ 系统崩溃 - BOSS特攻, 冷却5
	var combo_ult5 := ComboInfo.new(
		"system_crash",
		"系统崩溃",
		[1, 1, 0, 2],
		"BOSS特攻：对BOSS额外造成最大生命15%伤害",
		"boss_hunter",
		0,
		5,
		UnlockLevel.ULTIMATE
	)
	all_combos.append(combo_ult5)

	# ========== 角色专属连招 ==========
	all_combos.append(ComboInfo.new(
		"diagnose",
		"望闻问切",
		[0, 2, 1],
		"识破敌人弱点，本回合攻击+3，无视1护甲",
		"pierce_buff",
		3,
		3,
		UnlockLevel.BASIC,
		"医生"
	))
	all_combos.append(ComboInfo.new(
		"heal_wave",
		"妙手回春",
		[2, 0, 2],
		"恢复5点生命，若满血则获得2护甲",
		"heal_shield",
		5,
		4,
		UnlockLevel.BASIC,
		"医生"
	))
	all_combos.append(ComboInfo.new(
		"virus_implant",
		"病毒植入",
		[1, 2, 1],
		"敌人下回合无法行动，受到2伤害",
		"stun_damage",
		2,
		3,
		UnlockLevel.BASIC,
		"黑客"
	))
	all_combos.append(ComboInfo.new(
		"system_overload",
		"系统过载",
		[2, 2, 1],
		"无视所有护甲，造成6点伤害",
		"ignore_armor_damage",
		6,
		4,
		UnlockLevel.BASIC,
		"黑客"
	))
	all_combos.append(ComboInfo.new(
		"money_empire",
		"金钱帝国",
		[0, 0, 1],
		"战斗胜利额外获得12金币",
		"bonus_gold",
		12,
		2,
		UnlockLevel.BASIC,
		"商人"
	))
	all_combos.append(ComboInfo.new(
		"precise_mind",
		"精算头脑",
		[1, 1, 2],
		"本回合暴击率+40%，暴击伤害+50%",
		"crit_boost",
		40,
		3,
		UnlockLevel.BASIC,
		"商人"
	))
	all_combos.append(ComboInfo.new(
		"iron_wall",
		"固若金汤",
		[2, 0, 2],
		"获得5护甲，下回合开始时再获得3护甲",
		"armor_delayed",
		8,
		4,
		UnlockLevel.BASIC,
		"农民"
	))
	all_combos.append(ComboInfo.new(
		"harvest_blessing",
		"五谷丰登",
		[0, 2, 0],
		"每回合恢复2生命，持续3回合",
		"regen",
		6,
		3,
		UnlockLevel.BASIC,
		"农民"
	))
	all_combos.append(ComboInfo.new(
		"memory_burst",
		"记忆爆破",
		[0, 1, 2],
		"释放存储器残响，造成5点伤害",
		"damage",
		5,
		3,
		UnlockLevel.BASIC,
		"流浪者"
	))
	all_combos.append(ComboInfo.new(
		"phase_guard",
		"相位护盾",
		[2, 1, 0],
		"获得4点护甲，并短暂维持防御态势",
		"shield_duration",
		4,
		3,
		UnlockLevel.BASIC,
		"流浪者"
	))
	_apply_balance_profile()
	_apply_unlock_progression()
	print("[ComboDatabase] Initialized with ", all_combos.size(), " combos")

func _apply_balance_profile() -> void:
	var profiles := {
		"penetrating_strike": {"cooldown": 3, "role": "稳定输出", "hint": "基础泛用伤害。适合不知道选什么时携带，用来稳定压低普通敌人血线。"},
		"tactical_interference": {"cooldown": 2, "role": "节奏干扰", "hint": "低冷却功能技。适合拖慢强敌节奏，给自己争取凑下一套连招的时间。"},
		"lightning_strike": {"cooldown": 2, "role": "短冷却补刀", "hint": "伤害不高但周转快。适合收残血、保持进攻节奏。"},
		"solid_defense": {"cooldown": 3, "role": "抗压防御", "hint": "适合敌人攻击较高或自己血线危险时携带，能把防守转成反击机会。"},
		"energy_charge": {"cooldown": 3, "role": "伤害成长", "hint": "适合搭配高攻击装备或攻击成长局。先强化攻击，再用普通胜负或伤害连招扩大收益。"},
		"cyclic_shield": {"cooldown": 3, "role": "持续护甲", "hint": "适合稳健打法。护甲能缓冲失误，尤其适合面对高攻击敌人。"},
		"bind_fatal": {"cooldown": 4, "role": "控制补伤", "hint": "控制价值高于伤害。适合打精英和Boss，用安全回合换节奏。"},
		"double_strike": {"cooldown": 2, "role": "攻击收益", "hint": "基础多段输出。攻击越高收益越明显，适合装备长剑、妖刀、赏金宽刃时携带。"},
		"bloodthirsty_slash": {"cooldown": 3, "role": "装备吸血", "hint": "妖刀联动技。适合攻击高但血线不稳时，用输出换回复。"},
		"reflect_aura": {"cooldown": 3, "role": "装备反伤", "hint": "护心镜联动技。适合护甲较高时使用，把敌人的攻击压力反打回去。"},
		"absolute_hit": {"cooldown": 4, "role": "装备爆发", "hint": "精确系统联动技。适合关键回合打确定暴击，解决高血量目标。"},
		"desperate_counter": {"cooldown": 3, "role": "低血反打", "hint": "条件技。生命低于30%时价值很高，但不要为了触发它主动卖太多血。"},
		"iron_fortress": {"cooldown": 3, "role": "护甲转伤", "hint": "条件技。适合农民或护甲装备局，把防御积累转成爆发伤害。"},
		"supply_bombard": {"cooldown": 3, "role": "资源爆破", "hint": "条件技。背包满时消耗物品打高额伤害，适合物资过剩时清库存。"},
		"dual_ring_resonance": {"cooldown": 3, "role": "高级群伤", "hint": "高级稳定输出。比基础伤害更强，适合作为高级解锁后的泛用选择。"},
		"triangle_assault": {"cooldown": 4, "role": "高级爆发", "hint": "单体高伤害。适合精英和Boss，也适合快速压过危险阶段。"},
		"square_barrier": {"cooldown": 4, "role": "高级防御", "hint": "强护甲技能。适合容错和抗Boss，能让你更安全地凑下一套。"},
		"program_overload": {"cooldown": 3, "role": "持续输出", "hint": "即伤加持续伤。适合长战斗，越拖越赚。"},
		"mirror_counter": {"cooldown": 3, "role": "反制", "hint": "适合读懂敌人套路后使用，敌人越稳定，收益越高。"},
		"perfect_cycle": {"cooldown": 5, "role": "终极综合", "hint": "攻防一体。适合劣势回合反转，也适合Boss战稳定推进。"},
		"destructive_triangle": {"cooldown": 6, "role": "终结爆发", "hint": "敌人血量越低越强。不要开局急用，留到中后段打斩杀。"},
		"absolute_defense": {"cooldown": 5, "role": "终极防御", "hint": "免伤级技能。适合Boss强攻或自己血线危险时保命。"},
		"triple_ring": {"cooldown": 6, "role": "赌博斩杀", "hint": "对非Boss高风险高收益。适合普通/精英战赌快速结束，不适合作为稳定Boss方案。"},
		"system_crash": {"cooldown": 5, "role": "Boss特攻", "hint": "专门打Boss。适合长期Boss战，越早打出越能压低Boss血线。"},
		"diagnose": {"cooldown": 3, "role": "医生破防", "hint": "提高本回合攻击并穿透。适合配合高攻击装备或关键胜负回合。"},
		"heal_wave": {"cooldown": 4, "role": "医生续航", "hint": "血少时回血，满血时转护甲。适合稳定推进和修正失误。"},
		"virus_implant": {"cooldown": 4, "role": "黑客控制", "hint": "眩晕价值很高。适合打危险敌人或Boss关键回合。"},
		"system_overload": {"cooldown": 4, "role": "黑客爆发", "hint": "无视防御的稳定伤害。适合处理高护甲或高血量目标。"},
		"money_empire": {"cooldown": 2, "role": "商人经济", "hint": "越早触发越赚。适合普通战中提前为后续商店做准备。"},
		"precise_mind": {"cooldown": 3, "role": "商人暴击", "hint": "适合配合高攻击或多段伤害，在关键回合提高爆发。"},
		"iron_wall": {"cooldown": 4, "role": "农民护甲", "hint": "护甲可保留时价值很高。适合叠甲后继续滚雪球。"},
		"harvest_blessing": {"cooldown": 3, "role": "农民回复", "hint": "持续回血适合长战斗，越早打出越赚。"},
		"memory_burst": {"cooldown": 3, "role": "流浪者输出", "hint": "简单直接的中等伤害，适合流浪者稳定压血。"},
		"phase_guard": {"cooldown": 3, "role": "流浪者防御", "hint": "护甲收益稳定，适合在不确定敌人出招时提高容错。"},
	}
	for combo in all_combos:
		if not profiles.has(combo.id):
			continue
		var profile: Dictionary = profiles[combo.id]
		combo.cooldown = int(profile.get("cooldown", combo.cooldown))
		combo.role = str(profile.get("role", ""))
		combo.usage_hint = str(profile.get("hint", ""))

func _apply_unlock_progression() -> void:
	for combo in all_combos:
		if combo.id in HIDDEN_COMBO_IDS:
			combo.is_unlocked = false
		else:
			combo.is_unlocked = GameState.has_combo_tier_unlocked(combo.unlock_level)

# 获取已解锁的连招列表
func get_unlocked_combos() -> Array[ComboInfo]:
	var result: Array[ComboInfo] = []
	for combo in all_combos:
		if combo.is_unlocked:
			result.append(combo)
	return result

func get_start_selectable_combos() -> Array[ComboInfo]:
	var result: Array[ComboInfo] = []
	for combo in all_combos:
		if not combo.is_unlocked:
			continue
		if combo.exclusive_class != "":
			continue
		if combo.sequence.size() != 3:
			continue
		if combo.id in HIDDEN_COMBO_IDS:
			continue
		result.append(combo)
	return result

# 获取所有连招（包括未解锁）
func get_all_combos() -> Array[ComboInfo]:
	return all_combos

# 根据ID获取连招
func get_combo_by_id(combo_id: String) -> ComboInfo:
	for combo in all_combos:
		if combo.id == combo_id:
			return combo
	return null

func get_class_exclusive_combos(class_display_name: String) -> Array[ComboInfo]:
	var result: Array[ComboInfo] = []
	for combo in all_combos:
		if combo.exclusive_class == class_display_name:
			result.append(combo)
	return result

# 序列转字符串显示（如 [0,1,2] → "○→○→□"）
func sequence_to_display(sequence: Array) -> String:
	var symbols = ["○", "△", "□"]
	var result = ""
	for i in range(sequence.size()):
		if i > 0:
			result += "→"
		result += symbols[sequence[i]]
	return result

# 检查输入序列是否匹配某个连招
func check_combo_sequence(moves: Array[int]) -> ComboInfo:
	# 只需要检查最近3个动作
	if moves.size() < 3:
		return null
	
	var last_3 = moves.slice(-3)
	
	for combo in all_combos:
		if not combo.is_unlocked:
			continue
		if combo.sequence.size() != 3:
			continue
		if last_3[0] == combo.sequence[0] and last_3[1] == combo.sequence[1] and last_3[2] == combo.sequence[2]:
			return combo
	
	return null

# ========== 战斗连招系统（连击能量触发）==========
# 这些连招通过消耗连击能量来释放，而不是通过手势序列

class CombatCombo:
	var id: String
	var name: String
	var sequence: Array[int]  # 手势序列
	var description: String
	var base_damage: int  # 每次攻击的基础伤害百分比（80表示80%）
	var attack_count: int  # 攻击次数
	var special_effect: String  # 特殊效果
	var energy_cost: int  # 能量消耗
	
	func _init(
		p_id: String,
		p_name: String,
		p_sequence: Array[int],
		p_desc: String,
		p_damage: int,
		p_count: int,
		p_effect: String,
		p_cost: int
	):
		id = p_id
		name = p_name
		sequence = p_sequence
		description = p_desc
		base_damage = p_damage
		attack_count = p_count
		special_effect = p_effect
		energy_cost = p_cost

var combat_combos: Array[CombatCombo] = []

func _init_combat_combos():
	if not combat_combos.is_empty():
		return
	
	# 穿刺 - 剪刀-剪刀-石头 (0,0,1) - 3次攻击，每次80%伤害
	var pierce := CombatCombo.new(
		"pierce",
		"穿刺",
		[0, 0, 1],
		"3次攻击，每次80%伤害",
		80, 3, "none", 3
	)
	combat_combos.append(pierce)
	
	# 旋风 - 布-剪刀-石头-布 (2,1,0,2) - 4次攻击+击退
	var whirlwind := CombatCombo.new(
		"whirlwind",
		"旋风",
		[2, 1, 0, 2],
		"4次攻击+击退",
		80, 4, "knockback", 4
	)
	combat_combos.append(whirlwind)
	
	# 粉碎 - 石头-剪刀-布-剪刀-剪刀 (2,1,0,1,0) - 5次攻击+暴击
	var crush := CombatCombo.new(
		"crush",
		"粉碎",
		[2, 1, 0, 1, 0],
		"5次攻击+暴击",
		80, 5, "crit", 5
	)
	combat_combos.append(crush)

# 获取所有战斗连招
func get_combat_combos() -> Array[CombatCombo]:
	_init_combat_combos()
	return combat_combos

# 根据ID获取战斗连招
func get_combat_combo_by_id(combo_id: String) -> CombatCombo:
	_init_combat_combos()
	for combo in combat_combos:
		if combo.id == combo_id:
			return combo
	return null

# 检查手势序列是否匹配某个战斗连招
func check_combat_combo_sequence(moves: Array[int]) -> CombatCombo:
	_init_combat_combos()
	
	if moves.is_empty():
		return null
	
	for combo in combat_combos:
		if combo.sequence.size() > moves.size():
			continue
		
		# 检查最后N个手势是否匹配
		var start_idx = moves.size() - combo.sequence.size()
		var is_match = true
		for i in range(combo.sequence.size()):
			if moves[start_idx + i] != combo.sequence[i]:
				is_match = false
				break
		
		if is_match:
			return combo
	
	return null

# 获取战斗连招的序列显示
func combat_combo_sequence_to_display(sequence: Array[int]) -> String:
	var symbols = ["○", "△", "□"]
	var result = ""
	for i in range(sequence.size()):
		if i > 0:
			result += "→"
		result += symbols[sequence[i]]
	return result
