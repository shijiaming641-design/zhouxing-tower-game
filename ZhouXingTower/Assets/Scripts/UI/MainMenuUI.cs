using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZhouXing.UI
{
    /// <summary>
    /// 主菜单UI管理器
    /// </summary>
    public class MainMenuUI : MonoBehaviour
    {
        [Header("UI组件")]
        public GameObject mainMenuPanel;
        public GameObject newGameButton;
        public GameObject continueButton;
        public GameObject quitButton;

        [Header("游戏标题")]
        public Text titleText;
        public Text subtitleText;

        private void Start()
        {
            // 初始化UI
            if (titleText != null)
                titleText.text = "周行：循环三角";
            
            if (subtitleText != null)
                subtitleText.text = "蒸汽朋克 Roguelike 策略游戏";

            // 检查是否有存档
            bool hasSave = PlayerPrefs.HasKey("SaveLevel");
            if (continueButton != null)
                continueButton.SetActive(hasSave);

            Debug.Log("主菜单加载完成");
        }

        /// <summary>
        /// 开始新游戏
        /// </summary>
        public void OnNewGame()
        {
            Debug.Log("开始新游戏");
            
            // 清除旧存档
            PlayerPrefs.DeleteKey("SaveLevel");
            
            // 加载游戏场景
            SceneManager.LoadScene("GameScene");
        }

        /// <summary>
        /// 继续游戏
        /// </summary>
        public void OnContinue()
        {
            Debug.Log("继续游戏");
            SceneManager.LoadScene("GameScene");
        }

        /// <summary>
        /// 退出游戏
        /// </summary>
        public void OnQuit()
        {
            Debug.Log("退出游戏");
            Application.Quit();
            
            #if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
            #endif
        }

        /// <summary>
        /// 打开设置
        /// </summary>
        public void OnSettings()
        {
            Debug.Log("打开设置");
        }

        /// <summary>
        /// 打开关于
        /// </summary>
        public void OnAbout()
        {
            Debug.Log("打开关于");
        }
    }
}
