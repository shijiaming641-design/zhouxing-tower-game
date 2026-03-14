using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game.Tutorial
{
    /// <summary>
    /// 教程触发类型
    /// </summary>
    public enum TutorialTrigger
    {
        None,
        GameStart,           // 游戏开始
        FirstCombat,          // 首次战斗
        FirstCombo,           // 首次连招
        FirstShop,            // 首次商店
        FirstRest,            // 首次休息
        FirstEvent,           // 首次事件
        FirstBoss,            // 首次BOSS
        FirstUpgrade,         // 首次升级
        FirstEquip,           // 首次装备
        FirstItem,            // 首次使用道具
        ComboUnlock,          // 解锁连招
        Layer2,               // 到达第2层
        Layer3,               // 到达第3层
        WeekComplete,         // 首次周目完成
    }

    /// <summary>
    /// 教程步骤
    /// </summary>
    [System.Serializable]
    public class TutorialStep
    {
        public int StepIndex;
        public string Title;
        public string Content;
        public string HighlightUI;  // 高亮的UI元素
        public TutorialTrigger NextTrigger;  // 完成后触发下一个教程
        public bool IsRequired;  // 是否强制完成
        public bool CanSkip;  // 是否可以跳过

        public TutorialStep(int index, string title, string content, bool isRequired = true)
        {
            StepIndex = index;
            Title = title;
            Content = content;
            IsRequired = isRequired;
            CanSkip = !isRequired;
        }
    }

    /// <summary>
    /// 教程数据
    /// </summary>
    [System.Serializable]
    public class Tutorial
    {
        public string ID;
        public string Name;
        public TutorialTrigger Trigger;
        public List<TutorialStep> Steps = new List<TutorialStep>();
        public bool IsCompleted;
        public bool IsSkipped;

        public Tutorial(string id, string name, TutorialTrigger trigger)
        {
            ID = id;
            Name = name;
            Trigger = trigger;
        }

        /// <summary>
        /// 添加步骤
        /// </summary>
        public void AddStep(TutorialStep step)
        {
            step.StepIndex = Steps.Count;
            Steps.Add(step);
        }

        /// <summary>
        /// 获取步骤数
        /// </summary>
        public int GetStepCount()
        {
            return Steps.Count;
        }
    }

    /// <summary>
    /// 教程管理器
    /// </summary>
    public class TutorialSystem : MonoBehaviour
    {
        private static TutorialSystem _instance;
        public static TutorialSystem Instance => _instance;

        // 所有教程
        private List<Tutorial> tutorials = new List<Tutorial>();
        
        // 当前教程
        private Tutorial currentTutorial;
        private int currentStepIndex = 0;
        
        // 已完成的教程
        private HashSet<string> completedTutorials = new HashSet<string>();
        
        // 保存key
        private const string SAVE_KEY = "TutorialData";

        void Awake()
        {
            _instance = this;
            InitializeTutorials();
            LoadData();
        }

        /// <summary>
        /// 初始化所有教程
        /// </summary>
        private void InitializeTutorials()
        {
            // ========== 第一章：基础教程 ==========
            Tutorial chapter1 = new Tutorial("chapter1", "猜拳基础", TutorialTrigger.GameStart);
            
            chapter1.AddStep(new TutorialStep(0, "欢迎来到周行", 
                "欢迎来到《周行：循环三角》！\n\n这是一个充满挑战的爬塔游戏，你将通过猜拳策略来击败敌人，攀登塔顶！"));
            
            chapter1.AddStep(new TutorialStep(1, "猜拳规则", 
                "游戏的核心是猜拳对决：\n\n○ 圆 克制 △ 三角\n△ 三角 克制 □ 方\n□ 方 克制 ○ 圆\n\n猜拳获胜可以造成伤害！"));
            
            chapter1.AddStep(new TutorialStep(2, "如何出招", 
                "在战斗中，按下对应按键出招：\n\nA 键 → ○ 圆\nS 键 → △ 三角\nD 键 → □ 方"));
            
            chapter1.AddStep(new TutorialStep(3, "连招系统", 
                "当你按特定顺序出招时，会触发强大的连招效果！\n\n例如：\n△→○→□ = 闪电突袭\n□→□→△ = 稳固防御\n\n连招是战斗的关键！"));
            
            tutorials.Add(chapter1);

            // ========== 战斗教程 ==========
            Tutorial combatTutorial = new Tutorial("combat", "战斗指南", TutorialTrigger.FirstCombat);
            
            combatTutorial.AddStep(new TutorialStep(0, "战斗开始", 
                "在战斗中，你需要和敌人同时出招！\n\n猜拳获胜造成伤害，猜拳失败会受到伤害。"));
            
            combatTutorial.AddStep(new TutorialStep(1, "血量与防御", 
                "每个角色都有生命值(HP)和防御值。\n\n防御值优先抵挡伤害，耗尽后才会扣除生命。"));
            
            combatTutorial.AddStep(new TutorialStep(2, "暴击与格挡", 
                "暴击可以造成双倍伤害！\n\n格挡可以减少受到的伤害。"));
            
            tutorials.Add(combatTutorial);

            // ========== 连招教程 ==========
            Tutorial comboTutorial = new Tutorial("combo", "连招大师", TutorialTrigger.FirstCombo);
            
            comboTutorial.AddStep(new TutorialStep(0, "什么是连招", 
                "连招是通过特定顺序出招触发的强力效果！\n\n每次出招都会记录在序列中，匹配连招序列时触发效果。"));
            
            comboTutorial.AddStep(new TutorialStep(1, "基础连招", 
                "游戏中有许多基础连招：\n\n△→○→□ 闪电突袭\n□→□→△ 稳固防御\n○→△△ 能量充能\n\n通关过程中会逐步解锁更多连招！"));
            
            tutorials.Add(comboTutorial);

            // ========== 商店教程 ==========
            Tutorial shopTutorial = new Tutorial("shop", "商店指南", TutorialTrigger.FirstShop);
            
            shopTutorial.AddStep(new TutorialStep(0, "商店系统", 
                "在商店中，你可以购买装备和道具来提升实力！\n\n不同稀有度的装备有不同属性。"));
            
            shopTutorial.AddStep(new TutorialStep(1, "装备稀有度", 
                "装备分为4种稀有度：\n\n白色(普通) - 基础属性\n蓝色(精良) - 较好属性\n紫色(稀有) - 强力属性\n金色(传说) - 顶级属性"));
            
            shopTutorial.AddStep(new TutorialStep(2, "购买与刷新", 
                "商店商品每层刷新一次。\n\n也可以消耗金币手动刷新，获得新商品！"));
            
            tutorials.Add(shopTutorial);

            // ========== 地图教程 ==========
            Tutorial mapTutorial = new Tutorial("map", "探索指南", TutorialTrigger.Layer2);
            
            mapTutorial.AddStep(new TutorialStep(0, "地图探索", 
                "游戏中你需要在一张地图上选择路线前进。\n\n每层都有多个节点可供选择。"));
            
            mapTutorial.AddStep(new TutorialStep(1, "节点类型", 
                "地图上有多种节点：\n\n⚔️ 战斗 - 挑战敌人\n🏪 商店 - 购买物品\n⛺ 休息 - 恢复生命\n❓ 事件 - 随机事件\n👑 BOSS - 强大的敌人"));
            
            mapTutorial.AddStep(new TutorialStep(2, "路线选择", 
                "选择路线时考虑风险与回报：\n\n战斗多=奖励多但风险高\n商店/休息=安全但需要金币"));
            
            tutorials.Add(mapTutorial);

            // ========== 成长教程 ==========
            Tutorial growthTutorial = new Tutorial("growth", "成长指南", TutorialTrigger.FirstUpgrade);
            
            growthTutorial.AddStep(new TutorialStep(0, "局内成长", 
                "每场战斗胜利后，你获得：\n\n💰 金币 - 用于购买物品\n📧 经验 - 提升等级\n📦 装备 - 提升属性"));
            
            growthTutorial.AddStep(new TutorialStep(1, "局外成长", 
                "通关后获得「人员存储器」，用于永久解锁：\n\n• 新连招\n• 额外背包格\n• 更强属性\n• 更多装备槽"));
            
            growthTutorial.AddStep(new TutorialStep(2, "多周目", 
                "通关后可以开启新周目！\n\n新周目敌人更强，但你可以携带更强装备和新解锁能力！"));
            
            tutorials.Add(growthTutorial);

            Debug.Log($"已加载 {tutorials.Count} 个教程");
        }

        /// <summary>
        /// 检查并触发教程
        /// </summary>
        public void CheckTrigger(TutorialTrigger trigger)
        {
            if (trigger == TutorialTrigger.None) return;

            // 查找对应的教程
            Tutorial tutorial = tutorials.Find(t => t.Trigger == trigger);
            
            if (tutorial == null)
            {
                Debug.Log($"未找到触发器 {trigger} 对应的教程");
                return;
            }

            // 检查是否已完成
            if (completedTutorials.Contains(tutorial.ID))
            {
                Debug.Log($"教程已完成: {tutorial.Name}");
                return;
            }

            // 开始教程
            StartTutorial(tutorial);
        }

        /// <summary>
        /// 开始教程
        /// </summary>
        public void StartTutorial(Tutorial tutorial)
        {
            if (tutorial.IsCompleted)
            {
                Debug.Log($"教程已完成: {tutorial.Name}");
                return;
            }

            currentTutorial = tutorial;
            currentStepIndex = 0;
            
            ShowCurrentStep();
            
            Debug.Log($"开始教程: {tutorial.Name}");
        }

        /// <summary>
        /// 显示当前步骤
        /// </summary>
        private void ShowCurrentStep()
        {
            if (currentTutorial == null) return;
            if (currentStepIndex >= currentTutorial.Steps.Count)
            {
                CompleteTutorial();
                return;
            }

            TutorialStep step = currentTutorial.Steps[currentStepIndex];
            
            // 显示教程UI
            Debug.Log($"教程步骤 {currentStepIndex + 1}: {step.Title}");
            Debug.Log(step.Content);
            
            // 可以在这里调用UI系统显示教程弹窗
            // UIManager.Instance.ShowTutorialPanel(step);
        }

        /// <summary>
        /// 下一步
        /// </summary>
        public void NextStep()
        {
            if (currentTutorial == null) return;

            currentStepIndex++;

            // 检查是否完成
            if (currentStepIndex >= currentTutorial.Steps.Count)
            {
                CompleteTutorial();
                return;
            }

            ShowCurrentStep();
        }

        /// <summary>
        /// 跳过当前步骤
        /// </summary>
        public void SkipStep()
        {
            if (currentTutorial == null) return;

            TutorialStep step = currentTutorial.Steps[currentStepIndex];
            
            if (!step.CanSkip)
            {
                Debug.LogWarning("此步骤无法跳过");
                return;
            }

            NextStep();
        }

        /// <summary>
        /// 完成教程
        /// </summary>
        private void CompleteTutorial()
        {
            if (currentTutorial == null) return;

            currentTutorial.IsCompleted = true;
            completedTutorials.Add(currentTutorial.ID);
            
            Debug.Log($"教程完成: {currentTutorial.Name}");
            
            // 检查是否触发下一个教程
            TutorialStep lastStep = currentTutorial.Steps[currentTutorial.Steps.Count - 1];
            if (lastStep.NextTrigger != TutorialTrigger.None)
            {
                CheckTrigger(lastStep.NextTrigger);
            }

            // 保存
            SaveData();
            
            currentTutorial = null;
            currentStepIndex = 0;
        }

        /// <summary>
        /// 跳过整个教程
        /// </summary>
        public void SkipTutorial()
        {
            if (currentTutorial == null) return;

            currentTutorial.IsSkipped = true;
            completedTutorials.Add(currentTutorial.ID);
            
            Debug.Log($"教程跳过: {currentTutorial.Name}");
            
            SaveData();
            
            currentTutorial = null;
            currentStepIndex = 0;
        }

        /// <summary>
        /// 检查教程是否完成
        /// </summary>
        public bool IsTutorialCompleted(string tutorialID)
        {
            return completedTutorials.Contains(tutorialID);
        }

        /// <summary>
        /// 获取当前教程
        /// </summary>
        public Tutorial GetCurrentTutorial()
        {
            return currentTutorial;
        }

        /// <summary>
        /// 获取当前步骤
        /// </summary>
        public TutorialStep GetCurrentStep()
        {
            if (currentTutorial == null) return null;
            if (currentStepIndex >= currentTutorial.Steps.Count) return null;
            
            return currentTutorial.Steps[currentStepIndex];
        }

        /// <summary>
        /// 是否有教程进行中
        /// </summary>
        public bool IsTutorialActive()
        {
            return currentTutorial != null;
        }

        /// <summary>
        /// 获取教程进度
        /// </summary>
        public (int completed, int total) GetProgress()
        {
            return (completedTutorials.Count, tutorials.Count);
        }

        /// <summary>
        /// 保存数据
        /// </summary>
        private void SaveData()
        {
            List<string> list = new List<string>(completedTutorials);
            string json = JsonUtility.ToJson(new TutorialSaveData(list));
            PlayerPrefs.SetString(SAVE_KEY, json);
            PlayerPrefs.Save();
        }

        /// <summary>
        /// 加载数据
        /// </summary>
        private void LoadData()
        {
            string json = PlayerPrefs.GetString(SAVE_KEY, "");
            
            if (!string.IsNullOrEmpty(json))
            {
                try
                {
                    TutorialSaveData data = JsonUtility.FromJson<TutorialSaveData>(json);
                    
                    foreach (string id in data.completedIDs)
                    {
                        completedTutorials.Add(id);
                        
                        Tutorial tutorial = tutorials.Find(t => t.ID == id);
                        if (tutorial != null)
                        {
                            tutorial.IsCompleted = true;
                        }
                    }
                    
                    Debug.Log($"已加载 {completedTutorials.Count} 个已完成教程");
                }
                catch
                {
                    Debug.LogWarning("教程数据加载失败");
                }
            }
        }

        /// <summary>
        /// 重置所有教程
        /// </summary>
        public void ResetAllTutorials()
        {
            completedTutorials.Clear();
            
            foreach (var tutorial in tutorials)
            {
                tutorial.IsCompleted = false;
                tutorial.IsSkipped = false;
            }
            
            SaveData();
            Debug.Log("教程已重置");
        }

        #region 便捷方法

        /// <summary>
        /// 游戏开始
        /// </summary>
        public static void OnGameStart()
        {
            Instance?.CheckTrigger(TutorialTrigger.GameStart);
        }

        /// <summary>
        /// 首次战斗
        /// </summary>
        public static void OnFirstCombat()
        {
            Instance?.CheckTrigger(TutorialTrigger.FirstCombat);
        }

        /// <summary>
        /// 首次连招
        /// </summary>
        public static void OnFirstCombo()
        {
            Instance?.CheckTrigger(TutorialTrigger.FirstCombo);
        }

        /// <summary>
        /// 首次商店
        /// </summary>
        public static void OnFirstShop()
        {
            Instance?.CheckTrigger(TutorialTrigger.FirstShop);
        }

        /// <summary>
        /// 首次休息
        /// </summary>
        public static void OnFirstRest()
        {
            Instance?.CheckTrigger(TutorialTrigger.FirstRest);
        }

        /// <summary>
        /// 到达第2层
        /// </summary>
        public static void OnReachLayer2()
        {
            Instance?.CheckTrigger(TutorialTrigger.Layer2);
        }

        #endregion
    }

    /// <summary>
    /// 教程保存数据
    /// </summary>
    [System.Serializable]
    public class TutorialSaveData
    {
        public List<string> completedIDs;

        public TutorialSaveData()
        {
            completedIDs = new List<string>();
        }

        public TutorialSaveData(List<string> ids)
        {
            completedIDs = ids;
        }
    }
}
