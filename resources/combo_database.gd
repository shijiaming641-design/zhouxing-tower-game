## 连招数据库
## 存储所有可用的连招数据

class_name ComboDatabase
extends Node

const MoveSymbols = preload("res://resources/move_symbols.gd")

const HIDDEN_COMBO_IDS := [
	"bloodthirsty_slash",
	"reflect_aura",
	"absolute_hit",
	"desperate_counter",
	"iron_fortress",
	"supply_bombard"
]

const START_COMMON_COMBO_IDS := [
	"penetrating_strike",
	"tactical_interference",
	"lightning_strike",
	"solid_defense",
	"double_strike"
]

const HIDDEN_COMBO_CATALOG := [
	{"id": "bloodthirsty_slash", "category": "器物联动布局", "requires": "妖刀", "desc": "装备妖刀后可用"},
	{"id": "reflect_aura", "category": "器物联动布局", "requires": "护心镜", "desc": "装备护心镜后可用"},
	{"id": "absolute_hit", "category": "器物联动布局", "requires": "精确系统全套", "desc": "装备精确系统全套后可用"},
	{"id": "desperate_counter", "category": "状态依赖布局", "requires": "命数≤30%", "desc": "命数低于30%时自动触发"},
	{"id": "iron_fortress", "category": "状态依赖布局", "requires": "护甲≥5", "desc": "护甲值达到5以上时可用"},
	{"id": "supply_bombard", "category": "状态依赖布局", "requires": "背包满格", "desc": "背包满时消耗1件物品可发动"}
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
	var exclusive_era: String
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
		p_exclusive_class: String = "",
		p_exclusive_era: String = ""
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
		exclusive_era = p_exclusive_era
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

	# ========== 时代专属基础布局 ==========
	var combo_era_qin := ComboInfo.new(
		"qin_tiger_push",
		"虎符压阵",
		[2, 2, 0],
		"持令推进：本回合攻击+2，无视1护甲",
		"pierce_buff",
		2,
		3,
		UnlockLevel.BASIC,
		"",
		"qin"
	)
	all_combos.append(combo_era_qin)

	var combo_era_song := ComboInfo.new(
		"song_trade_turn",
		"市舶周转",
		[0, 2, 2],
		"商路兑现：本场战斗胜利额外获得10金币",
		"bonus_gold",
		10,
		2,
		UnlockLevel.BASIC,
		"",
		"song"
	)
	all_combos.append(combo_era_song)

	var combo_era_china := ComboInfo.new(
		"china_unity_echo",
		"山河同契",
		[1, 0, 0],
		"薪火回响：恢复4命，若已满命则获得2护甲",
		"heal_shield",
		4,
		3,
		UnlockLevel.BASIC,
		"",
		"china"
	)
	all_combos.append(combo_era_china)
	
	# ========== 特殊机制连招（仅展示，不在左侧选择列表中）==========
	# 妖刀联动
	var combo_item1 := ComboInfo.new(
		"bloodthirsty_slash",
		"嗜血斩",
		[1, 2, 1],  # △→□→△
		"【妖刀】伤害的50%转化为命数",
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
		3,
		3,
		UnlockLevel.BASIC
	)
	combo_item2.is_unlocked = false  # 不在左侧可选列表中
	all_combos.append(combo_item2)
	
	# 精确系统联动
	var combo_item3 := ComboInfo.new(
		"absolute_hit",
		"绝对命中",
		[1, 0, 1],
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
		"【命数≤30%】伤害×2，获得3护甲",
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
		"铁壁反震",
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
	
	# 三步布局最多只有27种。四步布局作为额外终式空间，不挤占三步基础格。

	# ========== 角色专属连招 ==========
	all_combos.append(ComboInfo.new(
		"diagnose",
		"望闻问切",
		[2, 0, 0],
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
		[2, 0, 1],
		"恢复5命，若满命则获得2护甲",
		"heal_shield",
		5,
		4,
		UnlockLevel.BASIC,
		"医生"
	))
	all_combos.append(ComboInfo.new(
		"virus_implant",
		"病毒植入",
		[1, 2, 2],
		"敌人下回合无法行动，受到2伤害；你获得1护甲",
		"stun_damage",
		2,
		3,
		UnlockLevel.BASIC,
		"黑客"
	))
	all_combos.append(ComboInfo.new(
		"system_overload",
		"系统过载",
		[2, 1, 1],
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
		[0, 1, 0],
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
		[1, 1, 1],
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
		[0, 2, 1],
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
		[2, 1, 2],
		"每回合恢复2命，持续3回合",
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
		[0, 0, 0],
		"获得4点护甲，并短暂维持防御态势",
		"shield_duration",
		4,
		3,
		UnlockLevel.BASIC,
		"流浪者"
	))

	# ========== 四步终式布局（高级解锁，不占三步27格）==========
	all_combos.append(ComboInfo.new(
		"formation_breaker",
		"破阵连环",
		[1, 1, 2, 1],
		"连环破阵：造成8点全体伤害",
		"damage_all",
		8,
		4,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"mountain_reversal",
		"山岳回震",
		[2, 2, 1, 2],
		"守势成峰：获得6护甲，反弹伤害",
		"shield_reflect",
		6,
		4,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"lockstep_snare",
		"连环锁势",
		[1, 2, 0, 2],
		"步步封锁：造成3伤害，并眩晕敌人",
		"stun_damage",
		3,
		4,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"renewal_cycle",
		"生息轮转",
		[2, 0, 2, 0],
		"生息不绝：每回合恢复3命，持续3回合",
		"regen",
		9,
		4,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"trade_tide",
		"商潮回涌",
		[0, 2, 2, 0],
		"商路滚动：本场战斗胜利额外获得16金币",
		"bonus_gold",
		16,
		3,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"last_lamp_reversal",
		"残灯逆照",
		[0, 0, 1, 2],
		"命线将断时反扑：伤害×2，获得护甲",
		"desperate",
		0,
		4,
		UnlockLevel.ADVANCED
	))
	all_combos.append(ComboInfo.new(
		"arsenal_unload",
		"倾仓齐发",
		[1, 1, 0, 2],
		"物资压阵：背包满格时消耗1件物品，造成10伤害",
		"consume_item_damage",
		10,
		4,
		UnlockLevel.ADVANCED
	))
	_apply_balance_profile()
	_apply_unlock_progression()
	DebugLog.log("[ComboDatabase] Initialized with ", all_combos.size(), " combos")

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
		"qin_tiger_push": {"cooldown": 3, "role": "秦卷专属强攻", "hint": "秦卷独有布局。适合抢前中段节奏，用穿透强化直接压低强敌血线。"},
		"song_trade_turn": {"cooldown": 2, "role": "宋卷专属经营", "hint": "宋卷独有布局。越早打出越赚，适合把普通战转成后续商队和工造优势。"},
		"china_unity_echo": {"cooldown": 3, "role": "终局专属续战", "hint": "终局独有布局。高压战里先稳住血线，再用后续布局接管节奏。"},
		"bloodthirsty_slash": {"cooldown": 3, "role": "装备吸血", "hint": "妖刀联动技。适合攻击高但血线不稳时，用输出换回复。"},
		"reflect_aura": {"cooldown": 3, "role": "装备反伤", "hint": "护心镜联动技。适合护甲较高时使用，把敌人的攻击压力反打回去。"},
		"absolute_hit": {"cooldown": 4, "role": "装备爆发", "hint": "精确系统联动技。适合关键回合打确定暴击，解决高血量目标。"},
		"desperate_counter": {"cooldown": 3, "role": "低命反打", "hint": "条件技。命数低于30%时价值很高，但不要为了触发它主动卖太多命。"},
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
		"formation_breaker": {"cooldown": 4, "role": "四步终式·破阵", "hint": "四步终式。适合压低多目标或Boss阶段血线，打出来应该像一次明确推进。"},
		"mountain_reversal": {"cooldown": 4, "role": "四步终式·回震", "hint": "四步终式。适合先稳住防线，再把敌人的进攻压力转成反打窗口。"},
		"lockstep_snare": {"cooldown": 4, "role": "四步终式·锁势", "hint": "四步终式。适合在危险回合前封住敌招，争取下一手空间。"},
		"renewal_cycle": {"cooldown": 4, "role": "四步终式·生息", "hint": "四步终式。越早打出越能稳住长战斗，适合承受连续压力。"},
		"trade_tide": {"cooldown": 3, "role": "四步终式·商潮", "hint": "四步终式。适合把普通战变成后续商店优势，早触发更赚。"},
		"last_lamp_reversal": {"cooldown": 4, "role": "四步终式·残灯", "hint": "四步终式。血线危险时才有价值，适合保留到真正需要翻盘的回合。"},
		"arsenal_unload": {"cooldown": 4, "role": "四步终式·倾仓", "hint": "四步终式。背包满时把资源压力转成当场爆发，适合物资过剩局。"},
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
		elif combo.exclusive_era != "" and combo.exclusive_era != GameState.selected_era_id:
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
		if combo.exclusive_era != "" and combo.exclusive_era != GameState.selected_era_id:
			continue
		if combo.id in HIDDEN_COMBO_IDS:
			continue
		if combo.exclusive_era != "":
			result.append(combo)
		elif combo.id in START_COMMON_COMBO_IDS:
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

static func get_hidden_combo_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in HIDDEN_COMBO_CATALOG:
		result.append((entry as Dictionary).duplicate(true))
	return result

static func get_era_combo_name(combo_name: String) -> String:
	var qin_map := {
		"全体穿透": "军阵贯杀",
		"战术干扰": "军令扰阵",
		"闪电突袭": "疾骑突袭",
		"稳固防御": "坚垒拒敌",
		"能量充能": "蓄势待发",
		"循环护盾": "玄甲回环",
		"束缚致命": "缚敌斩首",
		"双重打击": "双锋并进",
		"虎符压阵": "虎符压阵",
		"望闻问切": "军医望诊",
		"妙手回春": "营救回春",
		"病毒植入": "秘符暗植",
		"系统过载": "机关过载",
		"金钱帝国": "盐铁通筹",
		"精算头脑": "度支神算",
		"固若金汤": "城寨金汤",
		"五谷丰登": "屯田丰收",
		"记忆爆破": "旧忆裂阵",
		"相位护盾": "游身护势"
	}
	var song_map := {
		"全体穿透": "弩阵齐发",
		"战术干扰": "机宜牵制",
		"闪电突袭": "轻骑急袭",
		"稳固防御": "城防固守",
		"能量充能": "点将蓄势",
		"循环护盾": "楼橹回护",
		"束缚致命": "缚敌点杀",
		"双重打击": "双锋连断",
		"市舶周转": "市舶周转",
		"望闻问切": "太医四诊",
		"妙手回春": "杏林回春",
		"病毒植入": "机巧暗植",
		"系统过载": "算筹过载",
		"金钱帝国": "市舶通利",
		"精算头脑": "筹算入微",
		"固若金汤": "铁壁保甲",
		"五谷丰登": "丰年积粟",
		"记忆爆破": "行旅旧梦",
		"相位护盾": "帷幕护身"
	}
	var china_map := {
		"全体穿透": "山河贯杀号",
		"战术干扰": "终局牵制",
		"闪电突袭": "星火突进",
		"稳固防御": "长城固守",
		"能量充能": "薪火蓄势",
		"循环护盾": "山海回护",
		"束缚致命": "锁敌定锋",
		"双重打击": "双锋复断",
		"山河同契": "山河同契",
		"望闻问切": "国医四诊",
		"妙手回春": "山河回春",
		"病毒植入": "星图暗植",
		"系统过载": "星火过载",
		"金钱帝国": "百业通筹",
		"精算头脑": "山河筹算",
		"固若金汤": "守土成城",
		"五谷丰登": "仓廪丰年",
		"记忆爆破": "百代裂响",
		"相位护盾": "归乡护势"
	}
	match GameState.selected_era_id:
		"song":
			var song_name = str(song_map.get(combo_name, combo_name))
			if combo_name == "市舶周转":
				return "〔宋秘〕%s" % song_name
			return song_name
		"china":
			var china_name = str(china_map.get(combo_name, combo_name))
			if combo_name == "山河同契":
				return "〔终局〕%s" % china_name
			return china_name
		_:
			var qin_name = str(qin_map.get(combo_name, combo_name))
			if combo_name == "虎符压阵":
				return "〔秦秘〕%s" % qin_name
			return qin_name

static func get_era_role_text(role_text: String) -> String:
	match GameState.selected_era_id:
		"song":
			return "宋卷·%s" % role_text
		"china":
			return "终局·%s" % role_text
		_:
			return "秦卷·%s" % role_text

static func get_era_hint_text(hint_text: String) -> String:
	if hint_text == "":
		return ""
	match GameState.selected_era_id:
		"song":
			return "%s 适合走经营、工造与稳守路线。" % hint_text
		"china":
			return "%s 终局压迫更复合，适合留作关键回合翻盘。" % hint_text
		_:
			return "%s 适合速战强压，尽快把战局推向决胜。" % hint_text

# 序列转字符串显示（如 [0,1,2] → "○→○→□"）
func sequence_to_display(sequence: Array) -> String:
	return MoveSymbols.sequence_to_text(sequence)

# 检查输入序列是否匹配某个连招
func check_combo_sequence(moves: Array[int]) -> ComboInfo:
	if moves.size() < 3:
		return null
	var best_combo: ComboInfo = null
	var best_len := 0
	for combo in all_combos:
		if not combo.is_unlocked:
			continue
		if combo.sequence.size() > moves.size():
			continue
		var start_idx := moves.size() - combo.sequence.size()
		var matched := true
		for i in range(combo.sequence.size()):
			if moves[start_idx + i] != combo.sequence[i]:
				matched = false
				break
		if matched and combo.sequence.size() > best_len:
			best_combo = combo
			best_len = combo.sequence.size()
	return best_combo

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
	return MoveSymbols.sequence_to_text(sequence)
