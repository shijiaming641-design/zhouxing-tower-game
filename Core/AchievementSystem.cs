using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game.Achievement
{
    /// <summary>
    /// 成就分类
    /// </summary>
    public enum AchievementCategory
    {
        Battle,     // 战斗成就
        Explore,    // 探索成就
        Collection, // 收集成就
        Special,    // 特殊成就
        Hidden      // 隐藏成就
    }

    /// <summary>
    /// 成就条件类型
    /// </summary>
    public enum AchievementConditionType
    {
        DefeatEnemy,          // 击败敌人
        WinBattle,            // 战斗胜利
        UseCombo,             // 使用连招
        VisitNode,            // 访问节点
        CollectItem,          // 收集物品
        ReachLayer,           // 到达层数
        CompleteWeek,         // 完成周目
        UseItem,              // 使用道具
        Purchase,             // 购买物品
        Custom                // 自定义
    }

    /// <summary>
    /// 成就
    /// </summary>
    [System.Serializable]
    public class Achievement
    {
        public string ID;
        public string Name;
        public string Description;
        public AchievementCategory Category;
        public int Difficulty;  // 1-5星
        public int Reward;     // 人员存储器奖励
        
        // 条件
        public AchievementConditionType ConditionType;
        public int RequiredCount;  // 所需数量
        public int CurrentCount;  // 当前进度
        
        public bool IsCompleted;
        public System.DateTime? CompletedTime;

        public Achievement(string id, string name, string desc, AchievementCategory category, int difficulty, int reward)
        {
            ID = id;
            Name = name;
            Description = desc;
            Category = category;
            Difficulty = difficulty;
            Reward = reward;
            RequiredCount = 1;
            CurrentCount = 0;
            IsCompleted = false;
        }

        /// <summary>
        /// 获取难度显示
        /// </summary>
        public string GetDifficultyStars()
        {
            string stars = "";
            for (int i = 0; i < Difficulty; i++)
            {
                stars += "★";
            }
            return stars;
        }

        /// <summary>
        /// 获取进度文本
        /// </summary>
        public string GetProgressText()
        {
            if (IsCompleted) return "已完成";
            return $"{CurrentCount}/{RequiredCount}";
        }

        /// <summary>
        /// 获取分类名称
        /// </summary>
        public string GetCategoryName()
        {
            switch(Category)
            {
                case AchievementCategory.Battle: return "战斗";
                case AchievementCategory.Explore: return "探索";
                case AchievementCategory.Collection: return "收集";
                case AchievementCategory.Special: return "特殊";
                case AchievementCategory.Hidden: return "隐藏";
                default: return "其他";
            }
        }
    }

    /// <summary>
    /// 成就管理器
    /// </summary>
    public class AchievementSystem : MonoBehaviour
    {
        private static AchievementSystem _instance;
        public static AchievementSystem Instance => _instance;

        // 所有成就
        private List<Achievement> achievements = new List<Achievement>();
        
        // 已解锁的成就
        private HashSet<string> unlockedAchievements = new HashSet<string>();

        // 成就数据保存key
        private const string SAVE_KEY = "AchievementData";

        void Awake()
        {
            _instance = this;
            InitializeAchievements();
            LoadAchievements();
        }

        /// <summary>
        /// 初始化成就列表
        /// </summary>
        private void InitializeAchievements()
        {
            // ========== 战斗成就 ==========
            achievements.Add(new Achievement("battle_001", "初战告捷", "击败第一个敌人", AchievementCategory.Battle, 1, 1));
            achievements.Add(new Achievement("battle_002", "连胜3场", "连续击败3个敌人", AchievementCategory.Battle, 2, 2));
            achievements.Add(new Achievement("battle_003", "连胜5场", "连续击败5个敌人", AchievementCategory.Battle, 3, 3));
            achievements.Add(new Achievement("battle_004", "连胜10场", "连续击败10个敌人", AchievementCategory.Battle, 4, 5));
            achievements.Add(new Achievement("battle_005", "无伤通关", "不受伤害通过一层", AchievementCategory.Battle, 3, 5));
            achievements.Add(new Achievement("battle_006", "越级挑战", "击败高于自己5级的敌人", AchievementCategory.Battle, 3, 3));
            achievements.Add(new Achievement("battle_007", "零封BOSS", "BOSS战0伤害胜利", AchievementCategory.Battle, 5, 10));
            achievements.Add(new Achievement("battle_008", "反杀", "在血量低于20%时击败敌人", AchievementCategory.Battle, 3, 3));
            achievements.Add(new Achievement("battle_009", "连击", "一次性造成10点以上伤害", AchievementCategory.Battle, 2, 2));
            achievements.Add(new Achievement("battle_010", "元素大师", "使用所有类型克制击败敌人", AchievementCategory.Battle, 3, 3));

            // ========== 探索成就 ==========
            achievements.Add(new Achievement("explore_001", "首次探索", "进入第二层", AchievementCategory.Explore, 1, 1));
            achievements.Add(new Achievement("explore_002", "深入探索", "进入第三层", AchievementCategory.Explore, 2, 2));
            achievements.Add(new Achievement("explore_003", "登堂入室", "进入第四层", AchievementCategory.Explore, 3, 3));
            achievements.Add(new Achievement("explore_004", "商店顾客", "在商店消费100金币", AchievementCategory.Explore, 2, 2));
            achievements.Add(new Achievement("explore_005", "VIP顾客", "在商店消费500金币", AchievementCategory.Explore, 3, 3));
            achievements.Add(new Achievement("explore_006", "地图大师", "探索所有节点类型", AchievementCategory.Explore, 3, 3));
            achievements.Add(new Achievement("explore_007", "休息达人", "使用休息点5次", AchievementCategory.Explore, 2, 2));
            achievements.Add(new Achievement("explore_008", "事件达人", "触发10个随机事件", AchievementCategory.Explore, 3, 3));

            // ========== 收集成就 ==========
            achievements.Add(new Achievement("collect_001", "收藏家", "拥有10件装备", AchievementCategory.Collection, 2, 2));
            achievements.Add(new Achievement("collect_002", "连招大师", "解锁所有基础连招", AchievementCategory.Collection, 3, 3));
            achievements.Add(new Achievement("collect_003", "装备达人", "拥有5件紫色以上装备", AchievementCategory.Collection, 3, 5));
            achievements.Add(new Achievement("collect_004", "道具收藏家", "拥有20个道具", AchievementCategory.Collection, 2, 2));
            achievements.Add(new Achievement("collect_005", "全收集", "解锁所有内容", AchievementCategory.Collection, 5, 20));
            achievements.Add(new Achievement("collect_006", "商店大亨", "购买50件商品", AchievementCategory.Collection, 3, 3));
            achievements.Add(new Achievement("collect_007", "抽卡达人", "抽卡50次", AchievementCategory.Collection, 3, 3));

            // ========== 特殊成就 ==========
            achievements.Add(new Achievement("special_001", "首次升级", "首次升级", AchievementCategory.Special, 1, 1));
            achievements.Add(new Achievement("special_002", "欧皇", "抽卡获得传说装备", AchievementCategory.Special, 3, 3));
            achievements.Add(new Achievement("special_003", "非酋", "抽卡100次未获得传说", AchievementCategory.Special, 2, 2));
            achievements.Add(new Achievement("special_004", "速通", "30分钟内通关", AchievementCategory.Special, 4, 10));
            achievements.Add(new Achievement("special_005", "无无敌", "100连胜", AchievementCategory.Special, 5, 20));
            achievements.Add(new Achievement("special_006", "首通", "完成第1周目", AchievementCategory.Special, 2, 3));
            achievements.Add(new Achievement("special_007", "周目达人", "完成5周目", AchievementCategory.Special, 4, 10));
            achievements.Add(new Achievement("special_008", "刷子", "累计游戏时间100小时", AchievementCategory.Special, 4, 10));

            // ========== 隐藏成就 ==========
            achievements.Add(new Achievement("hidden_001", "秘密发现", "发现隐藏房间", AchievementCategory.Hidden, 3, 5));
            achievements.Add(new Achievement("hidden_002", "背刺", "从背后攻击敌人", AchievementCategory.Hidden, 2, 2));
            achievements.Add(new Achievement("hidden_003", "命运", "打出33%概率技能成功", AchievementCategory.Hidden, 4, 10));
            achievements.Add(new Achievement("hidden_004", "极限生存", "最后1血击败敌人", AchievementCategory.Hidden, 3, 5));
            achievements.Add(new Achievement("hidden_005", "完美主义", "所有节点无遗漏通过一层", AchievementCategory.Hidden, 4, 5));

            Debug.Log($"已加载 {achievements.Count} 个成就");
        }

        /// <summary>
        /// 检查成就条件
        /// </summary>
        public void CheckAchievement(AchievementConditionType type, int value = 1)
        {
            foreach (var achievement in achievements)
            {
                if (achievement.IsCompleted) continue;
                if (achievement.ConditionType != type) continue;

                achievement.CurrentCount += value;
                
                // 检查是否完成
                if (achievement.CurrentCount >= achievement.RequiredCount)
                {
                    UnlockAchievement(achievement.ID);
                }
            }
        }

        /// <summary>
        /// 解锁成就
        /// </summary>
        public bool UnlockAchievement(string achievementID)
        {
            Achievement achievement = achievements.Find(a => a.ID == achievementID);
            
            if (achievement == null)
            {
                Debug.LogWarning($"成就不存在: {achievementID}");
                return false;
            }

            if (achievement.IsCompleted)
            {
                Debug.Log($"成就已完成: {achievement.Name}");
                return false;
            }

            // 解锁成就
            achievement.IsCompleted = true;
            achievement.CompletedTime = System.DateTime.Now;
            unlockedAchievements.Add(achievementID);

            // 发放奖励
            if (Game.ProgressionSystem.Instance != null)
            {
                Game.ProgressionSystem.Instance.AddMemory(achievement.Reward);
            }

            // 显示成就解锁UI
            ShowAchievementUnlocked(achievement);

            Debug.Log($"成就解锁: {achievement.Name}! 奖励: {achievement.Reward} 个人员存储器");

            // 保存
            SaveAchievements();

            return true;
        }

        /// <summary>
        /// 显示成就解锁提示
        /// </summary>
        private void ShowAchievementUnlocked(Achievement achievement)
        {
            // 这里可以调用UI系统显示成就解锁弹窗
            Debug.Log($"🎉 成就解锁: {achievement.Name}! +{achievement.Reward} 💎");
        }

        /// <summary>
        /// 获取成就
        /// </summary>
        public Achievement GetAchievement(string id)
        {
            return achievements.Find(a => a.ID == id);
        }

        /// <summary>
        /// 获取所有成就
        /// </summary>
        public List<Achievement> GetAllAchievements()
        {
            return achievements;
        }

        /// <summary>
        /// 获取分类成就
        /// </summary>
        public List<Achievement> GetAchievementsByCategory(AchievementCategory category)
        {
            return achievements.FindAll(a => a.Category == category);
        }

        /// <summary>
        /// 获取已解锁成就
        /// </summary>
        public List<Achievement> GetUnlockedAchievements()
        {
            return achievements.FindAll(a => a.IsCompleted);
        }

        /// <summary>
        /// 获取成就进度
        /// </summary>
        public (int completed, int total) GetProgress()
        {
            int completed = achievements.FindAll(a => a.IsCompleted).Count;
            return (completed, achievements.Count);
        }

        /// <summary>
        /// 获取成就总数
        /// </summary>
        public int GetTotalAchievements()
        {
            return achievements.Count;
        }

        /// <summary>
        /// 获取已解锁数量
        /// </summary>
        public int GetUnlockedCount()
        {
            return unlockedAchievements.Count;
        }

        /// <summary>
        /// 是否有未解锁成就
        /// </summary>
        public bool HasUnlockedAchievement(string id)
        {
            return unlockedAchievements.Contains(id);
        }

        /// <summary>
        /// 获取总奖励
        /// </summary>
        public int GetTotalReward()
        {
            int total = 0;
            foreach (var a in achievements)
            {
                if (!a.IsCompleted)
                {
                    total += a.Reward;
                }
            }
            return total;
        }

        /// <summary>
        /// 保存成就数据
        /// </summary>
        public void SaveAchievements()
        {
            // 保存已解锁的成就ID
            List<string> unlockedList = new List<string>(unlockedAchievements);
            string json = JsonUtility.ToJson(new AchievementSaveData(unlockedList));
            PlayerPrefs.SetString(SAVE_KEY, json);
            PlayerPrefs.Save();
        }

        /// <summary>
        /// 加载成就数据
        /// </summary>
        private void LoadAchievements()
        {
            string json = PlayerPrefs.GetString(SAVE_KEY, "");
            
            if (!string.IsNullOrEmpty(json))
            {
                try
                {
                    AchievementSaveData data = JsonUtility.FromJson<AchievementSaveData>(json);
                    
                    foreach (string id in data.unlockedIDs)
                    {
                        Achievement achievement = achievements.Find(a => a.ID == id);
                        if (achievement != null)
                        {
                            achievement.IsCompleted = true;
                            unlockedAchievements.Add(id);
                        }
                    }
                    
                    Debug.Log($"已加载 {unlockedAchievements.Count} 个已解锁成就");
                }
                catch
                {
                    Debug.LogWarning("成就数据加载失败");
                }
            }
        }

        /// <summary>
        /// 重置成就
        /// </summary>
        public void ResetAchievements()
        {
            unlockedAchievements.Clear();
            
            foreach (var achievement in achievements)
            {
                achievement.IsCompleted = false;
                achievement.CurrentCount = 0;
                achievement.CompletedTime = null;
            }
            
            SaveAchievements();
            Debug.Log("成就已重置");
        }

        #region 便捷方法

        /// <summary>
        /// 击败敌人
        /// </summary>
        public static void OnDefeatEnemy()
        {
            Instance?.CheckAchievement(AchievementConditionType.DefeatEnemy);
        }

        /// <summary>
        /// 战斗胜利
        /// </summary>
        public static void OnWinBattle()
        {
            Instance?.CheckAchievement(AchievementConditionType.WinBattle);
        }

        /// <summary>
        /// 使用连招
        /// </summary>
        public static void OnUseCombo()
        {
            Instance?.CheckAchievement(AchievementConditionType.UseCombo);
        }

        /// <summary>
        /// 到达层数
        /// </summary>
        public static void OnReachLayer(int layer)
        {
            // 检查相关成就
            if (layer >= 2) Instance?.CheckAchievement(AchievementConditionType.ReachLayer);
        }

        /// <summary>
        /// 完成周目
        /// </summary>
        public static void OnCompleteWeek(int week)
        {
            if (week == 1) Instance?.CheckAchievement(AchievementConditionType.CompleteWeek);
        }

        /// <summary>
        /// 购买物品
        /// </summary>
        public static void OnPurchase(int amount)
        {
            // 这里需要在购买时调用
        }

        #endregion
    }

    /// <summary>
    /// 成就保存数据
    /// </summary>
    [System.Serializable]
    public class AchievementSaveData
    {
        public List<string> unlockedIDs;

        public AchievementSaveData()
        {
            unlockedIDs = new List<string>();
        }

        public AchievementSaveData(List<string> ids)
        {
            unlockedIDs = ids;
        }
    }
}
