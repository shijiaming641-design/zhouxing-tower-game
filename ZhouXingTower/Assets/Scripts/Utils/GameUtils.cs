using UnityEngine;

namespace ZhouXing.Utils
{
    /// <summary>
    /// 通用工具类
    /// </summary>
    public static class GameUtils
    {
        /// <summary>
        /// 获取RPS手势的中文名称
        /// </summary>
        public static string GetRpsName(Rps.RpsType type)
        {
            switch (type)
            {
                case Rps.RpsType.Rock:
                    return "石头";
                case Rps.RpsType.Scissors:
                    return "剪刀";
                case Rps.RpsType.Paper:
                    return "布";
                default:
                    return "未知";
            }
        }

        /// <summary>
        /// 获取RPS手势的emoji
        /// </summary>
        public static string GetRpsEmoji(Rps.RpsType type)
        {
            switch (type)
            {
                case Rps.RpsType.Rock:
                    return "✊";
                case Rps.RpsType.Scissors:
                    return "✌️";
                case Rps.RpsType.Paper:
                    return "✋";
                default:
                    return "❓";
            }
        }

        /// <summary>
        /// 获取战斗结果的中文描述
        /// </summary>
        public static string GetResultText(Rps.CombatResult result)
        {
            switch (result)
            {
                case Rps.CombatResult.Win:
                    return "胜利！";
                case Rps.CombatResult.Lose:
                    return "失败...";
                case Rps.CombatResult.Draw:
                    return "平局";
                default:
                    return "";
            }
        }

        /// <summary>
        /// 格式化数字（千位分隔符）
        /// </summary>
        public static string FormatNumber(int number)
        {
            return number.ToString("N0");
        }

        /// <summary>
        /// 格式化百分比
        /// </summary>
        public static string FormatPercent(float value)
        {
            return $"{value * 100:F1}%";
        }
    }

    /// <summary>
    /// 调试工具类
    /// </summary>
    public static class DebugUtils
    {
        /// <summary>
        /// 打印角色信息
        /// </summary>
        public static void LogCharacter(Data.CharacterStats stats)
        {
            if (stats == null)
            {
                Debug.Log("角色为空");
                return;
            }

            Debug.Log($"=== {stats.characterName} ===");
            Debug.Log($"HP: {stats.currentHealth}/{stats.maxHealth}");
            Debug.Log($"Attack: {stats.attack}, Defense: {stats.defense}");
            Debug.Log($"Rage: {stats.currentRage}/{stats.maxRage}");
        }

        /// <summary>
        /// 打印战斗结果
        /// </summary>
        public static void LogCombatRound(Combat.CombatRoundResult result)
        {
            Debug.Log($"=== 第{result.roundNumber}回合 ===");
            Debug.Log($"玩家: {Utils.GameUtils.GetRpsName(result.playerChoice)} vs 敌人: {Utils.GameUtils.GetRpsName(result.enemyChoice)}");
            Debug.Log($"结果: {Utils.GameUtils.GetResultText(result.result)}");
            Debug.Log($"玩家伤害: {result.playerDamage}, 敌人伤害: {result.enemyDamage}");
            Debug.Log($"玩家HP: {result.playerCurrentHealth}, 敌人HP: {result.enemyCurrentHealth}");
            Debug.Log($"连胜: {result.playerWinStreak}");
        }
    }
}
