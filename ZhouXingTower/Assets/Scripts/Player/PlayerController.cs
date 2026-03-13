using UnityEngine;
using ZhouXing.Data;

namespace ZhouXing.Player
{
    /// <summary>
    /// 玩家控制器
    /// </summary>
    public class PlayerController : MonoBehaviour
    {
        public CharacterStats stats;
        
        // 技能列表
        public SkillData[] skills;

        // 临时获得的效果卡牌
        public System.Collections.Generic.List<SkillData> tempCards = new System.Collections.Generic.List<SkillData>();

        private void Start()
        {
            if (stats == null)
            {
                stats = new CharacterStats
                {
                    characterId = "player_001",
                    characterName = "无名挑战者",
                    maxHealth = 100,
                    currentHealth = 100,
                    attack = 10,
                    defense = 2,
                    maxRage = 100,
                    currentRage = 0
                };
            }

            // 初始化默认技能
            InitializeDefaultSkills();
        }

        private void InitializeDefaultSkills()
        {
            skills = new SkillData[]
            {
                new SkillData
                {
                    skillId = "skill_001",
                    skillName = "重拳",
                    description = "伤害+100%，无视防御",
                    rageCost = 30,
                    cooldown = 2,
                    currentCooldown = 0,
                    isPassive = false,
                    damageMultiplier = 2.0f
                },
                new SkillData
                {
                    skillId = "skill_002",
                    skillName = "预判",
                    description = "敌人出拳倾向显示+20%精度",
                    rageCost = 0,
                    cooldown = 0,
                    currentCooldown = 0,
                    isPassive = true
                },
                new SkillData
                {
                    skillId = "skill_003",
                    skillName = "反击",
                    description = "被克制时触发，反弹50%伤害",
                    rageCost = 20,
                    cooldown = 1,
                    currentCooldown = 0,
                    isPassive = false
                },
                new SkillData
                {
                    skillId = "skill_004",
                    skillName = "防守",
                    description = "获得8点护盾",
                    rageCost = 15,
                    cooldown = 1,
                    currentCooldown = 0,
                    isPassive = false,
                    shieldAmount = 8
                },
                new SkillData
                {
                    skillId = "skill_005",
                    skillName = "集怒",
                    description = "额外获得10点怒气",
                    rageCost = 0,
                    cooldown = 2,
                    currentCooldown = 0,
                    isPassive = false
                },
                new SkillData
                {
                    skillId = "skill_006",
                    skillName = "虚张声势",
                    description = "平局时，敌人下回合倾向反转",
                    rageCost = 10,
                    cooldown = 3,
                    currentCooldown = 0,
                    isPassive = false
                }
            };
        }

        /// <summary>
        /// 使用技能
        /// </summary>
        public bool UseSkill(string skillId)
        {
            for (int i = 0; i < skills.Length; i++)
            {
                if (skills[i].skillId == skillId)
                {
                    if (skills[i].currentCooldown > 0)
                    {
                        Debug.Log($"技能冷却中，还需 {skills[i].currentCooldown} 回合");
                        return false;
                    }

                    if (stats.currentRage < skills[i].rageCost)
                    {
                        Debug.Log($"怒气不足，需要 {skills[i].rageCost} 点");
                        return false;
                    }

                    // 消耗怒气
                    stats.currentRage -= skills[i].rageCost;
                    
                    // 设置冷却
                    skills[i].currentCooldown = skills[i].cooldown + 1;

                    Debug.Log($"使用技能: {skills[i].skillName}");
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// 更新技能冷却
        /// </summary>
        public void UpdateCooldowns()
        {
            for (int i = 0; i < skills.Length; i++)
            {
                if (skills[i].currentCooldown > 0)
                {
                    skills[i].currentCooldown--;
                }
            }
        }

        /// <summary>
        /// 添加临时卡牌
        /// </summary>
        public void AddTempCard(SkillData card)
        {
            tempCards.Add(card);
            Debug.Log($"获得临时卡牌: {card.skillName}");
        }

        /// <summary>
        /// 治疗
        /// </summary>
        public void Heal(int amount)
        {
            stats.currentHealth = Mathf.Min(stats.maxHealth, stats.currentHealth + amount);
        }

        /// <summary>
        /// 添加怒气
        /// </summary>
        public void AddRage(int amount)
        {
            stats.currentRage = Mathf.Min(stats.maxRage, stats.currentRage + amount);
        }
    }
}
