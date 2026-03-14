using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// AI行为类型
    /// </summary>
    public enum AIBehavior
    {
        Random,      // 随机出招
        Aggressive,  // 激进攻击型
        Defensive,   // 防守优先型
        Adaptive,    // 适应型（学习玩家）
        Tactical,    // 战术型（根据血量调整）
        Boss         // BOSS特殊AI
    }

    /// <summary>
    /// AI难度等级
    /// </summary>
    public enum AIDifficulty
    {
        Easy,      // 简单
        Normal,    // 普通
        Hard,      // 困难
        Nightmare  // 噩梦
    }

    /// <summary>
    /// 出招类型
    /// </summary>
    public enum MoveType
    {
        Circle = 0,    // ○ 圆
        Triangle = 1, // △ 三角
        Square = 2    // □ 方
    }

    /// <summary>
    /// AI行为基类
    /// </summary>
    public abstract class EnemyAI
    {
        // AI配置
        protected AIBehavior behavior;
        protected AIDifficulty difficulty;
        
        // 玩家历史出招记录
        protected List<MoveType> playerMoveHistory = new List<MoveType>();
        
        // AI出招历史
        protected List<MoveType> aiMoveHistory = new List<MoveType>();
        
        // 当前回合
        protected int currentTurn = 0;
        
        // 预测准确率
        protected float predictionAccuracy = 0.5f;
        
        // 暴击率
        protected float critRate = 0.1f;
        
        public EnemyAI()
        {
            SetDifficulty(AIDifficulty.Normal);
        }
        
        /// <summary>
        /// 设置难度
        /// </summary>
        public void SetDifficulty(AIDifficulty difficulty)
        {
            this.difficulty = difficulty;
            
            switch(difficulty)
            {
                case AIDifficulty.Easy:
                    predictionAccuracy = 0.3f;
                    critRate = 0.05f;
                    break;
                case AIDifficulty.Normal:
                    predictionAccuracy = 0.5f;
                    critRate = 0.1f;
                    break;
                case AIDifficulty.Hard:
                    predictionAccuracy = 0.7f;
                    critRate = 0.15f;
                    break;
                case AIDifficulty.Nightmare:
                    predictionAccuracy = 0.9f;
                    critRate = 0.2f;
                    break;
            }
        }
        
        /// <summary>
        /// 记录玩家出招
        /// </summary>
        public void RecordPlayerMove(MoveType move)
        {
            playerMoveHistory.Add(move);
            if (playerMoveHistory.Count > 10)
            {
                playerMoveHistory.RemoveAt(0);
            }
        }
        
        /// <summary>
        /// 记录AI出招
        /// </summary>
        public void RecordAIMove(MoveType move)
        {
            aiMoveHistory.Add(move);
            if (aiMoveHistory.Count > 10)
            {
                aiMoveHistory.RemoveAt(0);
            }
        }
        
        /// <summary>
        /// 决定出招
        /// </summary>
        public abstract MoveType DecideMove();
        
        /// <summary>
        /// 计算伤害
        /// </summary>
        public virtual int CalculateDamage(int baseDamage)
        {
            int damage = baseDamage;
            
            // 暴击判定
            if (Random.value < critRate)
            {
                damage *= 2;
                Debug.Log("暴击!");
            }
            
            return damage;
        }
        
        /// <summary>
        /// 获取行为名称
        /// </summary>
        public string GetBehaviorName()
        {
            return behavior.ToString();
        }
        
        /// <summary>
        /// 获取难度名称
        /// </summary>
        public string GetDifficultyName()
        {
            return difficulty.ToString();
        }
    }

    /// <summary>
    /// 随机型AI - 完全随机出招
    /// </summary>
    public class RandomAI : EnemyAI
    {
        public RandomAI()
        {
            behavior = AIBehavior.Random;
        }
        
        public override MoveType DecideMove()
        {
            return (MoveType)Random.Range(0, 3);
        }
    }

    /// <summary>
    /// 激进型AI - 优先攻击
    /// </summary>
    public class AggressiveAI : EnemyAI
    {
        public AggressiveAI()
        {
            behavior = AIBehavior.Aggressive;
        }
        
        public override MoveType DecideMove()
        {
            float roll = Random.value;
            
            // 60%概率出攻击性招式（根据克制关系）
            if (roll < 0.6f)
            {
                // 随机选择
                return (MoveType)Random.Range(0, 3);
            }
            // 20%概率防守
            else if (roll < 0.8f)
            {
                // 随机选择
                return (MoveType)Random.Range(0, 3);
            }
            // 20%完全随机
            else
            {
                return (MoveType)Random.Range(0, 3);
            }
        }
    }

    /// <summary>
    /// 防守型AI - 优先防御
    /// </summary>
    public class DefensiveAI : EnemyAI
    {
        public DefensiveAI()
        {
            behavior = AIBehavior.Defensive;
        }
        
        public override MoveType DecideMove()
        {
            float roll = Random.value;
            
            // 60%概率出防守性招式
            if (roll < 0.6f)
            {
                return (MoveType)Random.Range(0, 3);
            }
            // 20%概率进攻
            else if (roll < 0.8f)
            {
                return (MoveType)Random.Range(0, 3);
            }
            // 20%随机
            else
            {
                return (MoveType)Random.Range(0, 3);
            }
        }
    }

    /// <summary>
    /// 适应型AI - 学习玩家习惯
    /// </summary>
    public class AdaptiveAI : EnemyAI
    {
        public AdaptiveAI()
        {
            behavior = AIBehavior.Adaptive;
        }
        
        public override MoveType DecideMove()
        {
            // 分析玩家最常用的出招
            if (playerMoveHistory.Count >= 3 && Random.value < predictionAccuracy)
            {
                MoveType mostUsed = GetMostUsedMove();
                // 克制玩家常用的出招
                return GetCounterMove(mostUsed);
            }
            
            // 否则随机
            return (MoveType)Random.Range(0, 3);
        }
        
        private MoveType GetMostUsedMove()
        {
            int[] counts = { 0, 0, 0 };
            
            foreach (MoveType move in playerMoveHistory)
            {
                counts[(int)move]++;
            }
            
            // 返回最常用的
            int maxIndex = 0;
            for (int i = 1; i < 3; i++)
            {
                if (counts[i] > counts[maxIndex])
                {
                    maxIndex = i;
                }
            }
            
            return (MoveType)maxIndex;
        }
        
        private MoveType GetCounterMove(MoveType playerMove)
        {
            // 克制关系: ○ > △ > □ > ○
            switch (playerMove)
            {
                case MoveType.Circle: return MoveType.Square;    // □ 克 ○
                case MoveType.Triangle: return MoveType.Circle; // ○ 克 △
                case MoveType.Square: return MoveType.Triangle; // △ 克 □
                default: return (MoveType)Random.Range(0, 3);
            }
        }
    }

    /// <summary>
    /// 战术型AI - 根据血量调整策略
    /// </summary>
    public class TacticalAI : EnemyAI
    {
        public TacticalAI()
        {
            behavior = AIBehavior.Tactical;
        }
        
        public override MoveType DecideMove()
        {
            // 这个需要传入敌人血量百分比
            // 这里返回默认策略
            return (MoveType)Random.Range(0, 3);
        }
        
        /// <summary>
        /// 根据血量百分比决定出招
        /// </summary>
        public MoveType DecideByHP(float hpPercent)
        {
            if (hpPercent > 0.7f)
            {
                // 高血量 - 激进进攻
                return (MoveType)Random.Range(0, 3);
            }
            else if (hpPercent > 0.3f)
            {
                // 中血量 - 均衡
                return (MoveType)Random.Range(0, 3);
            }
            else
            {
                // 低血量 - 拼命/防守
                float roll = Random.value;
                if (roll < 0.5f)
                {
                    // 防守
                    return (MoveType)Random.Range(0, 3);
                }
                else
                {
                    // 进攻
                    return (MoveType)Random.Range(0, 3);
                }
            }
        }
    }

    /// <summary>
    /// BOSS AI基类
    /// </summary>
    public class BossAI : EnemyAI
    {
        protected int currentPhase = 1;
        protected int maxPhase = 3;
        
        public BossAI()
        {
            behavior = AIBehavior.Boss;
            SetDifficulty(AIDifficulty.Hard);
        }
        
        /// <summary>
        /// 检查阶段转换
        /// </summary>
        public virtual void CheckPhaseChange(float hpPercent)
        {
            if (currentPhase < maxPhase)
            {
                float[] phaseThresholds = { 0.7f, 0.3f };
                
                if (hpPercent <= phaseThresholds[currentPhase - 1] * 100)
                {
                    currentPhase++;
                    OnPhaseChanged();
                }
            }
        }
        
        /// <summary>
        /// 阶段转换回调
        /// </summary>
        protected virtual void OnPhaseChanged()
        {
            Debug.Log($"BOSS进入第 {currentPhase} 阶段!");
            // 可以在这里触发特殊效果
        }
        
        /// <summary>
        /// BOSS特殊技能
        /// </summary>
        public virtual void UseSpecialAbility()
        {
            Debug.Log("BOSS使用特殊技能!");
        }
        
        public override MoveType DecideMove()
        {
            // BOSS会根据阶段调整策略
            return (MoveType)Random.Range(0, 3);
        }
        
        public int GetCurrentPhase()
        {
            return currentPhase;
        }
    }

    /// <summary>
    /// 核心守卫BOSS - 有信物机制
    /// </summary>
    public class CoreGuardianAI : BossAI
    {
        // 是否有密钥
        private bool hasKey = false;
        
        public CoreGuardianAI()
        {
            maxPhase = 2;
        }
        
        /// <summary>
        /// 设置是否有密钥
        /// </summary>
        public void SetHasKey(bool value)
        {
            hasKey = value;
        }
        
        public override int CalculateDamage(int baseDamage)
        {
            // 没有密钥时伤害大幅降低
            if (!hasKey)
            {
                Debug.Log("BOSS没有密钥，伤害降低!");
                return 1;  // 最低伤害
            }
            
            return baseDamage * 2;  // 有密钥伤害翻倍
        }
        
        protected override void OnPhaseChanged()
        {
            base.OnPhaseChanged();
            
            // 第二阶段召唤小怪或释放全屏技能
            if (currentPhase == 2)
            {
                Debug.Log("核心守卫进入第二阶段! 释放技能!");
            }
        }
    }

    /// <summary>
    /// AI系统 - 管理所有敌人AI
    /// </summary>
    public class AISystem : MonoBehaviour
    {
        private static AISystem _instance;
        public static AISystem Instance => _instance;
        
        // 当前AI实例
        private EnemyAI currentAI;
        
        // AI工厂
        private Dictionary<AIBehavior, System.Type> aiFactory = new Dictionary<AIBehavior, System.Type>()
        {
            { AIBehavior.Random, typeof(RandomAI) },
            { AIBehavior.Aggressive, typeof(AggressiveAI) },
            { AIBehavior.Defensive, typeof(DefensiveAI) },
            { AIBehavior.Adaptive, typeof(AdaptiveAI) },
            { AIBehavior.Tactical, typeof(TacticalAI) },
            { AIBehavior.Boss, typeof(BossAI) }
        };
        
        void Awake()
        {
            _instance = this;
        }
        
        /// <summary>
        /// 创建AI
        /// </summary>
        public void CreateAI(AIBehavior behavior)
        {
            if (aiFactory.ContainsKey(behavior))
            {
                currentAI = System.Activator.CreateInstance(aiFactory[behavior]) as EnemyAI;
                Debug.Log($"创建AI: {behavior}");
            }
        }
        
        /// <summary>
        /// 创建随机AI
        /// </summary>
        public void CreateRandomAI()
        {
            AIBehavior[] behaviors = { AIBehavior.Random, AIBehavior.Aggressive, AIBehavior.Defensive, AIBehavior.Adaptive };
            AIBehavior randomBehavior = behaviors[Random.Range(0, behaviors.Length)];
            CreateAI(randomBehavior);
        }
        
        /// <summary>
        /// 创建BOSS AI
        /// </summary>
        public void CreateBossAI()
        {
            CreateAI(AIBehavior.Boss);
        }
        
        /// <summary>
        /// 设置难度
        /// </summary>
        public void SetDifficulty(AIDifficulty difficulty)
        {
            if (currentAI != null)
            {
                currentAI.SetDifficulty(difficulty);
            }
        }
        
        /// <summary>
        /// 获取AI决策
        /// </summary>
        public MoveType GetAIMove()
        {
            if (currentAI == null)
            {
                Debug.LogWarning("AI未创建，使用随机");
                return (MoveType)Random.Range(0, 3);
            }
            
            return currentAI.DecideMove();
        }
        
        /// <summary>
        /// 记录玩家出招
        /// </summary>
        public void RecordPlayerMove(MoveType move)
        {
            currentAI?.RecordPlayerMove(move);
        }
        
        /// <summary>
        /// 记录AI出招
        /// </summary>
        public void RecordAIMove(MoveType move)
        {
            currentAI?.RecordAIMove(move);
        }
        
        /// <summary>
        /// 计算伤害
        /// </summary>
        public int CalculateDamage(int baseDamage)
        {
            return currentAI?.CalculateDamage(baseDamage) ?? baseDamage;
        }
        
        /// <summary>
        /// 玩家选择克制
        /// </summary>
        public static MoveType GetCounterMove(MoveType opponentMove)
        {
            switch (opponentMove)
            {
                case MoveType.Circle: return MoveType.Square;    // □ 克 ○
                case MoveType.Triangle: return MoveType.Circle; // ○ 克 △
                case MoveType.Square: return MoveType.Triangle; // △ 克 □
                default: return (MoveType)Random.Range(0, 3);
            }
        }
        
        /// <summary>
        /// 判断胜负
        /// </summary>
        public static int CompareMoves(MoveType player, MoveType ai)
        {
            // 0: 平局, 1: 玩家赢, -1: AI赢
            if (player == ai) return 0;
            
            if ((player == MoveType.Circle && ai == MoveType.Triangle) ||
                (player == MoveType.Triangle && ai == MoveType.Square) ||
                (player == MoveType.Square && ai == MoveType.Circle))
            {
                return 1;
            }
            
            return -1;
        }
        
        /// <summary>
        /// 获取AI信息
        /// </summary>
        public string GetAIInfo()
        {
            if (currentAI == null) return "无AI";
            
            return $"类型: {currentAI.GetBehaviorName()}, 难度: {currentAI.GetDifficultyName()}";
        }
    }
}
