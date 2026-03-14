using System;
using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 移动类型（猜拳）
    /// </summary>
    public enum MoveType
    {
        Circle,    // ○ 圆 - 克制方
        Triangle,  // △ 三角 - 克制圆
        Square     // □ 方 - 克制三角
    }

    /// <summary>
    /// 战斗单位类型
    /// </summary>
    public enum CombatantType
    {
        Player,
        Enemy,
        Boss
    }

    /// <summary>
    /// 战斗单位 - 玩家和敌人的基类
    /// </summary>
    [Serializable]
    public class Combatant
    {
        // 基本属性
        public string Name;
        public CombatantType Type;
        public int Level = 1;
        
        // 战斗属性
        public int MaxHP;
        public int CurrentHP;
        public int Attack;
        public int Defense;
        public int CritRate;      // 暴击率 (0-100)
        public int CritDamage;    // 暴击伤害 (100=1倍)
        public int Energy;        // 能量
        public int MaxEnergy;
        
        // 特殊属性
        public int Block;         // 护盾/格挡值
        public int Dodge;         // 闪避率 (0-100)
        
        // 状态
        public bool IsAlive => CurrentHP > 0;
        public bool IsDead => CurrentHP <= 0;
        
        // 出招序列（用于连招）
        public MoveType[] ComboSequence = new MoveType[3];
        public int SequenceIndex = 0;

        public Combatant(string name, CombatantType type)
        {
            Name = name;
            Type = type;
            MaxHP = 100;
            CurrentHP = 100;
            Attack = 10;
            Defense = 5;
            CritRate = 10;
            CritDamage = 150;
            Energy = 3;
            MaxEnergy = 3;
            Block = 0;
            Dodge = 0;
        }

        /// <summary>
        /// 造成伤害
        /// </summary>
        public void TakeDamage(int damage)
        {
            // 先扣除格挡
            int remainingDamage = damage;
            
            if (Block > 0)
            {
                if (Block >= remainingDamage)
                {
                    Block -= remainingDamage;
                    remainingDamage = 0;
                }
                else
                {
                    remainingDamage -= Block;
                    Block = 0;
                }
            }
            
            // 扣除生命
            CurrentHP = Math.Max(0, CurrentHP - remainingDamage);
        }

        /// <summary>
        /// 治疗
        /// </summary>
        public void Heal(int amount)
        {
            CurrentHP = Math.Min(MaxHP, CurrentHP + amount);
        }

        /// <summary>
        /// 恢复能量
        /// </summary>
        public void RestoreEnergy(int amount)
        {
            Energy = Math.Min(MaxEnergy, Energy + amount);
        }

        /// <summary>
        /// 添加格挡
        /// </summary>
        public void AddBlock(int amount)
        {
            Block += amount;
        }

        /// <summary>
        /// 清除格挡
        /// </summary>
        public void ClearBlock()
        {
            Block = 0;
        }

        /// <summary>
        /// 添加出招到序列
        /// </summary>
        public void AddMoveToSequence(MoveType move)
        {
            ComboSequence[SequenceIndex] = move;
            SequenceIndex = (SequenceIndex + 1) % 3;
        }

        /// <summary>
        /// 重置序列
        /// </summary>
        public void ResetSequence()
        {
            SequenceIndex = 0;
            ComboSequence = new MoveType[3];
        }

        /// <summary>
        /// 获取序列字符串
        /// </summary>
        public string GetSequenceString()
        {
            string result = "";
            for (int i = 0; i < 3; i++)
            {
                result += GetMoveIcon(ComboSequence[i]);
            }
            return result;
        }

        /// <summary>
        /// 获取移动图标
        /// </summary>
        public static string GetMoveIcon(MoveType move)
        {
            switch (move)
            {
                case MoveType.Circle: return "○";
                case MoveType.Triangle: return "△";
                case MoveType.Square: return "□";
                default: return "?";
            }
        }

        /// <summary>
        /// 检查是否暴击
        /// </summary>
        public bool CheckCrit()
        {
            return UnityEngine.Random.Range(0, 100) < CritRate;
        }

        /// <summary>
        /// 检查是否闪避
        /// </summary>
        public bool CheckDodge()
        {
            return UnityEngine.Random.Range(0, 100) < Dodge;
        }

        /// <summary>
        /// 升级
        /// </summary>
        public void LevelUp()
        {
            Level++;
            MaxHP += 10;
            CurrentHP = MaxHP;
            Attack += 2;
            Defense += 1;
        }

        /// <summary>
        /// 复制属性
        /// </summary>
        public Combatant Clone()
        {
            Combatant copy = new Combatant(Name, Type)
            {
                Level = Level,
                MaxHP = MaxHP,
                CurrentHP = CurrentHP,
                Attack = Attack,
                Defense = Defense,
                CritRate = CritRate,
                CritDamage = CritDamage,
                Energy = Energy,
                MaxEnergy = MaxEnergy,
                Block = Block,
                Dodge = Dodge
            };
            return copy;
        }
    }

    /// <summary>
    /// 战斗单位工厂
    /// </summary>
    public static class CombatantFactory
    {
        /// <summary>
        /// 创建玩家
        /// </summary>
        public static Combatant CreatePlayer(string name = "玩家")
        {
            Combatant player = new Combatant(name, CombatantType.Player)
            {
                MaxHP = 100,
                CurrentHP = 100,
                Attack = 15,
                Defense = 5,
                CritRate = 10,
                CritDamage = 150,
                Energy = 3,
                MaxEnergy = 3,
                Dodge = 5
            };
            return player;
        }

        /// <summary>
        /// 创建敌人
        /// </summary>
        public static Combatant CreateEnemy(string name, int level)
        {
            // 根据等级调整属性
            float multiplier = 1 + (level - 1) * 0.2f;
            
            Combatant enemy = new Combatant(name, CombatantType.Enemy)
            {
                Level = level,
                MaxHP = (int)(50 * multiplier),
                CurrentHP = (int)(50 * multiplier),
                Attack = (int)(8 * multiplier),
                Defense = (int)(3 * multiplier),
                CritRate = 5 + level,
                CritDamage = 150,
                Energy = 3,
                MaxEnergy = 3,
                Dodge = 3
            };
            return enemy;
        }

        /// <summary>
        /// 创建BOSS
        /// </summary>
        public static Combatant CreateBoss(string name, int level)
        {
            float multiplier = 1 + (level - 1) * 0.3f;
            
            Combatant boss = new Combatant(name, CombatantType.Boss)
            {
                Level = level,
                MaxHP = (int)(150 * multiplier),
                CurrentHP = (int)(150 * multiplier),
                Attack = (int)(15 * multiplier),
                Defense = (int)(8 * multiplier),
                CritRate = 15 + level,
                CritDamage = 175,
                Energy = 5,
                MaxEnergy = 5,
                Dodge = 10
            };
            return boss;
        }
    }
}
