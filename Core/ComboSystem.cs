using System;
using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 连招效果类型
    /// </summary>
    public enum ComboEffectType
    {
        Damage,         // 伤害
        Heal,           // 治疗
        Block,          // 护盾
        Energy,         // 能量
        Buff,           // 增益
        Debuff,         // 减益
        Special         // 特殊
    }

    /// <summary>
    /// 连招效果
    /// </summary>
    [Serializable]
    public class ComboEffect
    {
        public ComboEffectType Type;
        public int Value;              // 效果值
        public bool IsPercent;         // 是否为百分比
        public string Description;    // 描述

        public ComboEffect(ComboEffectType type, int value, bool isPercent = false, string desc = "")
        {
            Type = type;
            Value = value;
            IsPercent = isPercent;
            Description = desc;
        }

        /// <summary>
        /// 获取效果描述
        /// </summary>
        public string GetDescription()
        {
            if (!string.IsNullOrEmpty(Description)) return Description;

            string valueStr = IsPercent ? $"{Value}%" : Value.ToString();
            
            switch (Type)
            {
                case ComboEffectType.Damage:
                    return $"造成 {valueStr} 伤害";
                case ComboEffectType.Heal:
                    return $"恢复 {valueStr} 生命";
                case ComboEffectType.Block:
                    return $"获得 {valueStr} 护盾";
                case ComboEffectType.Energy:
                    return $"获得 {valueStr} 能量";
                case ComboEffectType.Buff:
                    return $"获得 {valueStr} 增益";
                case ComboEffectType.Debuff:
                    return $"造成 {valueStr} 减益";
                case ComboEffectType.Special:
                    return "特殊效果";
                default:
                    return "未知效果";
            }
        }
    }

    /// <summary>
    /// 连招（卡牌）
    /// </summary>
    [Serializable]
    public class Combo
    {
        public string ID;
        public string Name;
        public string Description;
        
        // 序列要求
        public MoveType[] Sequence = new MoveType[3];
        
        // 效果
        public ComboEffect Effect;
        
        // 属性
        public int Rarity;          // 稀有度 (1-5)
        public bool IsUnlocked;     // 是否已解锁
        public int UnlockCost;      // 解锁费用

        public Combo(string id, string name, MoveType[] sequence, ComboEffect effect, int rarity = 1)
        {
            ID = id;
            Name = name;
            Sequence = sequence;
            Effect = effect;
            Rarity = rarity;
            IsUnlocked = rarity == 1; // 基础连招默认解锁
            UnlockCost = rarity * 10;
        }

        /// <summary>
        /// 获取序列字符串
        /// </summary>
        public string GetSequenceString()
        {
            string result = "";
            foreach (var move in Sequence)
            {
                result += Combatant.GetMoveIcon(move);
            }
            return result;
        }

        /// <summary>
        /// 获取稀有度显示
        /// </summary>
        public string GetRarityString()
        {
            switch (Rarity)
            {
                case 1: return "普通";
                case 2: return "优秀";
                case 3: return "稀有";
                case 4: return "史诗";
                case 5: return "传说";
                default: return "未知";
            }
        }

        /// <summary>
        /// 获取稀有度颜色
        /// </summary>
        public string GetRarityColor()
        {
            switch (Rarity)
            {
                case 1: return "white";
                case 2: return "blue";
                case 3: return "purple";
                case 4: return "orange";
                case 5: return "gold";
                default: return "white";
            }
        }

        /// <summary>
        /// 检查序列是否匹配
        /// </summary>
        public bool MatchesSequence(MoveType[] inputSequence)
        {
            if (inputSequence == null || inputSequence.Length < 3) return false;
            
            // 检查最后3个出招是否匹配
            for (int i = 0; i < 3; i++)
            {
                if (Sequence[i] != inputSequence[i]) return false;
            }
            return true;
        }
    }

    /// <summary>
    /// 连招数据库
    /// </summary>
    public class ComboDatabase
    {
        private static ComboDatabase _instance;
        public static ComboDatabase Instance => _instance;

        private List<Combo> allCombos = new List<Combo>();
        private Dictionary<string, Combo> comboMap = new Dictionary<string, Combo>();

        public ComboDatabase()
        {
            _instance = this;
            Initialize();
        }

        /// <summary>
        /// 初始化连招
        /// </summary>
        private void Initialize()
        {
            // ========== 1星连招（初始解锁）==========
            AddCombo(new Combo("combo_001", "闪电突袭", 
                new MoveType[] { MoveType.Triangle, MoveType.Circle, MoveType.Square },
                new ComboEffect(ComboEffectType.Damage, 3, false, "3点真实伤害"), 1));

            AddCombo(new Combo("combo_002", "稳固防御", 
                new MoveType[] { MoveType.Square, MoveType.Square, MoveType.Triangle },
                new ComboEffect(ComboEffectType.Block, 3, false, "3点护盾+反弹"), 1));

            AddCombo(new Combo("combo_003", "能量充能", 
                new MoveType[] { MoveType.Circle, MoveType.Triangle, MoveType.Triangle },
                new ComboEffect(ComboEffectType.Energy, 1, false, "获得1能量"), 1));

            // ========== 2星连招 ==========
            AddCombo(new Combo("combo_004", "连击", 
                new MoveType[] { MoveType.Circle, MoveType.Circle, MoveType.Circle },
                new ComboEffect(ComboEffectType.Damage, 5, false, "5点伤害"), 2));

            AddCombo(new Combo("combo_005", "三角阵", 
                new MoveType[] { MoveType.Triangle, MoveType.Triangle, MoveType.Triangle },
                new ComboEffect(ComboEffectType.Damage, 5, false, "5点伤害"), 2));

            AddCombo(new Combo("combo_006", "方块墙", 
                new MoveType[] { MoveType.Square, MoveType.Square, MoveType.Square },
                new ComboEffect(ComboEffectType.Block, 5, false, "5点护盾"), 2));

            // ========== 3星连招 ==========
            AddCombo(new Combo("combo_007", "旋风斩", 
                new MoveType[] { MoveType.Circle, MoveType.Square, MoveType.Circle },
                new ComboEffect(ComboEffectType.Damage, 8, false, "8点伤害"), 3));

            AddCombo(new Combo("combo_008", "防守反击", 
                new MoveType[] { MoveType.Square, MoveType.Circle, MoveType.Square },
                new ComboEffect(ComboEffectType.Damage, 6, false, "6点伤害+3护盾"), 3));

            AddCombo(new Combo("combo_009", "全能三角", 
                new MoveType[] { MoveType.Triangle, MoveType.Circle, MoveType.Triangle },
                new ComboEffect(ComboEffectType.Heal, 5, false, "恢复5生命"), 3));

            // ========== 4星连招 ==========
            AddCombo(new Combo("combo_010", "循环之力", 
                new MoveType[] { MoveType.Circle, MoveType.Triangle, MoveType.Square },
                new ComboEffect(ComboEffectType.Damage, 12, false, "12点真实伤害"), 4));

            AddCombo(new Combo("combo_011", "绝对防御", 
                new MoveType[] { MoveType.Square, MoveType.Triangle, MoveType.Circle },
                new ComboEffect(ComboEffectType.Block, 10, false, "10点护盾"), 4));

            // ========== 5星连招（传说）==========
            AddCombo(new Combo("combo_012", "周行之道", 
                new MoveType[] { MoveType.Circle, MoveType.Triangle, MoveType.Square },
                new ComboEffect(ComboEffectType.Special, 0, false, "造成20点伤害并恢复10生命"), 5));

            AddCombo(new Combo("combo_013", "无限循环", 
                new MoveType[] { MoveType.Circle, MoveType.Circle, MoveType.Circle, MoveType.Triangle, MoveType.Square },
                new ComboEffect(ComboEffectType.Special, 0, false, "清空敌人能量并造成15点伤害"), 5));

            Debug.Log($"已加载 {allCombos.Count} 个连招");
        }

        private void AddCombo(Combo combo)
        {
            allCombos.Add(combo);
            comboMap[combo.ID] = combo;
        }

        /// <summary>
        /// 获取所有连招
        /// </summary>
        public List<Combo> GetAllCombos()
        {
            return allCombos;
        }

        /// <summary>
        /// 获取已解锁连招
        /// </summary>
        public List<Combo> GetUnlockedCombos()
        {
            return allCombos.FindAll(c => c.IsUnlocked);
        }

        /// <summary>
        /// 根据ID获取连招
        /// </summary>
        public Combo GetCombo(string id)
        {
            return comboMap.ContainsKey(id) ? comboMap[id] : null;
        }

        /// <summary>
        /// 检查序列是否触发连招
        /// </summary>
        public Combo CheckCombo(MoveType[] sequence)
        {
            foreach (var combo in allCombos)
            {
                if (combo.IsUnlocked && combo.MatchesSequence(sequence))
                {
                    return combo;
                }
            }
            return null;
        }

        /// <summary>
        /// 解锁连招
        /// </summary>
        public bool UnlockCombo(string id, int memory)
        {
            Combo combo = GetCombo(id);
            if (combo == null || combo.IsUnlocked) return false;
            
            if (memory >= combo.UnlockCost)
            {
                combo.IsUnlocked = true;
                return true;
            }
            return false;
        }

        /// <summary>
        /// 获取连招数量
        /// </summary>
        public int GetTotalCount()
        {
            return allCombos.Count;
        }

        /// <summary>
        /// 获取已解锁数量
        /// </summary>
        public int GetUnlockedCount()
        {
            return allCombos.FindAll(c => c.IsUnlocked).Count;
        }
    }
}
