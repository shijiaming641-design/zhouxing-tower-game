using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 商店类型
    /// </summary>
    public enum ShopType
    {
        Equipment,    // 装备商店
        Card,        // 卡牌商店
        Item,        // 道具商店
        Mystery,     // 神秘商人
        BlackMarket  // 黑市
    }

    /// <summary>
    /// 稀有度
    /// </summary>
    public enum Rarity
    {
        Common = 1,     // 普通(白色)
        Rare = 2,       // 精良(蓝色)
        Epic = 3,      // 稀有(紫色)
        Legendary = 4   // 传说(金色)
    }

    /// <summary>
    /// 商品基类
    /// </summary>
    [System.Serializable]
    public class ShopItem
    {
        public string ID;
        public string Name;
        public int Price;
        public int Stock = -1;  // -1表示无限
        public string Description;
        
        public virtual string GetDisplayInfo()
        {
            return $"{Name} - {Price}金币";
        }
    }

    /// <summary>
    /// 装备商品
    /// </summary>
    [System.Serializable]
    public class EquipmentShopItem : ShopItem
    {
        public Rarity Rarity;
        public int Attack;
        public int Defense;
        public int MaxHP;
        public float CritRate;
        
        public override string GetDisplayInfo()
        {
            string info = $"{Name} [{GetRarityColor()}{GetRarityName()}{ColorReset}] - {Price}金币\n";
            
            if (Attack > 0) info += $"  攻击: +{Attack}\n";
            if (Defense > 0) info += $"  防御: +{Defense}\n";
            if (MaxHP > 0) info += $"  生命: +{MaxHP}\n";
            if (CritRate > 0) info += $"  暴击: +{CritRate}%\n";
            
            return info;
        }
        
        private string GetRarityColor()
        {
            switch(Rarity)
            {
                case Rarity.Common: return "<color=white>";
                case Rarity.Rare: return "<color=blue>";
                case Rarity.Epic: return "<color=purple>";
                case Rarity.Legendary: return "<color=yellow>";
                default: return "";
            }
        }
        
        private string GetRarityName()
        {
            return Rarity.ToString();
        }
        
        private string ColorReset()
        {
            return "</color>";
        }
    }

    /// <summary>
    /// 道具商品
    /// </summary>
    [System.Serializable]
    public class ItemShopItem : ShopItem
    {
        public int HPHeal;
        public int EnergyHeal;
        
        public override string GetDisplayInfo()
        {
            string info = $"{Name} - {Price}金币\n";
            
            if (HPHeal > 0) info += $"  恢复生命: +{HPHeal}\n";
            if (EnergyHeal > 0) info += $"  恢复能量: +{EnergyHeal}\n";
            
            return info;
        }
    }

    /// <summary>
    /// 商店系统 - 负责商店商品管理
    /// </summary>
    public class ShopSystem : MonoBehaviour
    {
        private static ShopSystem _instance;
        public static ShopSystem Instance => _instance;
        
        // 当前商店类型
        private ShopType currentShopType;
        
        // 当前商品列表
        private List<ShopItem> currentItems = new List<ShopItem>();
        
        // 刷新次数
        private int refreshCount = 0;
        
        // 玩家金币
        private int playerGold = 500;
        
        // 商品数据库
        private List<EquipmentShopItem> equipmentDatabase = new List<EquipmentShopItem>();
        private List<ItemShopItem> itemDatabase = new List<ItemShopItem>();
        
        void Awake()
        {
            _instance = this;
            InitializeDatabase();
        }
        
        /// <summary>
        /// 初始化商品数据库
        /// </summary>
        private void InitializeDatabase()
        {
            // 装备数据库
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "weapon_001", Name = "铁剑", Price = 50, Rarity = Rarity.Common,
                Attack = 3, Description = "一把普通的铁剑"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "weapon_002", Name = "钢剑", Price = 120, Rarity = Rarity.Rare,
                Attack = 6, Description = "一把不错的钢剑"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "weapon_003", Name = "魔法剑", Price = 300, Rarity = Rarity.Epic,
                Attack = 10, CritRate = 10f, Description = "附有魔法的剑"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "weapon_004", Name = "龙鳞剑", Price = 800, Rarity = Rarity.Legendary,
                Attack = 18, CritRate = 20f, Description = "用龙鳞打造的传奇武器"
            });
            
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "armor_001", Name = "皮甲", Price = 50, Rarity = Rarity.Common,
                Defense = 2, MaxHP = 10, Description = "简单的皮甲"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "armor_002", Name = "锁甲", Price = 120, Rarity = Rarity.Rare,
                Defense = 5, MaxHP = 20, Description = "不错的锁甲"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "armor_003", Name = "秘银甲", Price = 350, Rarity = Rarity.Epic,
                Defense = 10, MaxHP = 40, Description = "秘银打造的护甲"
            });
            
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "acc_001", Name = "力量戒指", Price = 100, Rarity = Rarity.Common,
                Attack = 2, Description = "增加攻击力的戒指"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "acc_002", Name = "守护戒指", Price = 100, Rarity = Rarity.Common,
                Defense = 2, Description = "增加防御力的戒指"
            });
            equipmentDatabase.Add(new EquipmentShopItem 
            { 
                ID = "acc_003", Name = "幸运戒指", Price = 200, Rarity = Rarity.Rare,
                CritRate = 8f, Description = "增加暴击率的戒指"
            });
            
            // 道具数据库
            itemDatabase.Add(new ItemShopItem 
            { 
                ID = "item_hp_01", Name = "生命药水", Price = 30, 
                HPHeal = 20, Description = "恢复20点生命"
            });
            itemDatabase.Add(new ItemShopItem 
            { 
                ID = "item_hp_02", Name = "生命药水(大)", Price = 70, 
                HPHeal = 50, Description = "恢复50点生命"
            });
            itemDatabase.Add(new ItemShopItem 
            { 
                ID = "item_energy_01", Name = "能量药水", Price = 30, 
                EnergyHeal = 10, Description = "恢复10点能量"
            });
            itemDatabase.Add(new ItemShopItem 
            { 
                ID = "item_atk_01", Name = "力量药水", Price = 50, 
                Description = "临时增加攻击力"
            });
            itemDatabase.Add(new ItemShopItem 
            { 
                ID = "item_def_01", Name = "防御药水", Price = 50, 
                Description = "临时增加防御力"
            });
        }
        
        /// <summary>
        /// 打开商店
        /// </summary>
        public void OpenShop(ShopType type)
        {
            currentShopType = type;
            GenerateItems();
            Debug.Log($"商店已打开: {type}");
        }
        
        /// <summary>
        /// 生成商品
        /// </summary>
        private void GenerateItems()
        {
            currentItems.Clear();
            
            switch(currentShopType)
            {
                case ShopType.Equipment:
                    GenerateEquipmentShop();
                    break;
                case ShopType.Item:
                    GenerateItemShop();
                    break;
                case ShopType.Mystery:
                    GenerateMysteryShop();
                    break;
            }
        }
        
        /// <summary>
        /// 生成装备商店商品
        /// </summary>
        private void GenerateEquipmentShop()
        {
            int itemCount = Random.Range(4, 7);
            
            // 根据当前层数调整商品等级
            int playerLevel = Player.Instance != null ? Player.Instance.Level : 1;
            
            for (int i = 0; i < itemCount; i++)
            {
                // 随机选择装备类型
                float roll = Random.value;
                List<EquipmentShopItem> candidates = new List<EquipmentShopItem>();
                
                if (roll < 0.6f)
                {
                    // 60% 普通装备
                    candidates = equipmentDatabase.FindAll(e => e.Rarity == Rarity.Common);
                }
                else if (roll < 0.85f)
                {
                    // 25% 精良装备
                    candidates = equipmentDatabase.FindAll(e => e.Rarity == Rarity.Rare);
                }
                else if (roll < 0.95f)
                {
                    // 10% 稀有装备
                    candidates = equipmentDatabase.FindAll(e => e.Rarity == Rarity.Epic);
                }
                else
                {
                    // 5% 传说装备
                    candidates = equipmentDatabase.FindAll(e => e.Rarity == Rarity.Legendary);
                }
                
                if (candidates.Count > 0)
                {
                    EquipmentShopItem selected = candidates[Random.Range(0, candidates.Count)];
                    currentItems.Add(new EquipmentShopItem 
                    {
                        ID = selected.ID + "_" + i,
                        Name = selected.Name,
                        Price = selected.Price,
                        Rarity = selected.Rarity,
                        Attack = selected.Attack,
                        Defense = selected.Defense,
                        MaxHP = selected.MaxHP,
                        CritRate = selected.CritRate,
                        Description = selected.Description
                    });
                }
            }
        }
        
        /// <summary>
        /// 生成道具商店商品
        /// </summary>
        private void GenerateItemShop()
        {
            int itemCount = Random.Range(4, 7);
            
            for (int i = 0; i < itemCount; i++)
            {
                if (itemDatabase.Count > 0)
                {
                    ItemShopItem selected = itemDatabase[Random.Range(0, itemDatabase.Count)];
                    currentItems.Add(new ItemShopItem 
                    {
                        ID = selected.ID + "_" + i,
                        Name = selected.Name,
                        Price = selected.Price,
                        HPHeal = selected.HPHeal,
                        EnergyHeal = selected.EnergyHeal,
                        Description = selected.Description
                    });
                }
            }
        }
        
        /// <summary>
        /// 生成神秘商店商品
        /// </summary>
        private void GenerateMysteryShop()
        {
            // 神秘商店有折扣，可能有特殊商品
            GenerateEquipmentShop();
            
            // 对所有商品打9折
            foreach (var item in currentItems)
            {
                item.Price = Mathf.RoundToInt(item.Price * 0.9f);
            }
        }
        
        /// <summary>
        /// 购买商品
        /// </summary>
        public bool BuyItem(string itemId)
        {
            ShopItem item = currentItems.Find(i => i.ID == itemId);
            
            if (item == null)
            {
                Debug.LogWarning($"商品不存在: {itemId}");
                return false;
            }
            
            if (playerGold < item.Price)
            {
                Debug.LogWarning("金币不足!");
                return false;
            }
            
            if (item.Stock == 0)
            {
                Debug.LogWarning("商品已售罄!");
                return false;
            }
            
            // 扣除金币
            playerGold -= item.Price;
            
            // 减少库存
            if (item.Stock > 0)
            {
                item.Stock--;
            }
            
            // 添加到玩家背包
            AddItemToPlayer(item);
            
            Debug.Log($"购买成功: {item.Name}");
            return true;
        }
        
        /// <summary>
        /// 出售商品给商店
        /// </summary>
        public bool SellItem(string itemId, int sellPrice)
        {
            if (sellPrice <= 0) return false;
            
            playerGold += sellPrice;
            Debug.Log($"出售成功: 获得 {sellPrice} 金币");
            return true;
        }
        
        /// <summary>
        /// 刷新商品
        /// </summary>
        public void Refresh()
        {
            int refreshCost = 50 * (refreshCount + 1);
            
            if (playerGold < refreshCost)
            {
                Debug.LogWarning($"刷新费用不足: 需要 {refreshCost} 金币");
                return;
            }
            
            playerGold -= refreshCost;
            refreshCount++;
            
            GenerateItems();
            Debug.Log($"商品已刷新，消耗 {refreshCost} 金币");
        }
        
        /// <summary>
        /// 获取当前商品列表
        /// </summary>
        public List<ShopItem> GetItems()
        {
            return currentItems;
        }
        
        /// <summary>
        /// 获取玩家金币
        /// </summary>
        public int GetPlayerGold()
        {
            return playerGold;
        }
        
        /// <summary>
        /// 设置玩家金币
        /// </summary>
        public void SetPlayerGold(int gold)
        {
            playerGold = gold;
        }
        
        /// <summary>
        /// 添加物品到玩家背包
        /// </summary>
        private void AddItemToPlayer(ShopItem item)
        {
            if (Player.Instance != null)
            {
                // 这里应该调用玩家的背包系统
                Debug.Log($"物品已添加到背包: {item.Name}");
            }
        }
        
        /// <summary>
        /// 关闭商店
        /// </summary>
        public void CloseShop()
        {
            Debug.Log("商店已关闭");
        }
    }
}
