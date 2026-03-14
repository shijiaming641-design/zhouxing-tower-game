using System;
using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Core
{
    /// <summary>
    /// 战斗流程管理器 - 负责整个战斗流程的控制
    /// </summary>
    public class BattleSystem : MonoBehaviour
    {
        public static BattleSystem Instance { get; private set; }

        [Header("战斗参与者")]
        public Combatant player;
        public Combatant enemy;

        [Header("战斗状态")]
        public BattlePhase currentPhase = BattlePhase.Ready;
        public int currentRound = 0;
        public int playerWinStreak = 0;
        public int enemyWinStreak = 0;

        [Header("系统引用")]
        public DamageCalculator damageCalculator;
        public EnemyAI enemyAI;
        public RageSystem playerRageSystem;
        public RageSystem enemyRageSystem;

        private List<StatusEffect> playerStatusEffects = new List<StatusEffect>();
        private List<StatusEffect> enemyStatusEffects = new List<StatusEffect>();

        public event Action<Combatant, Combatant, int> OnDamageDealt;
        public event Action<Combatant> OnCombatantDefeated;
        public event Action<BattlePhase> OnPhaseChanged;

        private void Awake()
        {
            Instance = this;
            if (damageCalculator == null) damageCalculator = gameObject.AddComponent<DamageCalculator>();
            if (enemyAI == null) enemyAI = gameObject.AddComponent<EnemyAI>();
            if (playerRageSystem == null) playerRageSystem = gameObject.AddComponent<RageSystem>();
            if (enemyRageSystem == null) enemyRageSystem = gameObject.AddComponent<RageSystem>();
        }

        private void Start()
        {
            StartBattle();
        }

        /// <summary>
        /// 开始战斗
        /// </summary>
        public void StartBattle()
        {
            currentRound = 0;
            playerWinStreak = 0;
            enemyWinStreak = 0;
            playerStatusEffects.Clear();
            enemyStatusEffects.Clear();
            
            playerRageSystem.Initialize(player);
            enemyRageSystem.Initialize(enemy);
            
            SetPhase(BattlePhase.PlayerTurn);
        }

        /// <summary>
        /// 玩家出拳
        /// </summary>
        public void PlayerAttack(RockPaperScissors choice)
        {
            if (currentPhase != BattlePhase.PlayerTurn) return;

            // 敌人决策
            RockPaperScissors enemyChoice = enemyAI.Decide(player, enemy, choice);
            
            // 判定结果
            RoundResult result = DetermineResult(choice, enemyChoice);
            
            // 处理回合
            ProcessRound(result, choice, enemyChoice);
        }

        /// <summary>
        /// 判定回合结果
        /// </summary>
        private RoundResult DetermineResult(RockPaperScissors playerChoice, RockPaperScissors enemyChoice)
        {
            if (playerChoice == enemyChoice)
                return RoundResult.Draw;
            
            if ((playerChoice == RockPaperScissors.Rock && enemyChoice == RockPaperScissors.Scissors) ||
                (playerChoice == RockPaperScissors.Paper && enemyChoice == RockPaperScissors.Rock) ||
                (playerChoice == RockPaperScissors.Scissors && enemyChoice == RockPaperScissors.Paper))
                return RoundResult.PlayerWin;
            
            return RoundResult.EnemyWin;
        }

        /// <summary>
        /// 处理回合逻辑
        /// </summary>
        private void ProcessRound(RoundResult result, RockPaperScissors playerChoice, RockPaperScissors enemyChoice)
        {
            SetPhase(BattlePhase.Resolving);

            // 更新连胜
            UpdateWinStreak(result);

            // 计算伤害
            int playerDamage = 0;
            int enemyDamage = 0;

            if (result == RoundResult.PlayerWin)
            {
                playerDamage = damageCalculator.CalculateDamage(player, enemy, result, playerWinStreak);
                enemy.TakeDamage(playerDamage);
                playerRageSystem.OnWin();
                enemyRageSystem.OnLose();
            }
            else if (result == RoundResult.EnemyWin)
            {
                enemyDamage = damageCalculator.CalculateDamage(enemy, player, result, enemyWinStreak);
                player.TakeDamage(enemyDamage);
                enemyRageSystem.OnWin();
                playerRageSystem.OnLose();
            }
            else // Draw
            {
                // 平局各造成少量伤害
                playerDamage = damageCalculator.CalculateDamage(player, enemy, result, playerWinStreak);
                enemyDamage = damageCalculator.CalculateDamage(enemy, player, result, enemyWinStreak);
                player.TakeDamage(playerDamage);
                enemy.TakeDamage(enemyDamage);
            }

            // 触发事件
            if (playerDamage > 0) OnDamageDealt?.Invoke(player, enemy, playerDamage);
            if (enemyDamage > 0) OnDamageDealt?.Invoke(enemy, player, enemyDamage);

            // 检查死亡
            if (player.IsDead)
            {
                OnCombatantDefeated?.Invoke(player);
                SetPhase(BattlePhase.Ended);
                return;
            }
            if (enemy.IsDead)
            {
                OnCombatantDefeated?.Invoke(enemy);
                SetPhase(BattlePhase.Ended);
                return;
            }

            // 更新状态效果
            UpdateStatusEffects(player, playerStatusEffects);
            UpdateStatusEffects(enemy, enemyStatusEffects);

            currentRound++;
            SetPhase(BattlePhase.PlayerTurn);
        }

        /// <summary>
        /// 更新连胜计数
        /// </summary>
        private void UpdateWinStreak(RoundResult result)
        {
            if (result == RoundResult.PlayerWin)
            {
                playerWinStreak++;
                enemyWinStreak = 0;
            }
            else if (result == RoundResult.EnemyWin)
            {
                enemyWinStreak++;
                playerWinStreak = 0;
            }
            else
            {
                playerWinStreak = 0;
                enemyWinStreak = 0;
            }
        }

        /// <summary>
        /// 更新状态效果
        /// </summary>
        private void UpdateStatusEffects(Combatant target, List<StatusEffect> effects)
        {
            for (int i = effects.Count - 1; i >= 0; i--)
            {
                effects[i].OnRoundEnd(target);
                if (effects[i].IsExpired)
                {
                    effects.RemoveAt(i);
                }
            }
        }

        /// <summary>
        /// 添加状态效果
        /// </summary>
        public void AddStatusEffect(Combatant target, StatusEffect effect)
        {
            if (target == player)
                playerStatusEffects.Add(effect);
            else
                enemyStatusEffects.Add(effect);
            
            effect.OnApply(target);
        }

        private void SetPhase(BattlePhase phase)
        {
            currentPhase = phase;
            OnPhaseChanged?.Invoke(phase);
        }

        /// <summary>
        /// 获取当前连胜加成
        /// </summary>
        public float GetWinStreakBonus(int streak)
        {
            return DamageCalculator.GetWinStreakBonus(streak);
        }

        /// <summary>
        /// 获取克制系数
        /// </summary>
        public float GetTypeAdvantage(RockPaperScissors attacker, RockPaperScissors defender)
        {
            return DamageCalculator.GetTypeAdvantage(attacker, defender);
        }
    }

    /// <summary>
    /// 战斗阶段
    /// </summary>
    public enum BattlePhase
    {
        Ready,
        PlayerTurn,
        Resolving,
        EnemyTurn,
        Ended
    }

    /// <summary>
    /// 回合结果
    /// </summary>
    public enum RoundResult
    {
        PlayerWin,
        EnemyWin,
        Draw
    }

    /// <summary>
    /// 猜拳选择
    /// </summary>
    public enum RockPaperScissors
    {
        Rock = 0,     // 石头
        Paper = 1,    // 布
        Scissors = 2  // 剪刀
    }

    /// <summary>
    /// 战斗参与者
    /// </summary>
    [System.Serializable]
    public class Combatant
    {
        public string name;
        public int maxHealth = 100;
        public int currentHealth;
        public int attack = 20;
        public int defense = 5;
        
        public bool IsDead => currentHealth <= 0;

        public Combatant(string name, int health, int attack, int defense)
        {
            this.name = name;
            this.maxHealth = health;
            this.currentHealth = health;
            this.attack = attack;
            this.defense = defense;
        }

        public void TakeDamage(int damage)
        {
            currentHealth = Mathf.Max(0, currentHealth - damage);
        }

        public void Heal(int amount)
        {
            currentHealth = Mathf.Min(maxHealth, currentHealth + amount);
        }

        public void Reset()
        {
            currentHealth = maxHealth;
        }
    }
}
