using UnityEngine;

namespace ZhouXing.Core
{
    /// <summary>
    /// 预制体和场景设置器
    /// </summary>
    public class GameSetup : MonoBehaviour
    {
        [Header("游戏对象")]
        public GameObject gameManagerPrefab;
        public GameObject combatSystemPrefab;
        public GameObject playerPrefab;
        public GameObject enemyPrefab;

        private void Awake()
        {
            // 确保游戏管理器存在
            if (FindObjectOfType<GameManager>() == null)
            {
                if (gameManagerPrefab != null)
                {
                    Instantiate(gameManagerPrefab);
                }
                else
                {
                    gameObject.AddComponent<GameManager>();
                }
            }

            // 确保战斗系统存在
            if (FindObjectOfType<Combat.RpsCombatSystem>() == null)
            {
                if (combatSystemPrefab != null)
                {
                    Instantiate(combatSystemPrefab);
                }
                else
                {
                    gameObject.AddComponent<Combat.RpsCombatSystem>();
                }
            }

            // 确保场景控制器存在
            if (FindObjectOfType<SceneController>() == null)
            {
                gameObject.AddComponent<SceneController>();
            }
        }

        private void Start()
        {
            Debug.Log("游戏设置完成");
        }
    }
}
