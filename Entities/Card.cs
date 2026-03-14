using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Cards
{
    /// <summary>
    /// 卡牌稀有度
    /// </summary>
    public enum CardRarity
    {
        Common,    // 普通
        Rare,      // 稀有
        Legendary  // 传奇
    }

    /// <summary>
    /// 卡牌类型
    /// </summary>
    public enum CardType
    {
        Attack,   // 攻击
        Defense,  // 防御
        Skill     // 技能
    }

    /// <summary>
    /// 卡牌实体类
    /// </summary>
    [System.Serializable]
    public class Card
    {
        [Header("基础信息")]
        [SerializeField] private string m_Id;
        [SerializeField] private string m_Name;
        [SerializeField] private string m_Description;
        [SerializeField] private CardType m_CardType;
        [SerializeField] private CardRarity m_Rarity;

        [Header("数值")]
        [SerializeField] private int m_AttackValue;    // 攻击值
        [SerializeField] private int m_DefenseValue;   // 防御值
        [SerializeField] private int m_EnergyCost;     // 能量消耗
        [SerializeField] private int m_DrawCount;      // 抽牌数

        [Header("效果")]
        [SerializeField] private List<CardEffect> m_Effects;

        [Header("状态")]
        [SerializeField] private bool m_IsExhaust;     // 是否已耗尽

        public string Id => m_Id;
        public string Name => m_Name;
        public string Description => m_Description;
        public CardType CardType => m_CardType;
        public CardRarity Rarity => m_Rarity;
        public int AttackValue => m_AttackValue;
        public int DefenseValue => m_DefenseValue;
        public int EnergyCost => m_EnergyCost;
        public int DrawCount => m_DrawCount;
        public List<CardEffect> Effects => m_Effects;
        public bool IsExhaust => m_IsExhaust;

        public Card()
        {
            m_Effects = new List<CardEffect>();
            m_IsExhaust = false;
        }

        public Card(string id, string name, string description, CardType cardType, CardRarity rarity,
            int attackValue = 0, int defenseValue = 0, int energyCost = 1, int drawCount = 0) 
            : this()
        {
            m_Id = id;
            m_Name = name;
            m_Description = description;
            m_CardType = cardType;
            m_Rarity = rarity;
            m_AttackValue = attackValue;
            m_DefenseValue = defenseValue;
            m_EnergyCost = energyCost;
            m_DrawCount = drawCount;
        }

        /// <summary>
        /// 使用卡牌
        /// </summary>
        public virtual void Use(Player user, Player target)
        {
            if (m_IsExhaust)
            {
                Debug.LogWarning($"卡牌 {m_Name} 已耗尽，无法使用");
                return;
            }

            // 应用效果
            foreach (var effect in m_Effects)
            {
                effect.Apply(user, target);
            }

            // 应用基础数值
            switch (m_CardType)
            {
                case CardType.Attack:
                    target.TakeDamage(m_AttackValue);
                    break;
                case CardType.Defense:
                    user.AddDefense(m_DefenseValue);
                    break;
                case CardType.Skill:
                    // 技能效果由具体卡牌效果决定
                    break;
            }
        }

        /// <summary>
        /// 复制卡牌
        /// </summary>
        public Card Clone()
        {
            Card clone = new Card(m_Id, m_Name, m_Description, m_CardType, m_Rarity,
                m_AttackValue, m_DefenseValue, m_EnergyCost, m_DrawCount);
            
            foreach (var effect in m_Effects)
            {
                clone.m_Effects.Add(effect.Clone());
            }
            
            return clone;
        }

        public void SetExhaust(bool exhausted)
        {
            m_IsExhaust = exhausted;
        }

        public void Reset()
        {
            m_IsExhaust = false;
        }

        public override string ToString()
        {
            return $"[{m_Rarity}] {m_Name} ({m_CardType}) - 消耗: {m_EnergyCost}, 攻击: {m_AttackValue}, 防御: {m_DefenseValue}";
        }
    }
}
