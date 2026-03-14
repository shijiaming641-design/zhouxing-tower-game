using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 装备类型
    /// </summary>
    public enum EquipmentType
    {
        Weapon,     // 武器
        Armor,     // 护甲
        Accessory  // 饰品
    }

    /// <summary>
    /// 稀有度
    /// </summary>
    public enum Rarity
    {
        Common = 1,     // 普通(白色)
        Rare = 2,       // 精良(蓝色)
        Epic = 3,       // 稀有(紫色)
        Legendary = 4  // 传说(金色)
    }

    /// <summary>
    /// 特殊效果
    /// </summary>
    public enum SpecialEffect
    {
        None,           // 无
        LifeSteal,      // 吸血
        Reflect,        // 反射
        Poison,         // 中毒
        Freeze,         // 冰冻
        Dodge,          // 闪避
        Fire,           // 火焰附加
        Ice,            // 冰霜附加
        Lightning,      // 雷电附加
        CriticalBoost,  // 暴击伤害提升
        DoubleAttack,   // 双重攻击
    }

    /// <summary>
    /// 装备类
    /// </summary>
    [System.Serializable]
    public class Equipment
    {
        public string ID;
        public string Name;
        public EquipmentType Type;
        public Rarity Rarity;
        
        // 基础属性
        public int Attack;
        public int Defense;
        public int MaxHP;
        public float CritRate;
        public float CritDamage;
        public int Block;
        
        // 特殊效果
        public SpecialEffect SpecialEffect;
        public float SpecialEffectChance;  // 触发概率
        
        // 价格
        public int Price;
        
        // 描述
        public string Description;
        
        public Equipment() { }
        
        public Equipment(string id, string name, EquipmentType type, Rarity rarity, int price)
        {
            ID = id;
            Name = name;
            Type = type;
            Rarity = rarity;
            Price = price;
        }
        
        /// <summary>
        /// 获取稀有度颜色
        /// </summary>
        public string GetRarityColor()
        {
            switch(Rarity)
            {
                case Rarity.Common: return "white";
                case Rarity.Rare: return "blue";
                case Rarity.Epic: return "purple";
                case Rarity.Legendary: return "yellow";
                default: return "white";
            }
        }
        
        /// <summary>
        /// 获取稀有度名称
        /// </summary>
        public string GetRarityName()
        {
            switch(Rarity)
            {
                case Rarity.Common: return "普通";
                case Rarity.Rare: return "精良";
                case Rarity.Epic: return "稀有";
                case Rarity.Legendary: return "传说";
                default: return "未知";
            }
        }
        
        /// <summary>
        /// 获取装备图标
        /// </summary>
        public string GetIcon()
        {
            switch(Type)
            {
                case EquipmentType.Weapon: return "⚔️";
                case EquipmentType.Armor: return "🛡️";
                case EquipmentType.Accessory: return "💍";
                default: return "❓";
            }
        }
        
        /// <summary>
        /// 获取属性描述
        /// </summary>
        public string GetStatsDescription()
        {
            List<string> stats = new List<string>();
            
            if (Attack > 0) stats.Add($"攻击 +{Attack}");
            if (Defense > 0) stats.Add($"防御 +{Defense}");
            if (MaxHP > 0) stats.Add($"生命 +{MaxHP}");
            if (CritRate > 0) stats.Add($"暴击 +{CritRate}%");
            if (CritDamage > 0) stats.Add($"暴伤 +{CritDamage}%");
            if (Block > 0) stats.Add($"格挡 +{Block}");
            
            if (SpecialEffect != SpecialEffect.None)
            {
                stats.Add($"特效: {GetSpecialEffectName()}");
            }
            
            return string.Join("\n", stats);
        }
        
        private string GetSpecialEffectName()
        {
            switch(SpecialEffect)
            {
                case SpecialEffect.LifeSteal: return "吸血";
                case SpecialEffect.Reflect: return "反射";
                case SpecialEffect.Poison: return "中毒";
                case SpecialEffect.Freeze: return "冰冻";
                case SpecialEffect.Dodge: return "闪避";
                case SpecialEffect.Fire: return "火焰";
                case SpecialEffect.Ice: return "冰霜";
                case SpecialEffect.Lightning: return "雷电";
                case SpecialEffect.CriticalBoost: return "暴击伤害";
                case SpecialEffect.DoubleAttack: return "双重攻击";
                default: return "无";
            }
        }
        
        /// <summary>
        /// 克隆装备
        /// </summary>
        public Equipment Clone()
        {
            return new Equipment
            {
                ID = this.ID,
                Name = this.Name,
                Type = this.Type,
                Rarity = this.Rarity,
                Attack = this.Attack,
                Defense = this.Defense,
                MaxHP = this.MaxHP,
                CritRate = this.CritRate,
                CritDamage = this.CritDamage,
                Block = this.Block,
                SpecialEffect = this.SpecialEffect,
                SpecialEffectChance = this.SpecialEffectChance,
                Price = this.Price,
                Description = this.Description
            };
        }
    }

    /// <summary>
    /// 装备槽位
    /// </summary>
    [System.Serializable]
    public class EquipmentSlot
    {
        public EquipmentType Type;
        public Equipment EquippedItem;
        
        public EquipmentSlot(EquipmentType type)
        {
            Type = type;
            EquippedItem = null;
        }
        
        public bool IsEmpty => EquippedItem == null;
    }

    /// <summary>
    /// 装备系统 - 管理玩家装备
    /// </summary>
    public class EquipmentSystem : MonoBehaviour
    {
        private static EquipmentSystem _instance;
        public static EquipmentSystem Instance => _instance;
        
        // 装备槽位
        private EquipmentSlot[] equipmentSlots;
        
        // 背包
        private List<Equipment> inventory = new List<Equipment>();
        private int inventorySize = 20;
        
        // 最大槽位
        private int maxWeaponSlots = 1;
        private int maxArmorSlots = 1;
        private int maxAccessorySlots = 3;
        
        // 装备数据库
        private List<Equipment> equipmentDatabase = new List<Equipment>();
        
        void Awake()
        {
            _instance = this;
            InitializeDatabase();
            InitializeSlots();
        }
        
        /// <summary>
        /// 初始化装备槽位
        /// </summary>
        private void InitializeSlots()
        {
            equipmentSlots = new EquipmentSlot[]
            {
                new EquipmentSlot(EquipmentType.Weapon),
                new EquipmentSlot(EquipmentType.Armor),
                new EquipmentSlot(EquipmentType.Accessory),
                new EquipmentSlot(EquipmentType.Accessory),
                new EquipmentSlot(EquipmentType.Accessory),
            };
        }
        
        /// <summary>
        /// 初始化装备数据库
        /// </summary>
        private void InitializeDatabase()
        {
            // 武器
            equipmentDatabase.Add(new Equipment("weapon_001", "木剑", EquipmentType.Weapon, Rarity.Common, 50) 
            { Attack = 3, Description = "最简单的木质剑" });
            equipmentDatabase.Add(new Equipment("weapon_002", "铁剑", EquipmentType.Weapon, Rarity.Common, 80) 
            { Attack = 5, Description = "普通的铁制剑" });
            equipmentDatabase.Add(new Equipment("weapon_003", "钢剑", EquipmentType.Weapon, Rarity.Rare, 150) 
            { Attack = 8, CritRate = 5, Description = "优质的钢材打造" });
            equipmentDatabase.Add(new Equipment("weapon_004", "魔法剑", EquipmentType.Weapon, Rarity.Epic, 350) 
            { Attack = 12, CritRate = 10, SpecialEffect = SpecialEffect.Fire, SpecialEffectChance = 0.3f, Description = "附有火焰魔力的剑" });
            equipmentDatabase.Add(new Equipment("weapon_005", "龙鳞剑", EquipmentType.Weapon, Rarity.Legendary, 800) 
            { Attack = 20, CritRate = 15, CritDamage = 50, Description = "用龙鳞打造的传奇武器" });
            
            // 护甲
            equipmentDatabase.Add(new Equipment("armor_001", "布衣", EquipmentType.Armor, Rarity.Common, 50) 
            { Defense = 2, MaxHP = 10, Description = "简单的布制衣服" });
            equipmentDatabase.Add(new Equipment("armor_002", "皮甲", EquipmentType.Armor, Rarity.Common, 80) 
            { Defense = 4, MaxHP = 20, Description = "动物皮制作的护甲" });
            equipmentDatabase.Add(new Equipment("armor_003", "锁甲", EquipmentType.Armor, Rarity.Rare, 150) 
            { Defense = 8, MaxHP = 35, Block = 3, Description = "金属锁子甲" });
            equipmentDatabase.Add(new Equipment("armor_004", "秘银甲", EquipmentType.Armor, Rarity.Epic, 350) 
            { Defense = 15, MaxHP = 60, Block = 5, SpecialEffect = SpecialEffect.Dodge, SpecialEffectChance = 0.15f, Description = "秘银打造的精致护甲" });
            equipmentDatabase.Add(new Equipment("armor_005", "龙鳞甲", EquipmentType.Armor, Rarity.Legendary, 800) 
            { Defense = 25, MaxHP = 100, Block = 10, SpecialEffect = SpecialEffect.Reflect, SpecialEffectChance = 0.2f, Description = "龙鳞制成的顶级护甲" });
            
            // 饰品
            equipmentDatabase.Add(new Equipment("acc_001", "力量戒指", EquipmentType.Accessory, Rarity.Common, 60) 
            { Attack = 3, Description = "增加攻击力的戒指" });
            equipmentDatabase.Add(new Equipment("acc_002", "防御戒指", EquipmentType.Accessory, Rarity.Common, 60) 
            { Defense = 3, Description = "增加防御力的戒指" });
            equipmentDatabase.Add(new Equipment("acc_003", "生命戒指", EquipmentType.Accessory, Rarity.Common, 60) 
            { MaxHP = 30, Description = "增加生命值的戒指" });
            equipmentDatabase.Add(new Equipment("acc_004", "敏捷戒指", EquipmentType.Accessory, Rarity.Rare, 120) 
            { CritRate = 8, Description = "增加暴击率的戒指" });
            equipmentDatabase.Add(new Equipment("acc_005", "吸血戒指", EquipmentType.Accessory, Rarity.Epic, 300) 
            { Attack = 5, SpecialEffect = SpecialEffect.LifeSteal, SpecialEffectChance = 0.2f, Description = "汲取敌人生命" });
            equipmentDatabase.Add(new Equipment("acc_006", "闪电戒指", EquipmentType.Accessory, Rarity.Legendary, 700) 
            { Attack = 10, CritRate = 10, SpecialEffect = SpecialEffect.Lightning, SpecialEffectChance = 0.25f, Description = "蕴含雷电之力的戒指" });
        }
        
        /// <summary>
        /// 装备物品
        /// </summary>
        public bool Equip(Equipment equipment)
        {
            // 找到对应类型的空槽位
            EquipmentSlot slot = GetFirstEmptySlot(equipment.Type);
            
            if (slot == null)
            {
                // 槽位已满，替换现有装备
                slot = GetFirstSlot(equipment.Type);
                if (slot != null)
                {
                    // 卸下现有装备到背包
                    if (slot.EquippedItem != null)
                    {
                        AddToInventory(slot.EquippedItem);
                    }
                }
                else
                {
                    Debug.LogWarning($"没有对应的装备槽位: {equipment.Type}");
                    return false;
                }
            }
            
            // 从背包移除
            RemoveFromInventory(equipment);
            
            // 装备
            slot.EquippedItem = equipment;
            
            // 更新玩家属性
            UpdatePlayerStats();
            
            Debug.Log($"装备成功: {equipment.Name}");
            return true;
        }
        
        /// <summary>
        /// 卸下装备
        /// </summary>
        public bool Unequip(EquipmentType type)
        {
            EquipmentSlot slot = GetFirstSlot(type);
            
            if (slot == null || slot.IsEmpty)
            {
                return false;
            }
            
            Equipment unequipped = slot.EquippedItem;
            
            if (AddToInventory(unequipped))
            {
                slot.EquippedItem = null;
                UpdatePlayerStats();
                Debug.Log($"卸下装备: {unequipped.Name}");
                return true;
            }
            
            return false;
        }
        
        /// <summary>
        /// 获取第一个空槽位
        /// </summary>
        private EquipmentSlot GetFirstEmptySlot(EquipmentType type)
        {
            foreach (var slot in equipmentSlots)
            {
                if (slot.Type == type && slot.IsEmpty)
                {
                    return slot;
                }
            }
            return null;
        }
        
        /// <summary>
        /// 获取第一个对应类型的槽位
        /// </summary>
        private EquipmentSlot GetFirstSlot(EquipmentType type)
        {
            foreach (var slot in equipmentSlots)
            {
                if (slot.Type == type)
                {
                    return slot;
                }
            }
            return null;
        }
        
        /// <summary>
        /// 添加到背包
        /// </summary>
        public bool AddToInventory(Equipment equipment)
        {
            if (inventory.Count >= inventorySize)
            {
                Debug.LogWarning("背包已满!");
                return false;
            }
            
            inventory.Add(equipment);
            return true;
        }
        
        /// <summary>
        /// 从背包移除
        /// </summary>
        public bool RemoveFromInventory(Equipment equipment)
        {
            return inventory.Remove(equipment);
        }
        
        /// <summary>
        /// 获取背包
        /// </summary>
        public List<Equipment> GetInventory()
        {
            return inventory;
        }
        
        /// <summary>
        /// 获取已装备的物品
        /// </summary>
        public Equipment[] GetEquippedItems()
        {
            List<Equipment> equipped = new List<Equipment>();
            
            foreach (var slot in equipmentSlots)
            {
                if (!slot.IsEmpty)
                {
                    equipped.Add(slot.EquippedItem);
                }
            }
            
            return equipped.ToArray();
        }
        
        /// <summary>
        /// 获取空格子数
        /// </summary>
        public int GetEmptySlots()
        {
            return inventorySize - inventory.Count;
        }
        
        /// <summary>
        /// 获取总攻击力
        /// </summary>
        public int GetTotalAttack()
        {
            int total = 0;
            foreach (var slot in equipmentSlots)
            {
                if (!slot.IsEmpty)
                {
                    total += slot.EquippedItem.Attack;
                }
            }
            return total;
        }
        
        /// <summary>
        /// 获取总防御力
        /// </summary>
        public int GetTotalDefense()
        {
            int total = 0;
            foreach (var slot in equipmentSlots)
            {
                if (!slot.IsEmpty)
                {
                    total += slot.EquippedItem.Defense;
                }
            }
            return total;
        }
        
        /// <summary>
        /// 获取总生命加成
        /// </summary>
        public int GetTotalMaxHP()
        {
            int total = 0;
            foreach (var slot in equipmentSlots)
            {
                if (!slot.IsEmpty)
                {
                    total += slot.EquippedItem.MaxHP;
                }
            }
            return total;
        }
        
        /// <summary>
        /// 获取总暴击率
        /// </summary>
        public float GetTotalCritRate()
        {
            float total = 0;
            foreach (var slot in equipmentSlots)
            {
                if (!slot.IsEmpty)
                {
                    total += slot.EquippedItem.CritRate;
                }
            }
            return total;
        }
        
        /// <summary>
        /// 更新玩家属性
        /// </summary>
        private void UpdatePlayerStats()
        {
            if (Player.Instance == null) return;
            
            Player player = Player.Instance;
            
            // 这里应该调用 Player 的装备加成方法
            // player.UpdateEquipmentBonus();
        }
        
        /// <summary>
        /// 生成随机装备
        /// </summary>
        public Equipment GenerateRandomEquipment(int level)
        {
            // 根据等级和稀有度随机生成
            float roll = Random.value;
            Rarity rarity;
            
            if (roll < 0.6f) rarity = Rarity.Common;
            else if (roll < 0.85f) rarity = Rarity.Rare;
            else if (roll < 0.95f) rarity = Rarity.Epic;
            else rarity = Rarity.Legendary;
            
            // 根据类型随机选择
            EquipmentType[] types = { EquipmentType.Weapon, EquipmentType.Armor, EquipmentType.Accessory };
            EquipmentType type = types[Random.Range(0, types.Length)];
            
            // 从数据库中选择
            List<Equipment> candidates = equipmentDatabase.FindAll(e => e.Type == type && e.Rarity == rarity);
            
            if (candidates.Count > 0)
            {
                return candidates[Random.Range(0, candidates.Count)].Clone();
            }
            
            // 如果没有匹配的，返回默认
            return equipmentDatabase[0].Clone();
        }
    }
}
