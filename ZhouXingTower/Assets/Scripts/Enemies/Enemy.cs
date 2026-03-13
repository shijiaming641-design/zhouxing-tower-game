using UnityEngine;
using ZhouXing.Data;
using ZhouXing.Rps;

namespace ZhouXing.Enemies
{
    /// <summary>
    /// 敌人基础类
    /// </summary>
    public class Enemy : MonoBehaviour
    {
        public EnemyAIData enemyData;
        public CharacterStats stats;
        public EnemyAI ai;

        [Header("视觉")]
        public Sprite enemySprite;
        public Color enemyColor = Color.red;

        private void Start()
        {
            // 初始化AI
            if (ai == null)
            {
                ai = gameObject.AddComponent<EnemyAI>();
            }
            
            if (enemyData == null)
            {
                enemyData = new EnemyAIData
                {
                    enemyId = "enemy_001",
                    enemyName = "普通敌人",
                    rock倾向 = 33,
                    scissors倾向 = 33,
                    paper倾向 = 33,
                    aggressionLevel = 5
                };
            }

            // 初始化属性
            if (stats == null)
            {
                stats = new CharacterStats
                {
                    characterId = enemyData.enemyId,
                    characterName = enemyData.enemyName,
                    maxHealth = 50 + GameManager.Instance.currentTowerLevel * 10,
                    currentHealth = 50 + GameManager.Instance.currentTowerLevel * 10,
                    attack = 8 + GameManager.Instance.currentTowerLevel * 2,
                    defense = 1,
                    maxRage = 100,
                    currentRage = 0
                };
            }

            // 设置AI数据
            ai.aiData = enemyData;
            ai.stats = stats;
        }

        /// <summary>
        /// 受到伤害
        /// </summary>
        public void TakeDamage(int damage)
        {
            stats.currentHealth -= damage;
            stats.currentHealth = Mathf.Max(0, stats.currentHealth);

            Debug.Log($"{stats.characterName} 受到 {damage} 伤害，剩余 {stats.currentHealth} HP");

            if (stats.currentHealth <= 0)
            {
                OnDeath();
            }
        }

        /// <summary>
        /// 死亡处理
        /// </summary>
        private void OnDeath()
        {
            Debug.Log($"{stats.characterName} 被击败！");
            
            // 通知游戏管理器
            if (GameManager.Instance != null)
            {
                GameManager.Instance.OnCombatVictory();
            }

            // 销毁敌人
            Destroy(gameObject, 0.5f);
        }
    }
}
