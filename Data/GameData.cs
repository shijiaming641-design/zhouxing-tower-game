using UnityEngine;
using System.Collections.Generic;

namespace ZhouXing.Game.Data
{
    /// <summary>
    /// 卡牌数据结构
    /// </summary>
    [System.Serializable]
    public class Card
    {
        public string id;              // 卡牌ID
        public string name;            // 卡牌名称
        public string description;     // 卡牌描述
        public CardType type;          // 卡牌类型
        public CardRarity rarity;      // 稀有度
        public int cost;               // 消耗
        public int value;              // 效果值
        public RPSChoice requiredChoice; // 需要的选择
        public RPSChoice bonusChoice;   // 额外奖励选择
        public bool isPermanent;       // 是否永久卡牌

        public Card()
        {
            id = "";
            name = "";
            description = "";
            type = CardType.Attack;
            rarity = CardRarity.Common;
            cost = 1;
            value = 1;
            requiredChoice = RPSChoice.Rock;
            bonusChoice = RPSChoice.Paper;
            isPermanent = false;
        }

        public Card(string id, string name, string description, CardType type, 
                    CardRarity rarity, int cost, int value, RPSChoice requiredChoice)
        {
            this.id = id;
            this.name = name;
            this.description = description;
            this.type = type;
            this.rarity = rarity;
            this.cost = cost;
            this.value = value;
            this.requiredChoice = requiredChoice;
            this.bonusChoice = RPSChoice.Paper;
            this.isPermanent = false;
        }
    }

    /// <summary>
    /// 玩家数据
    /// </summary>
    [System.Serializable]
    public class PlayerData
    {
        public string playerId;        // 玩家ID
        public string playerName;      // 玩家名称
        public int health;             // 生命值
        public int maxHealth;          // 最大生命值
        public int mana;               // 当前魔法值
        public int maxMana;            // 最大魔法值
        public int attack;             // 攻击力
        public int defense;            // 防御力
        public int level;              // 等级
        public int experience;         // 经验值
        public List<Card> handCards;   // 手牌
        public List<Card> deck;        // 卡组
        public List<Card> discardPile; // 弃牌堆

        public PlayerData()
        {
            playerId = "";
            playerName = "Player";
            health = 100;
            maxHealth = 100;
            mana = 3;
            maxMana = 3;
            attack = 10;
            defense = 5;
            level = 1;
            experience = 0;
            handCards = new List<Card>();
            deck = new List<Card>();
            discardPile = new List<Card>();
        }

        public void TakeDamage(int damage)
        {
            int actualDamage = Mathf.Max(1, damage - defense);
            health = Mathf.Max(0, health - actualDamage);
        }

        public void Heal(int amount)
        {
            health = Mathf.Min(maxHealth, health + amount);
        }

        public void UseMana(int amount)
        {
            mana = Mathf.Max(0, mana - amount);
        }

        public void RestoreMana()
        {
            mana = maxMana;
        }

        public bool IsDead()
        {
            return health <= 0;
        }
    }

    /// <summary>
    /// 敌人数据
    /// </summary>
    [System.Serializable]
    public class EnemyData
    {
        public string enemyId;          // 敌人ID
        public string enemyName;       // 敌人名称
        public int health;             // 生命值
        public int maxHealth;          // 最大生命值
        public int attack;             // 攻击力
        public int defense;            // 防御力
        public RPSChoice preferredChoice; // 偏好选择（AI）
        public int attackPattern;      // 攻击模式（0=随机,1=石头,2=剪刀,3=布）
        public List<string> rewards;   // 奖励列表

        public EnemyData()
        {
            enemyId = "";
            enemyName = "Enemy";
            health = 50;
            maxHealth = 50;
            attack = 5;
            defense = 2;
            preferredChoice = RPSChoice.Rock;
            attackPattern = 0;
            rewards = new List<string>();
        }

        public void TakeDamage(int damage)
        {
            int actualDamage = Mathf.Max(1, damage - defense);
            health = Mathf.Max(0, health - actualDamage);
        }

        public bool IsDead()
        {
            return health <= 0;
        }
    }

    /// <summary>
    /// 战斗数据
    /// </summary>
    [System.Serializable]
    public class BattleData
    {
        public PlayerData player;
        public EnemyData enemy;
        public int round;               // 当前回合
        public int maxRounds;          // 最大回合数
        public bool isPlayerTurn;      // 是否玩家回合
        public RPSChoice playerChoice; // 玩家选择
        public RPSChoice enemyChoice;  // 敌人选择
        public BattleResult result;    // 战斗结果
        public int turnCount;          // 战斗轮次

        public BattleData()
        {
            player = new PlayerData();
            enemy = new EnemyData();
            round = 1;
            maxRounds = 10;
            isPlayerTurn = true;
            playerChoice = RPSChoice.Rock;
            enemyChoice = RPSChoice.Paper;
            result = BattleResult.Draw;
            turnCount = 0;
        }

        public void Reset()
        {
            round = 1;
            isPlayerTurn = true;
            playerChoice = RPSChoice.Rock;
            enemyChoice = RPSChoice.Paper;
            result = BattleResult.Draw;
            turnCount = 0;
        }
    }

    /// <summary>
    /// 游戏存档数据
    /// </summary>
    [System.Serializable]
    public class GameSaveData
    {
        public int currentLevel;           // 当前关卡
        public int totalWins;             // 总胜利次数
        public int totalLosses;           // 总失败次数
        public int currency;              // 货币
        public List<string> unlockedCards;// 解锁的卡牌ID列表
        public PlayerData savedPlayer;    // 保存的玩家数据
        public long saveTime;             // 保存时间戳

        public GameSaveData()
        {
            currentLevel = 1;
            totalWins = 0;
            totalLosses = 0;
            currency = 0;
            unlockedCards = new List<string>();
            savedPlayer = new PlayerData();
            saveTime = 0;
        }
    }
}
