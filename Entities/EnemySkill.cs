using System.Collections;
using UnityEngine;

namespace Zhouxing.Entities
{
    /// <summary>
    /// 技能类型
    /// </summary>
    public enum SkillType
    {
        Passive,      // 被动技能
        Active,       // 主动技能
        Buff,         // 增益技能
        Debuff        // 减益技能
    }

    /// <summary>
    /// 技能目标类型
    /// </summary>
    public enum SkillTargetType
    {
        Self,         // 自身
        Enemy,        // 单体敌人
        Enemies,      // 群体敌人
        Ally,         // 单体友军
        Allies        // 群体友军
    }

    /// <summary>
    /// 敌人技能类
    /// </summary>
    [System.Serializable]
    public class EnemySkill
    {
        [Header("基本属性")]
        [SerializeField] private string skillId;
        [SerializeField] private string skillName;
        [SerializeField] private string description;
        [SerializeField] private SkillType skillType;
        [SerializeField] private SkillTargetType targetType;
        [SerializeField] private float cooldown;
        [SerializeField] private float lastUseTime = -999f;

        [Header("效果数值")]
        [SerializeField] private int damage;           // 伤害值
        [SerializeField] private int healAmount;       // 治疗量
        [SerializeField] private float effectDuration; // 效果持续时间
        [SerializeField] private float range;          // 技能范围

        [Header("特殊效果")]
        [SerializeField] private bool stun;            // 眩晕
        [SerializeField] private bool poison;          // 中毒
        [SerializeField] private int poisonDamage;     // 中毒伤害
        [SerializeField] private bool knockback;       // 击退
        [SerializeField] private float knockbackForce; // 击退力度

        #region 属性访问

        public string SkillId => skillId;
        public string SkillName => skillName;
        public string Description => description;
        public SkillType SkillType => skillType;
        public SkillTargetType TargetType => targetType;
        public float Cooldown => cooldown;
        public float LastUseTime => lastUseTime;
        public int Damage => damage;
        public int HealAmount => healAmount;
        public float EffectDuration => effectDuration;
        public float Range => range;
        public bool Stun => stun;
        public bool Poison => poison;
        public int PoisonDamage => poisonDamage;
        public bool Knockback => knockback;
        public float KnockbackForce => knockbackForce;

        #endregion

        /// <summary>
        /// 技能是否可以使用
        /// </summary>
        public bool CanUse()
        {
            if (skillType == SkillType.Passive) return false;
            return Time.time - lastUseTime >= cooldown;
        }

        /// <summary>
        /// 使用技能
        /// </summary>
        public void Use(Enemy owner)
        {
            if (!CanUse()) return;

            lastUseTime = Time.time;

            switch (targetType)
            {
                case SkillTargetType.Self:
                    ApplyToSelf(owner);
                    break;
                case SkillTargetType.Enemy:
                case SkillTargetType.Enemies:
                    ApplyToEnemy(owner);
                    break;
            }
        }

        /// <summary>
        /// 对自身使用
        /// </summary>
        private void ApplyToSelf(Enemy owner)
        {
            if (healAmount > 0)
            {
                owner.Heal(healAmount);
            }
        }

        /// <summary>
        /// 对敌人使用
        /// </summary>
        private void ApplyToEnemy(Enemy owner)
        {
            if (owner.Target == null) return;

            // 获取目标
            var targetEntity = owner.Target.GetComponent<Entities.Player.Player>();
            if (targetEntity == null) return;

            // 造成伤害
            if (damage > 0)
            {
                targetEntity.TakeDamage(damage);
            }

            // 治疗自身
            if (healAmount > 0)
            {
                owner.Heal(healAmount);
            }

            // 特殊效果
            if (stun)
            {
                targetEntity.ApplyStun(effectDuration);
            }

            if (poison)
            {
                targetEntity.ApplyPoison(poisonDamage, effectDuration);
            }

            if (knockback)
            {
                Vector3 direction = (targetEntity.transform.position - owner.transform.position).normalized;
                targetEntity.ApplyKnockback(direction, knockbackForce);
            }
        }

        /// <summary>
        /// 被动技能效果（每帧调用）
        /// </summary>
        public void ApplyPassive(Enemy owner)
        {
            if (skillType != SkillType.Passive) return;

            // 持续治疗
            if (healAmount > 0)
            {
                owner.Heal(Mathf.RoundToInt(healAmount * Time.deltaTime));
            }
        }

        /// <summary>
        /// 从数据创建技能
        /// </summary>
        public static EnemySkill Create(SkillData data)
        {
            return new EnemySkill
            {
                skillId = data.Id,
                skillName = data.Name,
                description = data.Description,
                skillType = data.Type,
                targetType = data.TargetType,
                cooldown = data.Cooldown,
                damage = data.Damage,
                healAmount = data.HealAmount,
                effectDuration = data.EffectDuration,
                range = data.Range,
                stun = data.Stun,
                poison = data.Poison,
                poisonDamage = data.PoisonDamage,
                knockback = data.Knockback,
                knockbackForce = data.KnockbackForce
            };
        }
    }

    /// <summary>
    /// 技能数据（用于配置）
    /// </summary>
    [System.Serializable]
    public class SkillData
    {
        [Header("基本属性")]
        public string Id;
        public string Name;
        public string Description;
        public SkillType Type;
        public SkillTargetType TargetType;
        public float Cooldown = 5f;

        [Header("效果数值")]
        public int Damage;
        public int HealAmount;
        public float EffectDuration;
        public float Range = 3f;

        [Header("特殊效果")]
        public bool Stun;
        public bool Poison;
        public int PoisonDamage;
        public bool Knockback;
        public float KnockbackForce = 5f;
    }
}
