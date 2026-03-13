using UnityEngine;
using UnityEngine.SceneManagement;

namespace ZhouXing.Core
{
    /// <summary>
    /// 场景管理器
    /// </summary>
    public class SceneController : MonoBehaviour
    {
        public static SceneController Instance { get; private set; }

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
        }

        /// <summary>
        /// 加载场景
        /// </summary>
        public void LoadScene(string sceneName)
        {
            Debug.Log($"加载场景: {sceneName}");
            SceneManager.LoadScene(sceneName);
        }

        /// <summary>
        /// 异步加载场景
        /// </summary>
        public void LoadSceneAsync(string sceneName)
        {
            StartCoroutine(LoadSceneCoroutine(sceneName));
        }

        private System.Collections.IEnumerator LoadSceneCoroutine(string sceneName)
        {
            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);
            
            while (!asyncLoad.isDone)
            {
                float progress = Mathf.Clamp01(asyncLoad.progress / 0.9f);
                Debug.Log($"加载进度: {progress * 100}%");
                yield return null;
            }
            
            Debug.Log($"场景加载完成: {sceneName}");
        }

        /// <summary>
        /// 获取当前场景名称
        /// </summary>
        public string GetCurrentSceneName()
        {
            return SceneManager.GetActiveScene().name;
        }
    }
}
