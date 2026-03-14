using System;
using UnityEngine;
using ZhouXing.Core;

namespace ZhouXing.Core
{
    /// <summary>
    /// 伤害计算器 - 实现战斗系统要求的伤害公式
    /// </summary>
    public class DamageCalculator : MonoBehaviour
    {
        [Header("伤害参数")]
        [SerializeField] private float baseDamageMultiplier = 1.0f;
        [SerializeField] private float minRandomFactor = 0.9f;
        [SerializeField] private float maxRandomFactor = 1.1f;

        private System.Random random = new System.Random();

        /// <summary>
        /// 计算伤害
        /// 公式: (攻击力-防御力) × 克制系数 × 连胜加成 × 随机波动(0.9-1.1)
        /// </summary>
        /// <param name="attacker">攻击者</param>
        /// <param name="defender">防御者</param>
        /// <param name="result">回合结果</param>
        /// <param name="winStreak">当前连胜次数</param>
        /// <returns>最终伤害值</returns>
        public int CalculateDamage(Combatant attacker, Combatant defender, RoundResult result, int winStreak)
        {
            if (attacker == null || defender == null) return 0;

            // 1. 基础伤害 (攻击力 - 防御力)，最少为1
            float baseDamage = Mathf.Max(1, attacker.attack - defender.defense);

            // 2. 克制系数
            // 注意: 这里需要传入攻击者的选择和防御者的选择来计算克制
            // 由于在BattleSystem中已经判定结果，这里使用结果来推断克制
            float typeAdvantage = GetTypeAdvantageFromResult(result);

            // 3. 连胜加成
            float winStreakBonus = GetWinStreakBonus(winStreak);

            // 4. 随机波动 (0.9-1.1)
            float randomFactor = GetRandomFactor();

            // 最终伤害计算
            float finalDamage = baseDamage * typeAdvantage * winStreakBonus * randomFactor * baseDamageMultiplier;

            return Mathf.RoundToInt(finalDamage);
        }

        /// <summary>
        /// 根据回合结果获取克制系数
        /// 胜利: 1.5x, 失败: 0.5x, 平局: 0.75x
        /// </summary>
        public float GetTypeAdvantageFromResult(RoundResult result)
        {
            switch (result)
            {
                case RoundResult.PlayerWin:
                case RoundResult.EnemyWin:
                    return 1.5f;
                case RoundResult.Draw:
                    return 0.75f;
                default:
                    return 1.0f;
            }
        }

        /// <summary>
        /// 计算克制系数 - 根据攻击者和防御者的出拳
        /// 胜利: 1.5x, 失败: 0.5x, 平局: 0.75x
        /// </summary>
        public static float GetTypeAdvantage(RockPaperScissors attackerChoice, RockPaperScissors defenderChoice)
        {
            if (attackerChoice == defenderChoice)
                return 0.75f; // 平局

            bool isWin = (attackerChoice == RockPaperScissors.Rock && defenderChoice == RockPaperScissors.Scissors) ||
                         (attackerChoice == RockPaperScissors.Paper && defenderChoice == RockPaperScissors.Rock) ||
                         (attackerChoice == RockPaperScissors.Scissors && defenderChoice == RockPaperScissors.Paper);

            return isWin ? 1.5f : 0.5f;
        }

        /// <summary>
        /// 获取连胜加成
        /// 3连胜 +20%, 5连胜 +50%, 7连胜 +100%
        /// </summary>
        public static float GetWinStreakBonus(int winStreak)
        {
            if (winStreak >= 7)
                return 2.0f; // 100% 加成
            if (winStreak >= 5)
                return 1.5f; // 50% 加成
            if (winStreak >= 3)
                return 1.2f; // 20% 加成
            
            return 1.0f; // 无加成
        }

        /// <summary>
        /// 获取随机波动因子 (0.9-1.1)
        /// </summary>
        public float GetRandomFactor()
        {
            // 使用Unity的Random实现一致性
            return UnityEngine.Random.Range(minRandomFactor, maxRandomFactor);
        }

        /// <summary>
        /// 使用系统Random获取随机因子
        /// </summary>
        public float GetRandomFactorSeeded()
        {
            return (float)(random.NextDouble() * (maxRandomFactor - minRandomFactor) + minRandomFactor);
        }

        /// <summary>
        /// 暴击伤害计算 (可用于特殊技能)
        /// </summary>
        public int CalculateCriticalDamage(Combatant attacker, Combatant defender, RoundResult result, int winStreak, float critMultiplier = 1.5f)
        {
            int normalDamage = CalculateDamage(attacker, defender, result, winStreak);
            return Mathf.RoundToInt(normalDamage * critMultiplier);
        }

        /// <summary>
        /// 防御加成计算 (用于特殊防御状态)
        /// </summary>
        public int CalculateReducedDamage(Combatant attacker, Combatant defender, RoundResult result, int winStreak, float defenseBonus = 0.5f)
        {
            int normalDamage = CalculateDamage(attacker, defender, result, winStreak);
            return Mathf.RoundToInt(normalDamage * (1 - defenseBonus));
        }

        /// <summary>
        /// 获取伤害描述
        /// </summary>
        public string GetDamageDescription(Combatant attacker, Combatant defender, RoundResult result, int winStreak)
        {
            float baseDamage = Mathf.Max(1, attacker.attack - defender.defense);
            float typeAdv = GetTypeAdvantageFromResult(result);
            float streakBonus = GetWinStreakBonus(winStreak);
            float randomFactor = GetRandomFactor();

            float minDamage = baseDamage * typeAdvantageFromResultMin(result) * streakBonus * minRandomFactor;
            float maxDamage = baseDamage * typeAdvantageFromResultMax(result) * streakBonus * maxRandomFactor;

            return $"基础伤害: {baseDamage} × 克制: {typeAdv} × 连胜: {streakBonus} × 随机: {randomFactor:F2} = 约 {Mathf.RoundToInt(baseDamage * typeAdv * streakBonus * randomFactor)}";
        }

        private float typeAdvantageFromResultMin(RoundResult result)
        {
            switch (result)
            {
                case RoundResult.PlayerWin:
                case RoundResult.EnemyWin:
                    return 1.5f;
                case RoundResult.Draw:
                    return 0.75f;
                default:
                    return 1.0f;
            }
        }

        private float typeAdvantageFromResultMax(RoundResult result)
        {
            return typeAdvantageFromResultMin(result);
        }
    }
}
