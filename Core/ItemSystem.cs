using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 道具类型
    /// </summary>
    public enum ItemType
    {
        Consumable,  // 消耗品
        Key,        // 钥匙/信物
        Material,   // 材料
        Special     // 特殊物品
    }

    /// <summary>
    /// 道具类
    /// </summary>
    [System.Serializable]
    public class Item
    {
        public string ID;
        public string Name;
        public ItemType Type;
        public int Count;          // 数量
        public int MaxStack;       // 最大堆叠数
        public int Price;         // 价格
        public bool IsUsableInBattle;    // 战斗内可用
        public bool IsUsableOutsideBattle; // 战斗外可用
        
        // 消耗品效果
        public int HPHeal;
        public int EnergyHeal;
        public int AttackBuff;
        public int DefenseBuff;
        public int BuffDuration;  // buff持续回合
        
        // 特殊效果
        public SpecialEffect Effect;
        
        public string Description;
        
        public Item() { }
        
        public Item(string id, string name, ItemType type, int price)
        {
            ID = id;
            Name = name;
            Type = type;
            Price = price;
            Count = 1;
            MaxStack = GetDefaultMaxStack(type);
            IsUsableInBattle = type == ItemType.Consumable;
            IsUsableOutsideBattle = true;
        }
        
        private int GetDefaultMaxStack(ItemType type)
        {
            switch(type)
            {
                case ItemType.Consumable: return 99;
                case ItemType.Material: return 99;
                case ItemType.Key: return 1;
                case ItemType.Special: return 1;
                default: return 1;
            }
        }
        
        /// <summary>
        /// 获取图标
        /// </summary>
        public string GetIcon()
        {
            switch(Type)
            {
                case ItemType.Consumable: return "🧪";
                case ItemType.Key: return "🔑";
                case ItemType.Material: return "💎";
                case ItemType.Special: return "⭐";
                default: return "❓";
            }
        }
        
        /// <summary>
        /// 获取描述
        /// </summary>
        public string GetDescription()
        {
            List<string> effects = new List<string>();
            
            if (HPHeal > 0) effects.Add($"恢复{HPHeal}HP");
            if (EnergyHeal > 0) effects.Add($"恢复{EnergyHeal}能量");
            if (AttackBuff > 0) effects.Add($"攻击+{AttackBuff} ({BuffDuration}回合)");
            if (DefenseBuff > 0) effects.Add($"防御+{DefenseBuff} ({BuffDuration}回合)");
            if (Effect != SpecialEffect.None) effects.Add($"特殊效果");
            
            if (effects.Count == 0 && !string.IsNullOrEmpty(Description))
            {
                return Description;
            }
            
            return string.Join(", ", effects);
        }
        
        /// <summary>
        /// 克隆道具
        /// </summary>
        public Item Clone()
        {
            return new Item
            {
                ID = this.ID,
                Name = this.Name,
                Type = this.Type,
                Count = this.Count,
                MaxStack = this.MaxStack,
                Price = this.Price,
                IsUsableInBattle = this.IsUsableInBattle,
                IsUsableOutsideBattle = this.IsUsableOutsideBattle,
                HPHeal = this.HPHeal,
                EnergyHeal = this.EnergyHeal,
                AttackBuff = this.AttackBuff,
                DefenseBuff = this.DefenseBuff,
                BuffDuration = this.BuffDuration,
                Effect = this.Effect,
                Description = this.Description
            };
        }
        
        /// <summary>
        /// 是否可以堆叠
        /// </summary>
        public bool CanStackWith(Item other)
        {
            return ID == other.ID && Count < MaxStack;
        }
    }

    /// <summary>
    /// 道具系统 - 管理背包和道具
    /// </summary>
    public class ItemSystem : MonoBehaviour
    {
        private static ItemSystem _instance;
        public static ItemSystem Instance => _instance;
        
        // 背包
        private Dictionary<string, Item> inventory = new Dictionary<string, Item>();
        private int inventorySize = 20;
        
        // 道具数据库
        private List<Item> itemDatabase = new List<Item>();
        
        // 自动使用道具
        private bool autoUseHPItem = true;
        private int autoUseHPThreshold = 30;  // HP低于30%时自动使用
        
        void Awake()
        {
            _instance = this;
            InitializeDatabase();
        }
        
        /// <summary>
        /// 初始化道具数据库
        /// </summary>
        private void InitializeDatabase()
        {
            // 消耗品 - 生命药水
            itemDatabase.Add(new Item("item_hp_01", "生命药水", ItemType.Consumable, 30)
            { 
                HPHeal = 20, 
                Description = "恢复20点生命值",
                IsUsableInBattle = true 
            });
            itemDatabase.Add(new Item("item_hp_02", "生命药水(大)", ItemType.Consumable, 70)
            { 
                HPHeal = 50, 
                Description = "恢复50点生命值",
                IsUsableInBattle = true 
            });
            itemDatabase.Add(new Item("item_hp_03", "生命药水(超级)", ItemType.Consumable, 150)
            { 
                HPHeal = 100, 
                Description = "恢复100点生命值",
                IsUsableInBattle = true 
            });
            
            // 消耗品 - 能量药水
            itemDatabase.Add(new Item("item_energy_01", "能量药水", ItemType.Consumable, 30)
            { 
                EnergyHeal = 10, 
                Description = "恢复10点能量",
                IsUsableInBattle = true 
            });
            itemDatabase.Add(new Item("item_energy_02", "能量药水(大)", ItemType.Consumable, 60)
            { 
                EnergyHeal = 25, 
                Description = "恢复25点能量",
                IsUsableInBattle = true 
            });
            
            // 消耗品 - Buff药水
            itemDatabase.Add(new Item("item_buff_atk", "力量药水", ItemType.Consumable, 50)
            { 
                AttackBuff = 3, 
                BuffDuration = 3,
                Description = "攻击+3，持续3回合",
                IsUsableInBattle = true 
            });
            itemDatabase.Add(new Item("item_buff_def", "防御药水", ItemType.Consumable, 50)
            { 
                DefenseBuff = 3, 
                BuffDuration = 3,
                Description = "防御+3，持续3回合",
                IsUsableInBattle = true 
            });
            itemDatabase.Add(new Item("item_buff_crit", "暴击药水", ItemType.Consumable, 80)
            { 
                Effect = SpecialEffect.CriticalBoost,
                BuffDuration = 2,
                Description = "暴击率+50%，持续2回合",
                IsUsableInBattle = true 
            });
            
            // 消耗品 - 解毒/净化
            itemDatabase.Add(new Item("item_cure", "解毒药", ItemType.Consumable, 40)
            { 
                Description = "解除中毒状态",
                IsUsableInBattle = true 
            });
            
            // 消耗品 - 复活
            itemDatabase.Add(new Item("item_revive", "复活药", ItemType.Consumable, 100)
            { 
                Description = "战斗开始时自动复活1次",
                IsUsableInBattle = false,
                IsUsableOutsideBattle = true
            });
            
            // 钥匙/信物
            itemDatabase.Add(new Item("key_boss_01", "密钥碎片", ItemType.Key, 0)
            { 
                Description = "用于开启BOSS区域的钥匙",
                MaxStack = 5
            });
            itemDatabase.Add(new Item("key_secret_01", "神秘钥匙", ItemType.Key, 0)
            { 
                Description = "用于开启隐藏房间",
                MaxStack = 1
            });
            itemDatabase.Add(new Item("key_event_01", "机关钥匙", ItemType.Key, 0)
            { 
                Description = "用于解锁机关",
                MaxStack = 3
            });
            
            // 材料
            itemDatabase.Add(new Item("mat_gem_01", "能量宝石", ItemType.Material, 100)
            { 
                Description = "用于合成装备",
                MaxStack = 99
            });
            itemDatabase.Add(new Item("mat_ore_01", "铁矿", ItemType.Material, 50)
            { 
                Description = "用于合成装备",
                MaxStack = 99
            });
            itemDatabase.Add(new Item("mat_ore_02", "秘银", ItemType.Material, 150)
            { 
                Description = "用于合成高级装备",
                MaxStack = 99
            });
            itemDatabase.Add(new Item("mat_herb_01", "药草", ItemType.Material, 20)
            { 
                Description = "用于合成药水",
                MaxStack = 99
            });
        }
        
        /// <summary>
        /// 添加道具
        /// </summary>
        public bool AddItem(Item item)
        {
            if (inventory.Count >= inventorySize)
            {
                // 尝试堆叠
                if (inventory.ContainsKey(item.ID) && inventory[item.ID].CanStackWith(item))
                {
                    int canAdd = inventory[item.ID].MaxStack - inventory[item.ID].Count;
                    int addCount = Mathf.Min(canAdd, item.Count);
                    
                    inventory[item.ID].Count += addCount;
                    
                    if (addCount < item.Count)
                    {
                        Debug.LogWarning($"背包已满，部分{item.Name}无法添加");
                    }
                    return true;
                }
                
                Debug.LogWarning("背包已满!");
                return false;
            }
            
            // 添加新道具
            inventory[item.ID] = item;
            Debug.Log($"获得道具: {item.Name} x{item.Count}");
            return true;
        }
        
        /// <summary>
        /// 添加道具(通过ID)
        /// </summary>
        public bool AddItem(string itemId, int count = 1)
        {
            Item dbItem = itemDatabase.Find(i => i.ID == itemId);
            
            if (dbItem == null)
            {
                Debug.LogWarning($"道具不存在: {itemId}");
                return false;
            }
            
            Item newItem = dbItem.Clone();
            newItem.Count = count;
            
            return AddItem(newItem);
        }
        
        /// <summary>
        /// 移除道具
        /// </summary>
        public bool RemoveItem(string itemId, int count = 1)
        {
            if (!inventory.ContainsKey(itemId))
            {
                return false;
            }
            
            Item item = inventory[itemId];
            
            if (item.Count < count)
            {
                Debug.LogWarning($"道具数量不足: {item.Name}");
                return false;
            }
            
            item.Count -= count;
            
            if (item.Count <= 0)
            {
                inventory.Remove(itemId);
            }
            
            return true;
        }
        
        /// <summary>
        /// 使用道具
        /// </summary>
        public bool UseItem(string itemId, bool inBattle = false)
        {
            if (!inventory.ContainsKey(itemId))
            {
                Debug.LogWarning($"背包中没有此道具: {itemId}");
                return false;
            }
            
            Item item = inventory[itemId];
            
            // 检查是否可以在当前场景使用
            if (inBattle && !item.IsUsableInBattle)
            {
                Debug.LogWarning($"此道具不能在战斗中使用: {item.Name}");
                return false;
            }
            
            if (!inBattle && !item.IsUsableOutsideBattle)
            {
                Debug.LogWarning($"此道具不能在战斗外使用: {item.Name}");
                return false;
            }
            
            // 应用效果
            ApplyItemEffect(item, inBattle);
            
            // 消耗数量
            RemoveItem(itemId, 1);
            
            return true;
        }
        
        /// <summary>
        /// 应用道具效果
        /// </summary>
        private void ApplyItemEffect(Item item, bool inBattle)
        {
            if (Player.Instance == null) return;
            
            Player player = Player.Instance;
            
            // 生命恢复
            if (item.HPHeal > 0)
            {
                player.Heal(item.HPHeal);
                Debug.Log($"恢复 {item.HPHeal} 点生命!");
            }
            
            // 能量恢复
            if (item.EnergyHeal > 0)
            {
                // player.AddEnergy(item.EnergyHeal);
                Debug.Log($"恢复 {item.EnergyHeal} 点能量!");
            }
            
            // Buff效果
            if (item.AttackBuff > 0)
            {
                // player.AddAttackBuff(item.AttackBuff, item.BuffDuration);
                Debug.Log($"攻击 +{item.AttackBuff}，持续 {item.BuffDuration} 回合!");
            }
            
            if (item.DefenseBuff > 0)
            {
                // player.AddDefenseBuff(item.DefenseBuff, item.BuffDuration);
                Debug.Log($"防御 +{item.DefenseBuff}，持续 {item.BuffDuration} 回合!");
            }
            
            // 特殊效果
            if (item.Effect != SpecialEffect.None)
            {
                // player.AddSpecialEffect(item.Effect);
                Debug.Log($"获得特殊效果: {item.Effect}!");
            }
        }
        
        /// <summary>
        /// 检查并自动使用道具
        /// </summary>
        public void CheckAutoUseItems()
        {
            if (!autoUseHPItem || Player.Instance == null) return;
            
            int currentHP = Player.Instance.HP;
            int maxHP = Player.Instance.MaxHP;
            float hpPercent = (float)currentHP / maxHP * 100;
            
            // HP低于阈值时自动使用药水
            if (hpPercent < autoUseHPThreshold)
            {
                // 查找背包中的药水
                foreach (var kvp in inventory)
                {
                    if (kvp.Value.HPHeal > 0 && kvp.Value.IsUsableInBattle)
                    {
                        UseItem(kvp.Key, true);
                        Debug.Log("自动使用药水!");
                        break;
                    }
                }
            }
        }
        
        /// <summary>
        /// 获取背包
        /// </summary>
        public Dictionary<string, Item> GetInventory()
        {
            return inventory;
        }
        
        /// <summary>
        /// 获取道具
        /// </summary>
        public Item GetItem(string itemId)
        {
            return inventory.ContainsKey(itemId) ? inventory[itemId] : null;
        }
        
        /// <summary>
        /// 获取空格子数
        /// </summary>
        public int GetEmptySlots()
        {
            return inventorySize - inventory.Count;
        }
        
        /// <summary>
        /// 获取背包数量
        /// </summary>
        public int GetItemCount()
        {
            return inventory.Count;
        }
        
        /// <summary>
        /// 是否有道具
        /// </summary>
        public bool HasItem(string itemId)
        {
            return inventory.ContainsKey(itemId);
        }
        
        /// <summary>
        /// 获取道具列表(按类型)
        /// </summary>
        public List<Item> GetItemsByType(ItemType type)
        {
            List<Item> result = new List<Item>();
            
            foreach (var kvp in inventory)
            {
                if (kvp.Value.Type == type)
                {
                    result.Add(kvp.Value);
                }
            }
            
            return result;
        }
        
        /// <summary>
        /// 出售道具
        /// </summary>
        public bool SellItem(string itemId, int count = 1)
        {
            if (!inventory.ContainsKey(itemId))
            {
                return false;
            }
            
            Item item = inventory[itemId];
            int sellPrice = (item.Price / 2) * count;  // 半价出售
            
            RemoveItem(itemId, count);
            
            // 给玩家金币
            // Player.Instance.AddGold(sellPrice);
            
            Debug.Log($"出售 {item.Name} x{count}，获得 {sellPrice} 金币");
            return true;
        }
        
        /// <summary>
        /// 清空背包
        /// </summary>
        public void ClearInventory()
        {
            inventory.Clear();
            Debug.Log("背包已清空");
        }
    }
}
