using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 解锁项目类型
    /// </summary>
    public enum UnlockType
    {
        ComboSlot,        // 连招槽位
        AttributePoint,   // 属性点
        BackpackSlot,    // 背包格子
        Combo,            // 连招
        ComboCooldown,   // 冷却缩减
        EquipmentSlot,   // 装备槽位
        UltimateCombo,    // 终极连招
        PassiveSkill,    // 被动技能
        UltimateCharge,  // 外挂充能
        Protection,      // 保护光环
        AttributeBonus   // 属性加成
    }

    /// <summary>
    /// 解锁项目
    /// </summary>
    [System.Serializable]
    public class UnlockItem
    {
        public string ID;
        public string Name;
        public string Description;
        public UnlockType Type;
        public int Cost;  // 所需人员存储器数量
        public bool IsUnlocked;
        public string Icon;
        
        public UnlockItem(string id, string name, UnlockType type, int cost, string desc, string icon)
        {
            ID = id;
            Name = name;
            Type = type;
            Cost = cost;
            Description = desc;
            Icon = icon;
            IsUnlocked = false;
        }
    }

    /// <summary>
    /// 玩家进度数据
    /// </summary>
    [System.Serializable]
    public class PlayerProgress
    {
        public int MemoryFragments = 3;       // 人员存储器数量
        public int CurrentWeek = 1;            // 当前周目
        public int TotalWins = 0;              // 总胜场
        public List<string> UnlockedCombos = new List<string>();  // 已解锁连招
        public List<UnlockItem> UnlockedItems = new List<UnlockItem>();  // 已解锁项目
        
        public PlayerProgress()
        {
            InitializeUnlockItems();
        }
        
        private void InitializeUnlockItems()
        {
            // 基础连招槽位
            UnlockedItems.Add(new UnlockItem("combo_slot_1", "第2连招槽", UnlockType.ComboSlot, 1, "解锁第二个连招槽位", "⚔️"));
            
            // 属性点
            UnlockedItems.Add(new UnlockItem("attr_hp_1", "生命强化", UnlockType.AttributePoint, 1, "+2最大生命", "❤️"));
            UnlockedItems.Add(new UnlockItem("attr_atk_1", "攻击强化", UnlockType.AttributePoint, 1, "+1攻击力", "⚔️"));
            
            // 背包
            UnlockedItems.Add(new UnlockItem("backpack_1", "背包扩展", UnlockType.BackpackSlot, 1, "+4背包格子", "🎒"));
            
            // 高级连招
            UnlockedItems.Add(new UnlockItem("combo_adv_1", "高级连招包", UnlockType.Combo, 2, "解锁3个高级连招", "📜"));
            
            // 冷却缩减
            UnlockedItems.Add(new UnlockItem("cooldown_1", "冷却缩减", UnlockType.ComboCooldown, 2, "所有连招-1回合冷却", "⏱️"));
            
            // 装备槽位
            UnlockedItems.Add(new UnlockItem("equip_1", "装备槽位+1", UnlockType.EquipmentSlot, 2, "解锁第3个装备槽", "💍"));
            
            // 终极连招
            UnlockedItems.Add(new UnlockItem("combo_ulti_1", "终极连招包", UnlockType.UltimateCombo, 4, "解锁终极连招", "🌟"));
            
            // 被动技能
            UnlockedItems.Add(new UnlockItem("passive_1", "战斗序章", UnlockType.PassiveSkill, 4, "每局开始+1护甲", "🛡️"));
            
            // 外挂充能
            UnlockedItems.Add(new UnlockItem("charge_1", "外挂充能", UnlockType.UltimateCharge, 4, "每局可用次数+1", "⚡"));
            
            // 保护光环
            UnlockedItems.Add(new UnlockItem("protect_1", "护盾光环", UnlockType.Protection, 8, "每局免疫一次伤害", "✨"));
            
            // 属性加成
            UnlockedItems.Add(new UnlockItem("attr_bonus_1", "全面强化", UnlockType.AttributeBonus, 8, "血量+2, 攻击+0.5", "💪"));
        }
    }

    /// <summary>
    /// 角色类型
    /// </summary>
    public enum CharacterType
    {
        Explorer,   // 探索者 - 预知地图
        Immortal,   // 长生者 - 复活1次
        Adventurer, // 冒险家 - 经验加成
        Warrior,    // 剑士 - 高暴击
        Tank       // 坦克 - 高防御
    }

    /// <summary>
    /// 局外成长系统 - 管理玩家永久进度
    /// </summary>
    public class ProgressionSystem : MonoBehaviour
    {
        private static ProgressionSystem _instance;
        public static ProgressionSystem Instance => _instance;
        
        // 玩家进度数据
        private PlayerProgress progress = new PlayerProgress();
        
        // 角色选择
        private CharacterType selectedCharacter = CharacterType.Explorer;
        
        // 初始属性配置
        private Dictionary<CharacterType, CharacterStats> characterStats = new Dictionary<CharacterType, CharacterStats>()
        {
            { CharacterType.Explorer, new CharacterStats(80, 3, 0, 0, "预知前方地图，风险降低") },
            { CharacterType.Immortal, new CharacterStats(100, 2, 0, 0, "额外一次复活机会") },
            { CharacterType.Adventurer, new CharacterStats(80, 4, 0, 0, "战斗获得额外经验") },
            { CharacterType.Warrior, new CharacterStats(70, 5, 0, 15, "高额暴击伤害") },
            { CharacterType.Tank, new CharacterStats(120, 2, 5, 0, "高血量高防御") }
        };
        
        void Awake()
        {
            _instance = this;
            LoadProgress();
        }
        
        /// <summary>
        /// 获取玩家进度
        /// </summary>
        public PlayerProgress GetProgress()
        {
            return progress;
        }
        
        /// <summary>
        /// 获取人员存储器数量
        /// </summary>
        public int GetMemoryCount()
        {
            return progress.MemoryFragments;
        }
        
        /// <summary>
        /// 添加人员存储器
        /// </summary>
        public void AddMemory(int count)
        {
            progress.MemoryFragments += count;
            SaveProgress();
            Debug.Log($"获得 {count} 个人员存储器！总计: {progress.MemoryFragments}");
        }
        
        /// <summary>
        /// 消耗人员存储器
        /// </summary>
        public bool SpendMemory(int count)
        {
            if (progress.MemoryFragments >= count)
            {
                progress.MemoryFragments -= count;
                SaveProgress();
                return true;
            }
            return false;
        }
        
        /// <summary>
        /// 是否可以解锁
        /// </summary>
        public bool CanAfford(int cost)
        {
            return progress.MemoryFragments >= cost;
        }
        
        /// <summary>
        /// 解锁项目
        /// </summary>
        public bool Unlock(string itemId)
        {
            UnlockItem item = progress.UnlockedItems.Find(i => i.ID == itemId);
            
            if (item == null)
            {
                Debug.LogWarning($"解锁项目不存在: {itemId}");
                return false;
            }
            
            if (item.IsUnlocked)
            {
                Debug.LogWarning($"项目已解锁: {item.Name}");
                return false;
            }
            
            if (!CanAfford(item.Cost))
            {
                Debug.LogWarning($"人员存储器不足! 需要 {item.Cost}，当前 {progress.MemoryFragments}");
                return false;
            }
            
            // 消耗并解锁
            if (SpendMemory(item.Cost))
            {
                item.IsUnlocked = true;
                ApplyUnlockEffect(item);
                SaveProgress();
                Debug.Log($"解锁成功: {item.Name}!");
                return true;
            }
            
            return false;
        }
        
        /// <summary>
        /// 应用解锁效果
        /// </summary>
        private void ApplyUnlockEffect(UnlockItem item)
        {
            switch (item.Type)
            {
                case UnlockType.ComboSlot:
                    Debug.Log("已解锁第二个连招槽位!");
                    break;
                case UnlockType.AttributePoint:
                    Debug.Log("属性已提升!");
                    break;
                case UnlockType.BackpackSlot:
                    Debug.Log("背包已扩展!");
                    break;
                case UnlockType.Combo:
                    Debug.Log("已解锁高级连招!");
                    break;
                case UnlockType.ComboCooldown:
                    Debug.Log("连招冷却已缩减!");
                    break;
                case UnlockType.EquipmentSlot:
                    Debug.Log("装备槽位已增加!");
                    break;
                case UnlockType.UltimateCombo:
                    Debug.Log("已解锁终极连招!");
                    break;
                case UnlockType.PassiveSkill:
                    Debug.Log("被动技能已激活!");
                    break;
                case UnlockType.UltimateCharge:
                    Debug.Log("外挂充能已增强!");
                    break;
                case UnlockType.Protection:
                    Debug.Log("保护光环已激活!");
                    break;
                case UnlockType.AttributeBonus:
                    Debug.Log("全属性已加成!");
                    break;
            }
        }
        
        /// <summary>
        /// 获取所有解锁项目
        /// </summary>
        public List<UnlockItem> GetUnlockedItems()
        {
            return progress.UnlockedItems;
        }
        
        /// <summary>
        /// 获取已解锁项目数量
        /// </summary>
        public int GetUnlockedCount()
        {
            return progress.UnlockedItems.FindAll(i => i.IsUnlocked).Count;
        }
        
        /// <summary>
        /// 选择角色
        /// </summary>
        public void SelectCharacter(CharacterType character)
        {
            selectedCharacter = character;
            Debug.Log($"已选择角色: {character}");
        }
        
        /// <summary>
        /// 获取角色初始属性
        /// </summary>
        public CharacterStats GetCharacterStats()
        {
            return characterStats[selectedCharacter];
        }
        
        /// <summary>
        /// 获取角色名称
        /// </summary>
        public string GetCharacterName()
        {
            switch (selectedCharacter)
            {
                case CharacterType.Explorer: return "探索者";
                case CharacterType.Immortal: return "长生者";
                case CharacterType.Adventurer: return "冒险家";
                case CharacterType.Warrior: return "剑士";
                case CharacterType.Tank: return "坦克";
                default: return "未知";
            }
        }
        
        /// <summary>
        /// 获取角色描述
        /// </summary>
        public string GetCharacterDescription()
        {
            return characterStats[selectedCharacter].Description;
        }
        
        /// <summary>
        /// 增加胜场
        /// </summary>
        public void AddWin()
        {
            progress.TotalWins++;
            SaveProgress();
        }
        
        /// <summary>
        /// 获取总胜场
        /// </summary>
        public int GetTotalWins()
        {
            return progress.TotalWins;
        }
        
        /// <summary>
        /// 完成一周目
        /// </summary>
        public void CompleteWeek()
        {
            progress.CurrentWeek++;
            
            // 周目奖励
            int reward = 3 + (progress.CurrentWeek - 1) * 2;
            AddMemory(reward);
            
            Debug.Log($"第{progress.CurrentWeek - 1}周目完成! 获得 {reward} 个人员存储器!");
        }
        
        /// <summary>
        /// 保存进度
        /// </summary>
        public void SaveProgress()
        {
            string json = JsonUtility.ToJson(progress);
            PlayerPrefs.SetString("PlayerProgress", json);
            PlayerPrefs.Save();
        }
        
        /// <summary>
        /// 加载进度
        /// </summary>
        public void LoadProgress()
        {
            string json = PlayerPrefs.GetString("PlayerProgress", "");
            
            if (!string.IsNullOrEmpty(json))
            {
                try
                {
                    progress = JsonUtility.FromJson<PlayerProgress>(json);
                    Debug.Log("进度已加载!");
                }
                catch
                {
                    Debug.LogWarning("进度加载失败，使用默认进度");
                    progress = new PlayerProgress();
                }
            }
            else
            {
                Debug.Log("新玩家，将使用默认进度");
                progress = new PlayerProgress();
            }
        }
        
        /// <summary>
        /// 重置进度
        /// </summary>
        public void ResetProgress()
        {
            progress = new PlayerProgress();
            SaveProgress();
            Debug.Log("进度已重置!");
        }
    }

    /// <summary>
    /// 角色属性
    /// </summary>
    [System.Serializable]
    public class CharacterStats
    {
        public int MaxHP;
        public int BaseAttack;
        public int BaseDefense;
        public int BaseCritRate;
        public string Description;
        
        public CharacterStats(int hp, int atk, int def, int crit, string desc)
        {
            MaxHP = hp;
            BaseAttack = atk;
            BaseDefense = def;
            BaseCritRate = crit;
            Description = desc;
        }
    }
}
