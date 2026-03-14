using UnityEngine;
using UnityEngine.UI;
using ZhouXing.Game;

namespace ZhouXing.Game.UI
{
    /// <summary>
    /// 主菜单界面
    /// </summary>
    public class MainMenuPanel : BasePanel
    {
        [Header("按钮")]
        [SerializeField] private Button newGameButton;
        [SerializeField] private Button continueButton;
        [SerializeField] private Button settingsButton;
        [SerializeField] private Button quitButton;
        
        [Header("文本")]
        [SerializeField] private Text titleText;
        [SerializeField] private Text versionText;
        
        // 回调
        public System.Action OnNewGame;
        public System.Action OnContinue;
        public System.Action OnSettings;
        public System.Action OnQuit;

        public override void Initialize()
        {
            base.Initialize();
            
            // 绑定按钮事件
            if (newGameButton) newGameButton.onClick.AddListener(OnNewGameClick);
            if (continueButton) continueButton.onClick.AddListener(OnContinueClick);
            if (settingsButton) settingsButton.onClick.AddListener(OnSettingsClick);
            if (quitButton) quitButton.onClick.AddListener(OnQuitClick);
            
            // 设置标题
            if (titleText) titleText.text = "周行：循环三角";
            if (versionText) versionText.text = "Version 1.0.0";
            
            Debug.Log("主菜单初始化完成");
        }

        private void OnNewGameClick()
        {
            Debug.Log("新游戏");
            OnNewGame?.Invoke();
        }

        private void OnContinueClick()
        {
            Debug.Log("继续游戏");
            OnContinue?.Invoke();
        }

        private void OnSettingsClick()
        {
            Debug.Log("设置");
            OnSettings?.Invoke();
        }

        private void OnQuitClick()
        {
            Debug.Log("退出游戏");
            OnQuit?.Invoke();
            
            #if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
            #else
            Application.Quit();
            #endif
        }
    }

    /// <summary>
    /// 战斗界面
    /// </summary>
    public class BattlePanel : BasePanel
    {
        [Header("玩家信息")]
        [SerializeField] private Image playerHPBar;
        [SerializeField] private Text playerHPText;
        [SerializeField] private Image playerEnergyBar;
        [SerializeField] private Text playerEnergyText;
        [SerializeField] private Text playerBlockText;
        
        [Header("敌人信息")]
        [SerializeField] private Image enemyHPBar;
        [SerializeField] private Text enemyHPText;
        [SerializeField] private Text enemyNameText;
        [SerializeField] private Text enemyLevelText;
        
        [Header("出招按钮")]
        [SerializeField] private Button circleButton;    // ○ 圆
        [SerializeField] private Button triangleButton; // △ 三角
        [SerializeField] private Button squareButton;   // □ 方
        
        [Header("连招显示")]
        [SerializeField] private Text comboText;
        [SerializeField] private Text comboEffectText;
        
        [Header("状态显示")]
        [SerializeField] private Text resultText;
        [SerializeField] private Text turnText;
        
        [Header("功能按钮")]
        [SerializeField] private Button menuButton;
        [SerializeField] private Button useItemButton;
        
        public override void Initialize()
        {
            base.Initialize();
            
            // 绑定出招按钮
            if (circleButton) circleButton.onClick.AddListener(() => OnMoveClick(MoveType.Circle));
            if (triangleButton) triangleButton.onClick.AddListener(() => OnMoveClick(MoveType.Triangle));
            if (squareButton) squareButton.onClick.AddListener(() => OnMoveClick(MoveType.Square));
            
            // 绑定功能按钮
            if (menuButton) menuButton.onClick.AddListener(OnMenuClick);
            if (useItemButton) useItemButton.onClick.AddListener(OnUseItemClick);
            
            Debug.Log("战斗界面初始化完成");
        }

        /// <summary>
        /// 更新玩家信息
        /// </summary>
        public void UpdatePlayerInfo(int hp, int maxHP, int energy, int maxEnergy, int block)
        {
            if (playerHPBar) playerHPBar.fillAmount = (float)hp / maxHP;
            if (playerHPText) playerHPText.text = $"{hp}/{maxHP}";
            
            if (playerEnergyBar) playerEnergyBar.fillAmount = (float)energy / maxEnergy;
            if (playerEnergyText) playerEnergyText.text = $"{energy}/{maxEnergy}";
            
            if (playerBlockText) playerBlockText.text = $"格挡: {block}";
        }

