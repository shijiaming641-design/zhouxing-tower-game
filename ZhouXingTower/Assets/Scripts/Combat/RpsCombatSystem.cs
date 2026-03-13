using UnityEngine;
using ZhouXing.Data;

namespace ZhouXing.Combat
{
    /// <summary>
    /// 猜拳战斗系统核心
    /// </summary>
    public class RpsCombatSystem : MonoBehaviour
    {
        public static RpsCombatSystem Instance { get; private set; }

        // 战斗状态
        public bool isCombatActive = false;
        public int currentRound = 0;
        public int playerWinStreak = 0;

        // 战斗事件
        public System.Action<CombatRoundResult> OnRoundComplete;
        public System.Action<CombatResult> OnCombatEnd;

        private void Awake()
        {
            Instance = this;
        }

        /// <summary>
        /// 计算猜拳结果
        /// </summary>
        public static CombatResult CalculateResult(RpsType playerChoice, RpsType enemyChoice)
        {
            if (playerChoice == enemyChoice)
                return CombatResult.Draw;

            if ((playerChoice == RpsType.Rock && enemyChoice == RpsType.Scissors) ||
                (playerChoice == RpsType.Scissors && enemyChoice == RpsType.Paper) ||
                (playerChoice == RpsType.Paper && enemyChoice == RpsType.Rock))
            {
                return CombatResult.Win;
            }

            return CombatResult.Lose;
        }

        /// <summary>
        /// 计算克制系数
        /// </summary>
        public static float Get克制系数(CombatResult result)
        {
            switch (result)
            {
                case CombatResult.Win:
                    return 1.5f;
                case CombatResult.Draw:
                    return 0.75f;
                case CombatResult.Lose:
                    return 0.5f;
                default:
                    return 1.0f;
            }
        }

        /// <summary>
        /// 获取连胜加成
        /// </summary>
        public static float Get连胜加成(int winStreak)
        {
            if (winStreak >= 7) return 2.0f;
            if (winStreak >= 5) return 1.5f;
            if (winStreak >= 3) return 1.2f;
            return 1.0f;
        }

        /// <summary>
        /// 计算伤害
        /// </summary>
        public static int CalculateDamage(CharacterStats attacker, CharacterStats defender, CombatResult result, int winStreak)
        {
            float baseDamage = attacker.attack - defender.defense;
            if (baseDamage < 1) baseDamage = 1;

            float 克制系数 = Get克制系数(result);
            float 连胜加成 = Get连胜加成(winStreak);
            float 随机波动 = Random.Range(0.9f, 1.1f);

            int finalDamage = Mathf.RoundToInt(baseDamage * 克制系数 * 连胜加成 * 随机波动);
            return Mathf.Max(1, finalDamage);
        }

        /// <summary>
        /// 处理一回合战斗
        /// </summary>
        public CombatRoundResult ProcessRound(RpsType playerChoice, RpsType enemyChoice, CharacterStats playerStats, CharacterStats enemyStats)
        {
            currentRound++;

            CombatResult result = CalculateResult(playerChoice, enemyChoice);
            
            int playerDamage = 0;
            int enemyDamage = 0;

            // 计算伤害
            if (result == CombatResult.Win)
            {
                playerWinStreak++;
                enemyDamage = CalculateDamage(playerStats, enemyStats, result, playerWinStreak);
                enemyStats.currentHealth -= enemyDamage;
                playerStats.currentRage += 10;
            }
            else if (result == CombatResult.Lose)
            {
                playerWinStreak = 0;
                playerDamage = CalculateDamage(enemyStats, playerStats, CombatResult.Win, 0);
                playerStats.currentHealth -= playerDamage;
                playerStats.currentRage += 5;
            }
            else // 平局
            {
                playerWinStreak = 0;
                // 平局各造成50%伤害
                int halfPlayerDamage = CalculateDamage(enemyStats, playerStats, CombatResult.Win, 0) / 2;
                int halfEnemyDamage = CalculateDamage(playerStats, enemyStats, CombatResult.Win, 0) / 2;
                playerStats.currentHealth -= halfPlayerDamage;
                enemyStats.currentHealth -= halfEnemyDamage;
                playerStats.currentRage += 7;
            }

            // 确保生命值不为负
            playerStats.currentHealth = Mathf.Max(0, playerStats.currentHealth);
            enemyStats.currentHealth = Mathf.Max(0, enemyStats.currentHealth);

            // 检查连胜特殊效果
            bool triggerTempCard = (playerWinStreak == 3);
            bool heal10Percent = (playerWinStreak == 5);
            bool extraAction = (playerWinStreak == 7);

            var roundResult = new CombatRoundResult
            {
                roundNumber = currentRound,
                playerChoice = playerChoice,
                enemyChoice = enemyChoice,
                result = result,
                playerDamage = playerDamage,
                enemyDamage = enemyDamage,
                playerWinStreak = playerWinStreak,
                playerCurrentHealth = playerStats.currentHealth,
                enemyCurrentHealth = enemyStats.currentHealth,
                playerRage = playerStats.currentRage,
                enemyRage = enemyStats.currentRage,
                triggerTempCard = triggerTempCard,
                heal10Percent = heal10Percent,
                extraAction = extraAction
            };

            OnRoundComplete?.Invoke(roundResult);

            // 检查战斗结束
            if (playerStats.currentHealth <= 0)
            {
                isCombatActive = false;
                OnCombatEnd?.Invoke(CombatResult.Lose);
            }
            else if (enemyStats.currentHealth <= 0)
            {
                isCombatActive = false;
                OnCombatEnd?.Invoke(CombatResult.Win);
            }

            return roundResult;
        }
    }

    /// <summary>
    /// 回合战斗结果
    /// </summary>
    public class CombatRoundResult
    {
        public int roundNumber;
        public RpsType playerChoice;
        public RpsType enemyChoice;
        public CombatResult result;
        public int playerDamage;
        public int enemyDamage;
        public int playerWinStreak;
        public int playerCurrentHealth;
        public int enemyCurrentHealth;
        public int playerRage;
        public int enemyRage;
        
        // 连胜特殊效果
        public bool triggerTempCard = false;
        public bool heal10Percent = false;
        public bool extraAction = false;
    }
}
