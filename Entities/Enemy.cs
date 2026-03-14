using System.Collections.Generic;
using UnityEngine;

namespace Zhouxing.Entities
{
    /// <summary>
    /// 敌人类型枚举
    /// </summary>
    public enum EnemyType
    {
        Normal,   // 普通敌人
        Elite,    // 精英敌人
        Boss      // Boss
    }

    /// <summary>
    /// 敌人实体类 - 管理单个敌人的状态和行为
    /// </summary>
    public class Enemy : MonoBehaviour
    {
        [Header("基本属性")]
        [SerializeField] private string enemyId;
        [SerializeField] private string enemyName;
        [SerializeField] private EnemyType enemyType;
        [SerializeField] private int maxHealth;
        [SerializeField] private int currentHealth;
        [SerializeField] private int attack;
        [SerializeField] private float moveSpeed = 2f;
        [SerializeField] private float attackRange = 1f;
        [SerializeField] private float attackCooldown = 1f;

        [Header("状态")]
        [SerializeField] private bool isDead = false;
        [SerializeField] private float lastAttackTime;

        [Header("技能")]
        [SerializeField] private List<EnemySkill> skills = new List<EnemySkill>();

        [Header("战斗")]
        [SerializeField] private Transform target;
        [SerializeField] private int currentFloor;  // 当前所在楼层

        #region 属性访问

        public string EnemyId => enemyId;
        public string EnemyName => enemyName;
        public EnemyType EnemyType => enemyType;
        public int MaxHealth => maxHealth;
        public int CurrentHealth => currentHealth;
        public int Attack => attack;
        public float MoveSpeed => moveSpeed;
        public float AttackRange => attackRange;
        public float AttackCooldown => attackCooldown;
        public bool IsDead => isDead;
        public int CurrentFloor => currentFloor;
        public Transform Target => target;
        public List<EnemySkill> Skills => skills;

        public float HealthPercentage => (float)currentHealth / maxHealth;

        #endregion

        #region 生命周期

        protected virtual void Start()
        {
            currentHealth = maxHealth;
            lastAttackTime = -attackCooldown; // 允许立即攻击
        }

        protected virtual void Update()
        {
            if (isDead) return;

            UpdateAI();
        }

        #endregion

        #region 战斗方法

        /// <summary>
        /// 受到伤害
        /// </summary>
        public virtual void TakeDamage(int damage)
        {
            if (isDead) return;

            currentHealth -= damage;
            
            if (currentHealth <= 0)
            {
                currentHealth = 0;
                Die();
            }
        }

        /// <summary>
        /// 治疗
        /// </summary>
        public void Heal(int amount)
        {
            if (isDead) return;

            currentHealth = Mathf.Min(currentHealth + amount, maxHealth);
        }

        /// <summary>
        /// 死亡
        /// </summary>
        protected virtual void Die()
        {
            isDead = true;
            // 可以添加死亡特效、经验掉落等
            Destroy(gameObject, 0.5f);
        }

        /// <summary>
        /// 攻击目标
        /// </summary>
        public virtual void AttackTarget()
        {
            if (target == null || isDead) return;
            if (Time.time - lastAttackTime < attackCooldown) return;

            lastAttackTime = Time.time;

            // 造成伤害
            var targetEntity = target.GetComponent<Entities.Player.Player>();
            if (targetEntity != null)
            {
                targetEntity.TakeDamage(attack);
            }

            // 触发技能
            TryUseSkill();
        }

        /// <summary>
        /// 尝试使用技能
        /// </summary>
        private void TryUseSkill()
        {
            foreach (var skill in skills)
            {
                if (skill.CanUse())
                {
                    skill.Use(this);
                }
            }
        }

        #endregion

        #region AI

        /// <summary>
        /// 更新AI行为
        /// </summary>
        protected virtual void UpdateAI()
        {
            // 基础AI：寻找并靠近玩家，然后攻击
            if (target == null)
            {
                FindTarget();
                return;
            }

            float distance = Vector3.Distance(transform.position, target.position);
            
            if (distance <= attackRange)
            {
                AttackTarget();
            }
            else
            {
                MoveTowards(target.position);
            }
        }

        /// <summary>
        /// 寻找目标
        /// </summary>
        protected virtual void FindTarget()
        {
            var player = GameObject.FindGameObjectWithTag("Player");
            if (player != null)
            {
                target = player.transform;
            }
        }

        /// <summary>
        /// 移动向目标
        /// </summary>
        protected virtual void MoveTowards(Vector3 destination)
        {
            Vector3 direction = (destination - transform.position).normalized;
            transform.position += direction * moveSpeed * Time.deltaTime;
            
            // 面向移动方向
            if (direction != Vector3.zero)
            {
                transform.forward = direction;
            }
        }

        #endregion

        #region 数据初始化

        /// <summary>
        /// 从数据配置初始化敌人
        /// </summary>
        public void Initialize(EnemyData data)
        {
            enemyId = data.Id;
            enemyName = data.Name;
            enemyType = data.Type;
            maxHealth = data.MaxHealth;
            currentHealth = data.MaxHealth;
            attack = data.Attack;
            moveSpeed = data.MoveSpeed;
            attackRange = data.AttackRange;
            attackCooldown = data.AttackCooldown;

            // 初始化技能
            skills.Clear();
            if (data.SkillIds != null)
            {
                foreach (var skillId in data.SkillIds)
                {
                    var skill = EnemySkillDatabase.GetSkill(skillId);
                    if (skill != null)
                    {
                        skills.Add(skill);
                    }
                }
            }
        }

        #endregion

        /// <summary>
        /// 设置目标
        /// </summary>
        public void SetTarget(Transform newTarget)
        {
            target = newTarget;
        }

        /// <summary>
        /// 设置当前楼层
        /// </summary>
        public void SetFloor(int floor)
        {
            currentFloor = floor;
        }

        /// <summary>
        /// 获取敌人数据（用于UI显示等）
        /// </summary>
        public EnemyData GetEnemyData()
        {
            return new EnemyData
            {
                Id = enemyId,
                Name = enemyName,
                Type = enemyType,
                MaxHealth = maxHealth,
                Attack = attack,
                MoveSpeed = moveSpeed,
                AttackRange = attackRange,
                AttackCooldown = attackCooldown
            };
        }
    }
}
