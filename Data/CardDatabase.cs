using UnityEngine;
using System.Collections.Generic;

namespace ZhouXing.Game.Data
{
    /// <summary>
    /// 卡牌数据库 - 管理所有卡牌数据
    /// </summary>
    public class CardDatabase : MonoBehaviour
    {
        private static CardDatabase _instance;
        public static CardDatabase Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = FindObjectOfType<CardDatabase>();
                    if (_instance == null)
                    {
                        GameObject go = new GameObject("CardDatabase");
                        _instance = go.AddComponent<CardDatabase>();
                    }
                }
                return _instance;
            }
        }

        [Header("卡牌数据库")]
        [SerializeField] private List<Card> allCards = new List<Card>();

        private Dictionary<string, Card> cardDictionary = new Dictionary<string, Card>();

        private void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Destroy(gameObject);
                return;
            }
            _instance = this;
            InitializeDatabase();
        }

        /// <summary>
        /// 初始化卡牌数据库
        /// </summary>
        private void InitializeDatabase()
        {
            cardDictionary.Clear();
            
            // 如果编辑器中未配置卡牌，则使用默认卡牌
            if (allCards.Count == 0)
            {
                allCards = GetDefaultCards();
            }

            foreach (Card card in allCards)
            {
                if (!cardDictionary.ContainsKey(card.id))
                {
                    cardDictionary.Add(card.id, card);
                }
            }
        }

        /// <summary>
        /// 获取默认卡牌列表
        /// </summary>
        private List<Card> GetDefaultCards()
        {
            List<Card> defaultCards = new List<Card>();

            // 普通攻击类卡牌
            defaultCards.Add(new Card("atk_001", "石拳", "造成基于攻击力的伤害", CardType.Attack, CardRarity.Common, 1, 10, RPSChoice.Rock));
            defaultCards.Add(new Card("atk_002", "剪刀刺", "造成基于攻击力的伤害", CardType.Attack, CardRarity.Common, 1, 10, RPSChoice.Scissors));
            defaultCards.Add(new Card("atk_003", "纸扇", "造成基于攻击力的伤害", CardType.Attack, CardRarity.Common, 1, 10, RPSChoice.Paper));

            // 稀有攻击卡
            defaultCards.Add(new Card("atk_004", "重拳", "造成大量伤害", CardType.Attack, CardRarity.Rare, 2, 25, RPSChoice.Rock));
            defaultCards.Add(new Card("atk_005", "风暴之刃", "造成巨量伤害", CardType.Attack, CardRarity.Legendary, 3, 40, RPSChoice.Scissors));

            // 防御类卡牌
            defaultCards.Add(new Card("def_001", "石盾", "增加防御力", CardType.Defense, CardRarity.Common, 1, 5, RPSChoice.Rock));
            defaultCards.Add(new Card("def_002", "纸墙", "增加防御力", CardType.Defense, CardRarity.Common, 1, 5, RPSChoice.Paper));
            defaultCards.Add(new Card("def_003", "铁壁", "大幅增加防御力", CardType.Defense, CardRarity.Rare, 2, 15, RPSChoice.Rock));

            // 技能类卡牌
            defaultCards.Add(new Card("skl_001", "抽牌", "抽一张牌", CardType.Skill, CardRarity.Common, 1, 1, RPSChoice.Paper));
            defaultCards.Add(new Card("skl_002", "恢复", "恢复生命值", CardType.Skill, CardRarity.Uncommon, 2, 15, RPSChoice.Paper));
            defaultCards.Add(new Card("skl_003", "能量爆发", "恢复所有魔法值", CardType.Skill, CardRarity.Rare, 2, 0, RPSChoice.Scissors));

            // 增益类卡牌
            defaultCards.Add(new Card("buf_001", "力量", "增加攻击力", CardType.Buff, CardRarity.Uncommon, 2, 5, RPSChoice.Rock));
            defaultCards.Add(new Card("buf_002", "护盾", "增加防御力", CardType.Buff, CardRarity.Uncommon, 2, 5, RPSChoice.Paper));
            defaultCards.Add(new Card("buf_003", "狂化", "大幅增加攻击力", CardType.Buff, CardRarity.Legendary, 3, 15, RPSChoice.Rock));

            // 减益类卡牌
            defaultCards.Add(new Card("debuf_001", "虚弱", "减少敌人攻击力", CardType.Debuff, CardRarity.Uncommon, 2, 3, RPSChoice.Scissors));
            defaultCards.Add(new Card("debuf_002", "破甲", "减少敌人防御力", CardType.Debuff, CardRarity.Uncommon, 2, 3, RPSChoice.Rock));

            // 特殊类卡牌
            defaultCards.Add(new Card("spc_001", "偷取", "偷取敌人增益", CardType.Special, CardRarity.Rare, 2, 0, RPSChoice.Paper));
            defaultCards.Add(new Card("spc_002", "必杀", "造成敌人当前生命值50%的伤害", CardType.Special, CardRarity.Legendary, 4, 50, RPSChoice.Scissors));
            defaultCards.Add(new Card("spc_003", "复制", "复制敌人上次使用的卡牌", CardType.Special, CardRarity.Legendary, 3, 0, RPSChoice.Paper));

            return defaultCards;
        }

        /// <summary>
        /// 根据ID获取卡牌
        /// </summary>
        public Card GetCard(string cardId)
        {
            if (cardDictionary.ContainsKey(cardId))
            {
                return cardDictionary[cardId];
            }
            return null;
        }

        /// <summary>
        /// 获取所有卡牌
        /// </summary>
        public List<Card> GetAllCards()
        {
            return new List<Card>(allCards);
        }

        /// <summary>
        /// 根据稀有度获取卡牌
        /// </summary>
        public List<Card> GetCardsByRarity(CardRarity rarity)
        {
            List<Card> result = new List<Card>();
            foreach (Card card in allCards)
            {
                if (card.rarity == rarity)
                {
                    result.Add(card);
                }
            }
            return result;
        }

        /// <summary>
        /// 根据类型获取卡牌
        /// </summary>
        public List<Card> GetCardsByType(CardType type)
        {
            List<Card> result = new List<Card>();
            foreach (Card card in allCards)
            {
                if (card.type == type)
                {
                    result.Add(card);
                }
            }
            return result;
        }

        /// <summary>
        /// 随机获取指定数量的卡牌
        /// </summary>
        public List<Card> GetRandomCards(int count)
        {
            List<Card> result = new List<Card>();
            List<Card> tempList = new List<Card>(allCards);

            for (int i = 0; i < count && tempList.Count > 0; i++)
            {
                int randomIndex = Random.Range(0, tempList.Count);
                result.Add(tempList[randomIndex]);
                tempList.RemoveAt(randomIndex);
            }

            return result;
        }

        /// <summary>
        /// 随机获取指定稀有度的卡牌
        /// </summary>
        public List<Card> GetRandomCardsByRarity(CardRarity rarity, int count)
        {
            List<Card> rarityCards = GetCardsByRarity(rarity);
            List<Card> result = new List<Card>();

            for (int i = 0; i < count && rarityCards.Count > 0; i++)
            {
                int randomIndex = Random.Range(0, rarityCards.Count);
                result.Add(rarityCards[randomIndex]);
                rarityCards.RemoveAt(randomIndex);
            }

            return result;
        }

        /// <summary>
        /// 添加新卡牌到数据库
        /// </summary>
        public void AddCard(Card card)
        {
            if (!cardDictionary.ContainsKey(card.id))
            {
                allCards.Add(card);
                cardDictionary.Add(card.id, card);
            }
        }

        /// <summary>
        /// 移除卡牌
        /// </summary>
        public void RemoveCard(string cardId)
        {
            if (cardDictionary.ContainsKey(cardId))
            {
                Card card = cardDictionary[cardId];
                allCards.Remove(card);
                cardDictionary.Remove(cardId);
            }
        }

        /// <summary>
        /// 获取卡牌数量
        /// </summary>
        public int GetCardCount()
        {
            return allCards.Count;
        }
    }
}
