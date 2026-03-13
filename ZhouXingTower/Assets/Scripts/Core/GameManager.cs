using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZhouXing.Core
{
    /// <summary>
    /// 游戏管理器
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        // 游戏状态
        public enum GameState
        {
            MainMenu,
            TowerClimbing,
            Combat,
            Pause,
            GameOver
        }

        public GameState currentState = GameState.MainMenu;

        // 玩家进度
        public int currentTowerLevel = 1;
        public int maxTowerLevel = 999;

        // 资源
        public int gold = 0;
        public int soulStones = 0;

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            // 初始化游戏
            InitializeGame();
        }

        /// <summary>
        /// 初始化游戏
        /// </summary>
        private void InitializeGame()
        {
            Debug.Log("=== 周行：循环三角 ===");
            Debug.Log("游戏初始化完成");
        }

        /// <summary>
        /// 开始新游戏
        /// </summary>
        public void StartNewGame()
        {
            currentTowerLevel = 1;
            gold = 0;
            soulStones = 0;
            
            Debug.Log("开始新游戏 - 第1层");
            
            // 加载第一个战斗场景
            SceneManager.LoadScene("CombatScene");
            currentState = GameState.Combat;
        }

        /// <summary>
        /// 继续游戏
        /// </summary>
        public void ContinueGame()
        {
            Debug.Log($"继续游戏 - 第{currentTowerLevel}层");
            SceneManager.LoadScene("CombatScene");
            currentState = GameState.Combat;
        }

        /// <summary>
        /// 退出游戏
        /// </summary>
        public void QuitGame()
        {
            Debug.Log("退出游戏");
            Application.Quit();
        }

        /// <summary>
        /// 战斗胜利
        /// </summary>
        public void OnCombatVictory()
        {
            // 奖励
            gold += 50 + currentTowerLevel * 10;
            soulStones += 5;
            
            Debug.Log($"战斗胜利！获得 {50 + currentTowerLevel * 10} 金币, 5 魂石");
            
            // 进入下一层
            currentTowerLevel++;
            
            if (currentTowerLevel > maxTowerLevel)
            {
                Debug.Log("通关！");
                currentState = GameState.GameOver;
            }
        }

        /// <summary>
        /// 战斗失败
        /// </summary>
        public void OnCombatDefeat()
        {
            Debug.Log("战斗失败...");
            currentState = GameState.GameOver;
        }

        /// <summary>
        /// 暂停游戏
        /// </summary>
        public void PauseGame()
        {
            Time.timeScale = 0;
            currentState = GameState.Pause;
        }

        /// <summary>
        /// 恢复游戏
        /// </summary>
        public void ResumeGame()
        {
            Time.timeScale = 1;
            currentState = GameState.Combat;
        }
    }
}
