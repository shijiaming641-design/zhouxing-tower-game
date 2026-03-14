using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace ZhouXing.Game.UI
{
    /// <summary>
    /// UI界面类型
    /// </summary>
    public enum UIType
    {
        None,
        MainMenu,
        Battle,
        Shop,
        Inventory,
        Map,
        Settings,
        Pause,
        GameOver,
        Victory
    }

    /// <summary>
    /// UI管理器 - 管理所有界面
    /// </summary>
    public class UIManager : MonoBehaviour
    {
        private static UIManager _instance;
        public static UIManager Instance => _instance;

        // 所有UI面板
        private Dictionary<UIType, GameObject> uiPanels = new Dictionary<UIType, GameObject>();
        
        // 当前显示的界面
        private UIType currentUI = UIType.None;
        
        // UI层级
        [SerializeField] private Canvas mainCanvas;
        [SerializeField] private Transform normalLayer;   // 普通层级
        [SerializeField] private Transform popupLayer;   // 弹窗层级
        [SerializeField] private Transform topLayer;      // 最高层级

        void Awake()
        {
            _instance = this;
            Initialize();
        }

        /// <summary>
        /// 初始化
        /// </summary>
        private void Initialize()
        {
            // 创建基础UI层级
            if (normalLayer == null) CreateLayer("NormalLayer");
            if (popupLayer == null) CreateLayer("PopupLayer");
            if (topLayer == null) CreateLayer("TopLayer");
            
            Debug.Log("UI系统初始化完成");
        }

        private void CreateLayer(string name)
        {
            GameObject layer = new GameObject(name);
            layer.transform.SetParent(mainCanvas.transform);
            
            RectTransform rect = layer.AddComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            
            layer.AddComponent<CanvasRenderer>();
        }

        /// <summary>
        /// 显示界面
        /// </summary>
        public void ShowUI(UIType uiType)
        {
            // 隐藏当前界面
            if (currentUI != UIType.None && currentUI != uiType)
            {
                HideUI(currentUI);
            }

            // 显示新界面
            if (uiPanels.ContainsKey(uiType) && uiPanels[uiType] != null)
            {
                uiPanels[uiType].SetActive(true);
                currentUI = uiType;
                Debug.Log($"显示界面: {uiType}");
            }
            else
            {
                Debug.LogWarning($"界面不存在: {uiType}");
            }
        }

        /// <summary>
        /// 隐藏界面
        /// </summary>
        public void HideUI(UIType uiType)
        {
            if (uiPanels.ContainsKey(uiType) && uiPanels[uiType] != null)
            {
                uiPanels[uiType].SetActive(false);
                
                if (currentUI == uiType)
                {
                    currentUI = UIType.None;
                }
                
                Debug.Log($"隐藏界面: {uiType}");
            }
        }

        /// <summary>
        /// 注册界面
        /// </summary>
        public void RegisterUI(UIType uiType, GameObject panel)
        {
            uiPanels[uiType] = panel;
            
            // 默认隐藏
            if (panel != null)
            {
                panel.SetActive(false);
            }
        }

        /// <summary>
        /// 获取界面
        /// </summary>
        public GameObject GetUI(UIType uiType)
        {
            return uiPanels.ContainsKey(uiType) ? uiPanels[uiType] : null;
        }

        /// <summary>
        /// 显示提示信息
        /// </summary>
        public void ShowTip(string message, float duration = 2f)
        {
            Debug.Log($"提示: {message}");
            // 可以在这里添加Toast或提示UI
        }

        /// <summary>
        /// 显示确认对话框
        /// </summary>
        public void ShowConfirm(string title, string message, System.Action onConfirm, System.Action onCancel = null)
        {
            Debug.Log($"确认对话框: {title} - {message}");
            // 可以在这里添加确认对话框UI
        }

        /// <summary>
        /// 显示加载界面
        /// </summary>
        public void ShowLoading(bool show)
        {
            Debug.Log($"加载界面: {show}");
        }

        /// <summary>
        /// 获取当前界面
        /// </summary>
        public UIType GetCurrentUI()
        {
            return currentUI;
        }

        /// <summary>
        /// 是否显示中
        /// </summary>
        public bool IsShowing(UIType uiType)
        {
            return uiPanels.ContainsKey(uiType) && uiPanels[uiType].activeSelf;
        }
    }

    /// <summary>
    /// 面板基类
    /// </summary>
    public abstract class BasePanel : MonoBehaviour
    {
        protected bool isInitialized = false;

        /// <summary>
        /// 初始化
        /// </summary>
        public virtual void Initialize()
        {
            isInitialized = true;
        }

        /// <summary>
        /// 显示
        /// </summary>
        public virtual void OnShow()
        {
            gameObject.SetActive(true);
        }

        /// <summary>
        /// 隐藏
        /// </summary>
        public virtual void OnHide()
        {
            gameObject.SetActive(false);
        }

        /// <summary>
        /// 刷新
        /// </summary>
        public virtual void OnRefresh()
        {
        }
    }

    /// <summary>
    /// 按钮点击事件
    /// </summary>
    public class ButtonClickEvent : UnityEngine.Events.UnityEvent
    {
    }
}
