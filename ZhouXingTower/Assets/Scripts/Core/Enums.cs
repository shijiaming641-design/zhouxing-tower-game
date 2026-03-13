namespace ZhouXing.Rps
{
    /// <summary>
    /// 猜拳手势类型
    /// </summary>
    public enum RpsType
    {
        None = 0,
        Rock = 1,      // 石头
        Scissors = 2,  // 剪刀
        Paper = 3      // 布
    }

    /// <summary>
    /// 战斗结果
    /// </summary>
    public enum CombatResult
    {
        None = 0,
        Win = 1,       // 胜利
        Lose = 2,      // 失败
        Draw = 3       // 平局
    }

    /// <summary>
    /// 效果类型
    /// </summary>
    public enum EffectType
    {
        Damage,
        Heal,
        Shield,
        Buff,
        Debuff
    }
}
