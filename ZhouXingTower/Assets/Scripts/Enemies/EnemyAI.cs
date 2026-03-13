using UnityEngine;
using ZhouXing.Data;
using ZhouXing.Rps;

namespace ZhouXing.Enemies
{
    /// <summary>
    /// 敌人AI控制器
    /// </summary>
    public class EnemyAI : MonoBehaviour
    {
        public EnemyAIData aiData;
        public CharacterStats stats;

        // 倾向显示（可以被玩家观察）
        [Range(0, 100)]
        public int displayedRock倾向;
        public int displayedScissors倾向;
        public int displayedPaper倾向;

        private void Start()
        {
            // 初始化显示倾向
            displayedRock倾向 = aiData.rock倾向;
            displayedScissors倾向 = aiData.scissors倾向;
            displayedPaper倾向 = aiData.paper倾向;
        }

        /// <summary>
        /// 获取敌人选择的手势
        /// </summary>
        public RpsType GetEnemyChoice()
        {
            // 基础随机选择
            int total = displayedRock倾向 + displayedScissors倾向 + displayedPaper倾向;
            int randomValue = Random.Range(0, total);

            if (randomValue < displayedRock倾向)
                return RpsType.Rock;
            else if (randomValue < displayedRock倾向 + displayedScissors倾向)
                return RpsType.Scissors;
            else
                return RpsType.Paper;
        }

        /// <summary>
        /// 根据玩家选择获取克制选项
        /// </summary>
        public RpsType GetCounterChoice(RpsType playerChoice)
        {
            // 高级AI：30%几率预判玩家并克制
            if (Random.Range(0, 100) < 30)
            {
                switch (playerChoice)
                {
                    case RpsType.Rock:
                        return RpsType.Paper;
                    case RpsType.Scissors:
                        return RpsType.Rock;
                    case RpsType.Paper:
                        return RpsType.Scissors;
                }
            }

            return GetEnemyChoice();
        }

        /// <summary>
        /// 更新敌人倾向（根据行为模式）
        /// </summary>
        public void UpdateTendency()
        {
            // 根据 агрессия 调整倾向
            int aggression = aiData.aggressionLevel;

            // 高攻击性：增加石头倾向（主动攻击）
            if (aggression >= 7)
            {
                displayedRock倾向 = Mathf.Clamp(aiData.rock倾向 + 20, 0, 80);
                displayedScissors倾向 = Mathf.Clamp(aiData.scissors倾向 - 10, 10, 50);
                displayedPaper倾向 = 100 - displayedRock倾向 - displayedScissors倾向;
            }
            // 低攻击性：增加布倾向（保守）
            else if (aggression <= 3)
            {
                displayedPaper倾向 = Mathf.Clamp(aiData.paper倾向 + 20, 0, 80);
                displayedScissors倾向 = Mathf.Clamp(aiData.scissors倾向 - 10, 10, 50);
                displayedRock倾向 = 100 - displayedPaper倾向 - displayedScissors倾向;
            }
        }

        /// <summary>
        /// 获取显示给玩家的倾向信息
        /// </summary>
        public string GetTendencyText()
        {
            return $"石头: {displayedRock倾向}% | 剪刀: {displayedScissors倾向}% | 布: {displayedPaper倾向}%";
        }
    }
}
