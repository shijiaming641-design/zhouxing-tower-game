using UnityEngine;
using ZhouXing.Data;

namespace ZhouXing.Enemies
{
    /// <summary>
    /// 敌人生成器
    /// </summary>
    public class EnemySpawner : MonoBehaviour
    {
        [Header("敌人配置")]
        public EnemyAIData[] enemyTemplates;

        [Header("生成设置")]
        public Transform spawnPoint;
        public int baseHealth = 50;
        public int healthPerLevel = 10;
        public int baseAttack = 8;
        public int attackPerLevel = 2;

        private int currentTowerLevel = 1;

        private void Start()
        {
            if (GameManager.Instance != null)
            {
                currentTowerLevel = GameManager.Instance.currentTowerLevel;
            }

            // 如果没有预设，使用默认敌人
            if (enemyTemplates == null || enemyTemplates.Length == 0)
            {
                enemyTemplates = new EnemyAIData[]
                {
                    CreateBasicEnemy("普通敌人", 33, 33, 34, 5),
                    CreateAggressiveEnemy("激进敌人", 45, 30, 25, 8),
                    CreateDefensiveEnemy("保守敌人", 20, 30, 50, 3)
                };
            }

            SpawnEnemy();
        }

        /// <summary>
        /// 生成敌人
        /// </summary>
        public void SpawnEnemy()
        {
            // 随机选择敌人类型
            int randomIndex = Random.Range(0, enemyTemplates.Length);
            EnemyAIData selectedEnemy = enemyTemplates[randomIndex];

            // 创建敌人游戏对象
            GameObject enemyObj = new GameObject(selectedEnemy.enemyName);
            
            if (spawnPoint != null)
            {
                enemyObj.transform.position = spawnPoint.position;
            }

            // 添加敌人组件
            Enemy enemy = enemyObj.AddComponent<Enemy>();
            enemy.enemyData = selectedEnemy;
            enemy.stats = new CharacterStats
            {
                characterId = selectedEnemy.enemyId,
                characterName = selectedEnemy.enemyName,
                maxHealth = baseHealth + currentTowerLevel * healthPerLevel,
                currentHealth = baseHealth + currentTowerLevel * healthPerLevel,
                attack = baseAttack + currentTowerLevel * attackPerLevel,
                defense = 1,
                maxRage = 100,
                currentRage = 0
            };

            // 添加AI组件
            EnemyAI ai = enemyObj.AddComponent<EnemyAI>();
            ai.aiData = selectedEnemy;
            ai.stats = enemy.stats;

            Debug.Log($"生成敌人: {selectedEnemy.enemyName} (Level {currentTowerLevel})");
        }

        /// <summary>
        /// 创建基础敌人数据
        /// </summary>
        private EnemyAIData CreateBasicEnemy(string name, int rock, int scissors, int paper, int aggression)
        {
            return new EnemyAIData
            {
                enemyId = "enemy_" + name.GetHashCode(),
                enemyName = name,
                rock倾向 = rock,
                scissors倾向 = scissors,
                paper倾向 = paper,
                aggressionLevel = aggression
            };
        }

        /// <summary>
        /// 创建激进型敌人
        /// </summary>
        private EnemyAIData CreateAggressiveEnemy(string name, int rock, int scissors, int paper, int aggression)
        {
            return CreateBasicEnemy(name, rock, scissors, paper, aggression);
        }

        /// <summary>
        /// 创建保守型敌人
        /// </summary>
        private EnemyAIData CreateDefensiveEnemy(string name, int rock, int scissors, int paper, int aggression)
        {
            return CreateBasicEnemy(name, rock, scissors, paper, aggression);
        }
    }
}
