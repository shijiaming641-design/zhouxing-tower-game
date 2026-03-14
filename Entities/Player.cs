using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Cards
{
    /// <summary>
    /// 玩家类 - 包含HP/攻击/防御/怒气/卡组
    /// </summary>
    public class Player
    {
        [Header("基础属性")]
        private string m_Name;
        private int m_MaxHp;
        private int m_CurrentHp;
        private int m_Attack;
        private int m_Defense;
        private int m_MaxEnergy;
        private int m_CurrentEnergy;
        private int m_Rage;           // 怒气值

        [Header("卡牌相关")]
        private List<Card> m_Deck;        // 卡组（抽牌堆）
        private List<Card> m_Hand;        // 手牌
        private List<Card> m_DiscardPile; // 弃牌堆
        private List<Card> m_DrawPile;    // 抽牌堆
        private List<Card> m_ExhaustPile; // 耗尽堆

        [Header("Buff/Debuff")]
        private Dictionary<string, Buff> m_Buffs;

        [Header("状态")]
        private bool m_IsDead;

        #region Properties

        public string Name => m_Name;
        public int MaxHp => m_MaxHp;
        public int CurrentHp => m_CurrentHp;
        public int Attack => m_Attack;
        public int Defense => m_Defense;
        public int MaxEnergy => m_MaxEnergy;
        public int CurrentEnergy => m_CurrentEnergy;
        public int Rage => m_Rage;
        public bool IsDead => m_IsDead;

        public List<Card> Deck => m_Deck;
        public List<Card> Hand => m_Hand;
        public List<Card> DiscardPile => m_DiscardPile;
        public List<Card> DrawPile => m_DrawPile;
        public List<Card> ExhaustPile => m_ExhaustPile;
        public Dictionary<string, Buff> Buffs => m_Buffs;

        public int HandCount => m_Hand != null ? m_Hand.Count : 0;

        #endregion

        public Player(string name, int maxHp, int attack, int maxEnergy)
        {
            m_Name = name;
            m_MaxHp = maxHp;
            m_CurrentHp = maxHp;
            m_Attack = attack;
            m_Defense = 0;
            m_MaxEnergy = maxEnergy;
            m_CurrentEnergy = maxEnergy;
            m_Rage = 0;
            m_IsDead = false;

            m_Deck = new List<Card>();
            m_Hand = new List<Card>();
            m_DiscardPile = new List<Card>();
            m_DrawPile = new List<Card>();
            m_ExhaustPile = new List<Card>();
            m_Buffs = new Dictionary<string, Buff>();
        }

        #region 战斗属性操作

        /// <summary>
        /// 受到伤害
        /// </summary>
        public void TakeDamage(int damage)
        {
            int actualDamage = Mathf.Max(0, damage - m_Defense);
            m_CurrentHp = Mathf.Max(0, m_CurrentHp - actualDamage);
            
            Debug.Log($"{m_Name} 受到 {actualDamage} 点伤害 (护甲吸收 {Mathf.Min(damage, m_Defense)})");

            if (m_CurrentHp <= 0)
            {
                m_IsDead = true;
                Debug.Log($"{m_Name} 已死亡!");
            }
        }

        /// <summary>
        /// 治疗
        /// </summary>
        public void Heal(int healAmount)
        {
            m_CurrentHp = Mathf.Min(m_MaxHp, m_CurrentHp + healAmount);
            Debug.Log($"{m_Name} 恢复了 {healAmount} 点生命值");
        }

        /// <summary>
        /// 添加防御
        /// </summary>
        public void AddDefense(int defense)
        {
            m_Defense += defense;
            Debug.Log($"{m_Name} 获得 {defense} 点护甲");
        }

        /// <summary>
        /// 清除所有护甲
        /// </summary>
        public void ClearDefense()
        {
            m_Defense = 0;
        }

        /// <summary>
        /// 增加攻击力
        /// </summary>
        public void AddAttack(int attack)
        {
            m_Attack += attack;
            Debug.Log($"{m_Name} 攻击力增加 {attack}, 当前攻击力: {m_Attack}");
        }

        /// <summary>
        /// 增加能量
        /// </summary>
        public void AddEnergy(int energy)
        {
            m_CurrentEnergy = Mathf.Min(m_MaxEnergy, m_CurrentEnergy + energy);
        }

        /// <summary>
        /// 消耗能量
        /// </summary>
        public bool ConsumeEnergy(int energy)
        {
            if (m_CurrentEnergy >= energy)
            {
                m_CurrentEnergy -= energy;
                return true;
            }
            Debug.LogWarning($"{m_Name} 能量不足!");
            return false;
        }

        /// <summary>
        /// 增加怒气
        /// </summary>
        public void AddRage(int rage)
        {
            m_Rage += rage;
            Debug.Log($"{m_Name} 怒气增加 {rage}, 当前怒气: {m_Rage}");
        }

        /// <summary>
        /// 消耗怒气
        /// </summary>
        public bool ConsumeRage(int rage)
        {
            if (m_Rage >= rage)
            {
                m_Rage -= rage;
                return true;
            }
            return false;
        }

        #endregion

        #region 卡牌操作

        /// <summary>
        /// 设置卡组
        /// </summary>
        public void SetDeck(List<Card> deck)
        {
            m_Deck = new List<Card>(deck);
            m_DrawPile = new List<Card>(deck);
            ShuffleDrawPile();
        }

        /// <summary>
        /// 抽牌
        /// </summary>
        public void DrawCards(int count)
        {
            for (int i = 0; i < count; i++)
            {
                DrawCard();
            }
        }

        /// <summary>
        /// 抽一张牌
        /// </summary>
        public bool DrawCard()
        {
            // 如果抽牌堆为空，弃牌堆洗牌
            if (m_DrawPile.Count == 0)
            {
                if (m_DiscardPile.Count == 0)
                {
                    Debug.Log($"{m_Name} 没有牌可抽!");
                    return false;
                }
                ReshuffleDiscardIntoDraw();
            }

            if (m_DrawPile.Count > 0)
            {
                Card card = m_DrawPile[m_DrawPile.Count - 1];
                m_DrawPile.RemoveAt(m_DrawPile.Count - 1);
                m_Hand.Add(card);
                Debug.Log($"{m_Name} 抽到了 {card.Name}");
                return true;
            }

            return false;
        }

        /// <summary>
        /// 将弃牌堆洗入抽牌堆
        /// </summary>
        private void ReshuffleDiscardIntoDraw()
        {
            m_DrawPile = new List<Card>(m_DiscardPile);
            m_DiscardPile.Clear();
            ShuffleDrawPile();
            Debug.Log($"{m_Name} 将弃牌堆洗入抽牌堆");
        }

        /// <summary>
        /// 洗牌
        /// </summary>
        private void ShuffleDrawPile()
        {
            for (int i = 0; i < m_DrawPile.Count; i++)
            {
                Card temp = m_DrawPile[i];
                int randomIndex = Random.Range(i, m_DrawPile.Count);
                m_DrawPile[i] = m_DrawPile[randomIndex];
                m_DrawPile[randomIndex] = temp;
            }
        }

        /// <summary>
        /// 打出手牌中的卡牌
        /// </summary>
        public bool PlayCard(int handIndex, Player target)
        {
            if (handIndex < 0 || handIndex >= m_Hand.Count)
            {
                Debug.LogWarning("无效的手牌索引!");
                return false;
            }

            Card card = m_Hand[handIndex];

            // 检查能量
            if (!ConsumeEnergy(card.EnergyCost))
            {
                Debug.LogWarning($"能量不足，无法使用 {card.Name}");
                return false;
            }

            // 使用卡牌
            card.Use(this, target);

            // 从手牌移除
            m_Hand.RemoveAt(handIndex);

            // 抽牌效果
            if (card.DrawCount > 0)
            {
                DrawCards(card.DrawCount);
            }

            // 加入弃牌堆
            m_DiscardPile.Add(card);
            
            Debug.Log($"{m_Name} 使用了 {card.Name}");

            return true;
        }

        /// <summary>
        /// 弃置手牌
        /// </summary>
        public void DiscardCard(int handIndex)
        {
            if (handIndex < 0 || handIndex >= m_Hand.Count)
            {
                Debug.LogWarning("无效的手牌索引!");
                return;
            }

            Card card = m_Hand[handIndex];
            m_Hand.RemoveAt(handIndex);
            m_DiscardPile.Add(card);
            
            Debug.Log($"{m_Name} 弃置了 {card.Name}");
        }

        /// <summary>
        /// 弃置所有手牌
        /// </summary>
        public void DiscardAllHand()
        {
            while (m_Hand.Count > 0)
            {
                DiscardCard(0);
            }
        }

        /// <summary>
        /// 将卡牌加入弃牌堆
        /// </summary>
        public void AddToDiscardPile(Card card)
        {
            m_DiscardPile.Add(card);
        }

        /// <summary>
        /// 将卡牌加入耗尽堆
        /// </summary>
        public void AddToExhaustPile(Card card)
        {
            m_ExhaustPile.Add(card);
            card.SetExhaust(true);
        }

        #endregion

        #region Buff操作

        /// <summary>
        /// 添加Buff
        /// </summary>
        public void AddBuff(Buff buff)
        {
            if (m_Buffs.ContainsKey(buff.Id))
            {
                m_Buffs[buff.Id].AddStacks(buff.Stacks);
            }
            else
            {
                m_Buffs[buff.Id] = buff;
                buff.OnApply(this);
            }
        }

        /// <summary>
        /// 移除Buff
        /// </summary>
        public void RemoveBuff(string buffId)
        {
            if (m_Buffs.ContainsKey(buffId))
            {
                m_Buffs[buffId].OnRemove(this);
                m_Buffs.Remove(buffId);
            }
        }

        /// <summary>
        /// 每回合开始时更新Buff
        /// </summary>
        public void OnTurnStart()
        {
            List<string> buffsToRemove = new List<string>();
            
            foreach (var kvp in m_Buffs)
            {
                kvp.Value.OnTurnStart(this);
                if (kvp.Value.IsExpired)
                {
                    buffsToRemove.Add(kvp.Key);
                }
            }

            foreach (string buffId in buffsToRemove)
            {
                RemoveBuff(buffId);
            }
        }

        /// <summary>
        /// 每回合结束时更新Buff
        /// </summary>
        public void OnTurnEnd()
        {
            foreach (var kvp in m_Buffs)
            {
                kvp.Value.OnTurnEnd(this);
            }
        }

        #endregion

        #region 回合管理

        /// <summary>
        /// 开始回合
        /// </summary>
        public void StartTurn()
        {
            m_CurrentEnergy = m_MaxEnergy;
            OnTurnStart();
            DrawCards(5); // 默认每回合抽5张牌
            Debug.Log($"{m_Name} 回合开始: HP={m_CurrentHp}/{m_MaxHp}, 能量={m_CurrentEnergy}/{m_MaxEnergy}, 手牌数={m_Hand.Count}");
        }

        /// <summary>
        /// 结束回合
        /// </summary>
        public void EndTurn()
        {
            OnTurnEnd();
            DiscardAllHand();
            ClearDefense();
            Debug.Log($"{m_Name} 回合结束");
        }

        /// <summary>
        /// 重置玩家状态（战斗开始时）
        /// </summary>
        public void ResetForBattle()
        {
            m_CurrentHp = m_MaxHp;
            m_Defense = 0;
            m_CurrentEnergy = m_MaxEnergy;
            m_Rage = 0;
            m_IsDead = false;
            
            m_Hand.Clear();
            m_DiscardPile.Clear();
            m_ExhaustPile.Clear();
            
            // 重新洗牌
            m_DrawPile = new List<Card>(m_Deck);
            ShuffleDrawPile();
            
            // 清除所有Buff
            m_Buffs.Clear();
        }

        #endregion

        /// <summary>
        /// 获取玩家状态信息
        /// </summary>
        public string GetStatusInfo()
        {
            return $"{m_Name} - HP: {m_CurrentHp}/{m_MaxHp}, 能量: {m_CurrentEnergy}/{m_MaxEnergy}, " +
                   $"攻击: {m_Attack}, 防御: {m_Defense}, 怒气: {m_Rage}, " +
                   $"手牌: {m_Hand.Count}, 抽牌堆: {m_DrawPile.Count}, 弃牌堆: {m_DiscardPile.Count}";
        }
    }
}
