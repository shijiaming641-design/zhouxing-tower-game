using UnityEngine;

namespace ZhouXing.Data
{
    /// <summary>
    /// 角色属性数据
    /// </summary>
    [System.Serializable]
    public class CharacterStats
    {
        public string characterId;
        public string characterName;
        public int maxHealth = 100;
        public int currentHealth;
        public int attack = 10;
        public int defense = 2;
        public int maxRage = 100;
        public int currentRage;
        
        public CharacterStats()
        {
            currentHealth = maxHealth;
            currentRage = 0;
        }

        public CharacterStats Clone()
        {
            return new CharacterStats
            {
                characterId = characterId,
                characterName = characterName,
                maxHealth = maxHealth,
                currentHealth = currentHealth,
                attack = attack,
                defense = defense,
                maxRage = maxRage,
                currentRage = currentRage
            };
        }
    }

    /// <summary>
    /// 技能数据
    /// </summary>
    [System.Serializable]
    public class SkillData
    {
        public string skillId;
        public string skillName;
        public string description;
        public int rageCost;
        public int cooldown;
        public int currentCooldown;
        public bool isPassive;
        
        // 效果参数
        public float damageMultiplier = 1.0f;
        public int healAmount = 0;
        public int shieldAmount = 0;
        public float critChance = 0f;
    }

    /// <summary>
    /// 敌人AI数据
    /// </summary>
    [System.Serializable]
    public class EnemyAIData
    {
        public string enemyId;
        public string enemyName;
        
        // 出拳倾向（石头/剪刀/布的百分比）
        public int rock倾向 = 33;
        public int scissors倾向 = 33;
        public int paper倾向 = 33;
        
        // 行为模式
        public bool useSkillWhenRageFull = true;
        public int aggressionLevel = 5; // 1-10, 越高越倾向攻击
    }
}