        /// <summary>
        /// 更新敌人信息
        /// </summary>
        public void UpdateEnemyInfo(string name, int level, int hp, int maxHP)
        {
            if (enemyNameText) enemyNameText.text = name;
            if (enemyLevelText) enemyLevelText.text = $"Lv.{level}";
            if (enemyHPBar) enemyHPBar.fillAmount = (float)hp / maxHP;
            if (enemyHPText) enemyHPText.text = $"{hp}/{maxHP}";
        }

        /// <summary>
        /// 更新连招序列
        /// </summary>
        public void UpdateComboSequence(MoveType[] sequence)
        {
            if (comboText == null) return;
            
            string text = "";
            foreach (var move in sequence)
            {
                text += GetMoveIcon(move) + " ";
            }
            comboText.text = text;
        }

        /// <summary>
        /// 显示连招效果
        /// </summary>
        public void ShowComboEffect(string effectName)
        {
            if (comboEffectText)
            {
                comboEffectText.text = effectName;
                comboEffectText.gameObject.SetActive(true);
            }
        }

        /// <summary>
        /// 显示战斗结果
        /// </summary>
        public void ShowBattleResult(string result)
        {
            if (resultText)
            {
                resultText.text = result;
                resultText.gameObject.SetActive(true);
            }
        }

        /// <summary>
        /// 更新回合数
        /// </summary>
        public void UpdateTurn(int turn)
        {
            if (turnText) turnText.text = $"回合: {turn}";
        }

        /// <summary>
        /// 出招点击
        /// </summary>
        private void OnMoveClick(MoveType move)
        {
            Debug.Log($"玩家出招: {move}");
            // 通知战斗系统
        }

        private void OnMenuClick()
        {
            Debug.Log("打开菜单");
        }

        private void OnUseItemClick()
        {
            Debug.Log("使用道具");
        }

        private string GetMoveIcon(MoveType move)
        {
            switch (move)
            {
                case MoveType.Circle: return "○";
                case MoveType.Triangle: return "△";
                case MoveType.Square: return "□";
                default: return "?";
            }
        }
    }

    /// <summary>
    /// 商店界面
    /// </summary>
    public class ShopPanel : BasePanel
    {
        [Header("商店信息")]
        [SerializeField] private Text shopNameText;
        [SerializeField] private Text goldText;
        
        [Header("商品列表")]
        [SerializeField] private Transform itemContainer;
        [SerializeField] private GameObject itemPrefab;
        
        [Header("按钮")]
        [SerializeField] private Button refreshButton;
        [SerializeField] private Text refreshCostText;
        [SerializeField] private Button closeButton;
        
        public override void Initialize()
        {
            base.Initialize();
            
            if (refreshButton) refreshButton.onClick.AddListener(OnRefreshClick);
            if (closeButton) closeButton.onClick.AddListener(OnCloseClick);
            
            Debug.Log("商店界面初始化完成");
        }

        /// <summary>
        /// 设置商店信息
        /// </summary>
        public void SetShopInfo(string name, int gold)
        {
            if (shopNameText) shopNameText.text = name;
            if (goldText) goldText.text = $"金币: {gold}";
        }

        /// <summary>
        /// 刷新商品
        /// </summary>
        private void OnRefreshClick()
        {
            Debug.Log("刷新商品");
        }

        /// <summary>
        /// 关闭商店
        /// </summary>
        private void OnCloseClick()
        {
            Debug.Log("关闭商店");
            OnHide();
        }
    }

    /// <summary>
    /// 背包界面
    /// </summary>
    public class InventoryPanel : BasePanel
    {
        [Header("背包信息")]
        [SerializeField] private Text capacityText;
        
        [Header("标签页")]
        [SerializeField] private Button equipmentTab;
        [SerializeField] private Button itemTab;
        [SerializeField] private Button keyTab;
        
