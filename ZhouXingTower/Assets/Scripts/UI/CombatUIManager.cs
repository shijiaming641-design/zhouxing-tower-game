using UnityEngine;
using UnityEngine.UI;
using ZhouXing.Combat;
using ZhouXing.Rps;

namespace ZhouXing.UI
{
    /// <summary>
    /// 战斗UI管理器
    /// </summary>
    public class CombatUIManager : MonoBehaviour
    {
        [Header("玩家信息")]
        public Text playerNameText;
        public Slider playerHealthSlider;
        public Text playerHealthText;
        public Slider playerRageSlider;
        public Text playerRageText;

        [Header("敌人信息")]
        public Text enemyNameText;
        public Slider enemyHealthSlider;
        public Text enemyHealthText;
        public Text enemyTendencyText;

        [Header("战斗控制")]
        public Button rockButton;
        public Button scissorsButton;
        public Button paperButton;
        public Text roundInfoText;
        public Text winStreakText;
        public Text combatResultText;

        [Header("效果显示")]
        public Text damageText;
        public GameObject winEffect;
        public GameObject loseEffect;

        private PlayerController player;
        private EnemyAI enemy;
        private RpsCombatSystem combatSystem;

        private void Start()
        {
            combatSystem = FindObjectOfType<RpsCombatSystem>();
            player = FindObjectOfType<PlayerController>();
            enemy = FindObjectOfType<EnemyAI>();

            // 绑定按钮事件
            rockButton.onClick.AddListener(() => OnPlayerChoice(RpsType.Rock));
            scissorsButton.onClick.AddListener(() => OnPlayerChoice(RpsType.Scissors));
            paperButton.onClick.AddListener(() => OnPlayerChoice(RpsType.Paper));

            // 绑定战斗事件
            combatSystem.OnRoundComplete += OnRoundComplete;
            combatSystem.OnCombatEnd += OnCombatEnd;

            UpdateUI();
        }

        private void OnDestroy()
        {
            if (combatSystem != null)
            {
                combatSystem.OnRoundComplete -= OnRoundComplete;
                combatSystem.OnCombatEnd -= OnCombatEnd;
            }
        }

        /// <summary>
        /// 玩家选择手势
        /// </summary>
        private void OnPlayerChoice(RpsType choice)
        {
            if (!combatSystem.isCombatActive) return;

            // 获取敌人选择
            RpsType enemyChoice = enemy.GetEnemyChoice();

            // 处理回合
            combatSystem.ProcessRound(choice, enemyChoice, player.stats, enemy.stats);

            // 更新敌人倾向
            enemy.UpdateTendency();
        }

        /// <summary>
        /// 回合完成回调
        /// </summary>
        private void OnRoundComplete(CombatRoundResult result)
        {
            UpdateUI();
            ShowRoundEffect(result);

            // 处理连胜特殊效果
            if (result.heal10Percent)
            {
                int healAmount = player.stats.maxHealth / 10;
                player.Heal(healAmount);
                Debug.Log($"连胜5次，治疗 {healAmount} 点");
            }
        }

        /// <summary>
        /// 战斗结束回调
        /// </summary>
        private void OnCombatEnd(CombatResult result)
        {
            combatResultText.gameObject.SetActive(true);
            
            if (result == CombatResult.Win)
            {
                combatResultText.text = "胜利！";
                combatResultText.color = Color.green;
                if (winEffect != null) winEffect.SetActive(true);
            }
            else
            {
                combatResultText.text = "失败...";
                combatResultText.color = Color.red;
                if (loseEffect != null) loseEffect.SetActive(true);
            }
        }

        /// <summary>
        /// 更新UI显示
        /// </summary>
        private void UpdateUI()
        {
            if (player == null || enemy == null) return;

            // 玩家信息
            if (playerNameText != null) playerNameText.text = player.stats.characterName;
            if (playerHealthSlider != null) 
                playerHealthSlider.maxValue = player.stats.maxHealth;
            if (playerHealthSlider != null) 
                playerHealthSlider.value = player.stats.currentHealth;
            if (playerHealthText != null) 
                playerHealthText.text = $"{player.stats.currentHealth}/{player.stats.maxHealth}";
            
            if (playerRageSlider != null) 
                playerRageSlider.maxValue = player.stats.maxRage;
            if (playerRageSlider != null) 
                playerRageSlider.value = player.stats.currentRage;
            if (playerRageText != null) 
                playerRageText.text = $"{player.stats.currentRage}/{player.stats.maxRage}";

            // 敌人信息
            if (enemyNameText != null) enemyNameText.text = enemy.stats.characterName;
            if (enemyHealthSlider != null) 
                enemyHealthSlider.maxValue = enemy.stats.maxHealth;
            if (enemyHealthSlider != null) 
                enemyHealthSlider.value = enemy.stats.currentHealth;
            if (enemyHealthText != null) 
                enemyHealthText.text = $"{enemy.stats.currentHealth}/{enemy.stats.maxHealth}";
            if (enemyTendencyText != null) 
                enemyTendencyText.text = enemy.GetTendencyText();

            // 回合信息
            if (roundInfoText != null) 
                roundInfoText.text = $"回合: {combatSystem.currentRound}";
            if (winStreakText != null) 
                winStreakText.text = $"连胜: {playerWinStreak}";
        }

        private int playerWinStreak = 0;

        /// <summary>
        /// 显示回合效果
        /// </summary>
        private void ShowRoundEffect(CombatRoundResult result)
        {
            playerWinStreak = result.playerWinStreak;

            string effectText = "";
            
            if (result.result == CombatResult.Win)
            {
                effectText = $"胜利！造成 {result.enemyDamage} 伤害";
            }
            else if (result.result == CombatResult.Lose)
            {
                effectText = $"失败...受到 {result.playerDamage} 伤害";
            }
            else
            {
                effectText = $"平局！";
            }

            if (result.triggerTempCard)
                effectText += "\n获得临时卡牌！";
            if (result.heal10Percent)
                effectText += "\n治疗10%生命！";
            if (result.extraAction)
                effectText += "\n额外行动一次！";

            if (damageText != null)
            {
                damageText.text = effectText;
            }
        }
    }
}