        [Header("物品列表")]
        [SerializeField] private Transform itemContainer;
        
        [Header("物品信息")]
        [SerializeField] private GameObject itemInfoPanel;
        [SerializeField] private Text itemNameText;
        [SerializeField] private Text itemDescText;
        [SerializeField] private Text itemStatsText;
        
        [Header("按钮")]
        [SerializeField] private Button useButton;
        [SerializeField] private Button equipButton;
        [SerializeField] private Button unequipButton;
        [SerializeField] private Button sellButton;
        [SerializeField] private Button closeButton;

        public override void Initialize()
        {
            base.Initialize();
            
            if (closeButton) closeButton.onClick.AddListener(OnCloseClick);
            if (equipmentTab) equipmentTab.onClick.AddListener(() => OnTabClick(0));
            if (itemTab) itemTab.onClick.AddListener(() => OnTabClick(1));
            if (keyTab) keyTab.onClick.AddListener(() => OnTabClick(2));
            
            Debug.Log("背包界面初始化完成");
        }

        /// <summary>
        /// 更新背包容量
        /// </summary>
        public void UpdateCapacity(int current, int max)
        {
            if (capacityText) capacityText.text = $"背包: {current}/{max}";
        }

        /// <summary>
        /// 显示物品信息
        /// </summary>
        public void ShowItemInfo(string name, string desc, string stats)
        {
            if (itemInfoPanel) itemInfoPanel.SetActive(true);
            if (itemNameText) itemNameText.text = name;
            if (itemDescText) itemDescText.text = desc;
            if (itemStatsText) itemStatsText.text = stats;
        }

        /// <summary>
        /// 标签页点击
        /// </summary>
        private void OnTabClick(int tab)
        {
            Debug.Log($"切换标签页: {tab}");
        }

        private void OnCloseClick()
        {
            Debug.Log("关闭背包");
            OnHide();
        }
    }

    /// <summary>
    /// 地图选择界面
    /// </summary>
    public class MapPanel : BasePanel
    {
        [Header("地图信息")]
        [SerializeField] private Text layerText;
        [SerializeField] private Text progressText;
        
        [Header("节点容器")]
        [SerializeField] private Transform nodeContainer;
        
        [Header("按钮")]
        [SerializeField] private Button backButton;

        public override void Initialize()
        {
            base.Initialize();
            
            if (backButton) backButton.onClick.AddListener(OnBackClick);
            
            Debug.Log("地图界面初始化完成");
        }

        /// <summary>
        /// 更新地图信息
        /// </summary>
        public void UpdateMapInfo(int currentLayer, int totalLayer, int visitedNodes, int totalNodes)
        {
            if (layerText) layerText.text = $"第 {currentLayer} 层";
            if (progressText) progressText.text = $"进度: {visitedNodes}/{totalNodes}";
        }

        private void OnBackClick()
        {
            Debug.Log("返回");
            OnHide();
        }
    }

    /// <summary>
    /// 设置界面
    /// </summary>
    public class SettingsPanel : BasePanel
    {
        [Header("音量")]
        [SerializeField] private Slider masterVolumeSlider;
        [SerializeField] private Slider bgmVolumeSlider;
        [SerializeField] private Slider sfxVolumeSlider;
        
        [Header("画质")]
        [SerializeField] private Dropdown qualityDropdown;
        
        [Header("按钮")]
        [SerializeField] private Button closeButton;
        [SerializeField] private Button resetButton;
        [SerializeField] private Button saveButton;

        public override void Initialize()
        {
            base.Initialize();
            
            if (closeButton) closeButton.onClick.AddListener(OnCloseClick);
            if (resetButton) resetButton.onClick.AddListener(OnResetClick);
            if (saveButton) saveButton.onClick.AddListener(OnSaveClick);
            
            Debug.Log("设置界面初始化完成");
        }

        private void OnCloseClick()
        {
            OnHide();
        }

        private void OnResetClick()
        {
            Debug.Log("重置设置");
            // 重置为默认值
        }

        private void OnSaveClick()
        {
            Debug.Log("保存设置");
            // 保存设置
        }
    }
}
