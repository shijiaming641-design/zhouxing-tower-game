using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game
{
    /// <summary>
    /// 地图节点类型
    /// </summary>
    public enum NodeType
    {
        Combat,        // 普通战斗
        Elite,         // 精英战斗
        Boss,          // BOSS战
        Shop,          // 商店
        Rest,          // 休息点
        Event,         // 随机事件
        Treasure,      // 宝藏
        Secret         // 隐藏房间
    }

    /// <summary>
    /// 地图节点
    /// </summary>
    [System.Serializable]
    public class MapNode
    {
        public int ID;
        public NodeType Type;
        public int Layer;
        public List<int> NextNodes = new List<int>();
        public bool IsVisited;
        
        // 战斗相关
        public Enemy Enemy;
        
        // 事件相关
        public GameEvent Event;
        
        public MapNode(int id, NodeType type, int layer)
        {
            ID = id;
            Type = type;
            Layer = layer;
        }
        
        public string GetNodeName()
        {
            switch(Type)
            {
                case NodeType.Combat: return "战斗";
                case NodeType.Elite: return "精英";
                case NodeType.Boss: return "BOSS";
                case NodeType.Shop: return "商店";
                case NodeType.Rest: return "休息";
                case NodeType.Event: return "事件";
                case NodeType.Treasure: return "宝藏";
                case NodeType.Secret: return "隐藏";
                default: return "未知";
            }
        }
        
        public string GetNodeIcon()
        {
            switch(Type)
            {
                case NodeType.Combat: return "⚔️";
                case NodeType.Elite: return "👹";
                case NodeType.Boss: return "👑";
                case NodeType.Shop: return "🏪";
                case NodeType.Rest: return "⛺";
                case NodeType.Event: return "❓";
                case NodeType.Treasure: return "💎";
                case NodeType.Secret: return "🔮";
                default: return "❓";
            }
        }
    }

    /// <summary>
    /// 随机事件
    /// </summary>
    [System.Serializable]
    public class GameEvent
    {
        public string ID;
        public string Name;
        public string Description;
        public List<EventChoice> Choices = new List<EventChoice>();
    }

    /// <summary>
    /// 事件选项
    /// </summary>
    [System.Serializable]
    public class EventChoice
    {
        public string Text;
        public string Result;
        public int GoldChange;
        public int ExpChange;
        public string ItemReward;
    }

    /// <summary>
    /// 地图系统 - 负责生成和管理关卡地图
    /// </summary>
    public class MapSystem : MonoBehaviour
    {
        private static MapSystem _instance;
        public static MapSystem Instance => _instance;
        
        // 节点数据
        private List<MapNode> nodes = new List<MapNode>();
        private int currentLayer = 1;
        private int currentNodeIndex = 0;
        private int totalLayers = 4;
        
        // 节点权重配置
        private Dictionary<NodeType, float> nodeWeights = new Dictionary<NodeType, float>()
        {
            { NodeType.Combat, 0.40f },
            { NodeType.Elite, 0.10f },
            { NodeType.Shop, 0.15f },
            { NodeType.Rest, 0.15f },
            { NodeType.Event, 0.15f },
            { NodeType.Treasure, 0.05f }
        };
        
        // 每层节点数
        private int[] layerNodeCounts = { 0, 4, 5, 6, 3 };
        
        void Awake()
        {
            _instance = this;
        }
        
        /// <summary>
        /// 生成新地图
        /// </summary>
        public void GenerateMap()
        {
            nodes.Clear();
            currentLayer = 1;
            currentNodeIndex = 0;
            
            int nodeId = 0;
            
            // 为每层生成节点
            for (int layer = 1; layer <= totalLayers; layer++)
            {
                int nodeCount = layerNodeCounts[layer];
                
                // 最后一层是BOSS
                if (layer == totalLayers)
                {
                    nodes.Add(new MapNode(nodeId++, NodeType.Boss, layer));
                    continue;
                }
                
                // 生成该层节点
                List<MapNode> layerNodes = new List<MapNode>();
                for (int i = 0; i < nodeCount; i++)
                {
                    NodeType type = GetRandomNodeType(layer);
                    layerNodes.Add(new MapNode(nodeId++, type, layer));
                }
                
                // 连接到下一层
                ConnectNodes(layerNodes, layer);
                
                nodes.AddRange(layerNodes);
            }
            
            Debug.Log($"地图已生成，共 {nodes.Count} 个节点");
        }
        
        /// <summary>
        /// 获取随机节点类型
        /// </summary>
        private NodeType GetRandomNodeType(int layer)
        {
            float random = Random.value;
            float cumulative = 0f;
            
            // 第一层不生成精英和BOSS
            if (layer == 1)
            {
                // 调整权重，第一层主要是教学
                Dictionary<NodeType, float> layerWeights = new Dictionary<NodeType, float>()
                {
                    { NodeType.Combat, 0.50f },
                    { NodeType.Shop, 0.20f },
                    { NodeType.Rest, 0.20f },
                    { NodeType.Event, 0.10f }
                };
                
                foreach (var kvp in layerWeights)
                {
                    cumulative += kvp.Value;
                    if (random <= cumulative)
                        return kvp.Key;
                }
            }
            
            foreach (var kvp in nodeWeights)
            {
                cumulative += kvp.Value;
                if (random <= cumulative)
                    return kvp.Key;
            }
            
            return NodeType.Combat;
        }
        
        /// <summary>
        /// 连接节点
        /// </summary>
        private void ConnectNodes(List<MapNode> layerNodes, int layer)
        {
            if (layer >= totalLayers) return;
            
            // 简单连接：每个节点至少连接到一个下一层节点
            int nextLayerStart = GetLayerStartIndex(layer + 1);
            int nextLayerCount = GetLayerNodeCount(layer + 1);
            
            foreach (var node in layerNodes)
            {
                // 随机连接到1-2个下一层节点
                int connections = Random.Range(1, 3);
                for (int i = 0; i < connections; i++)
                {
                    int nextNodeId = nextLayerStart + Random.Range(0, nextLayerCount);
                    if (!node.NextNodes.Contains(nextNodeId))
                    {
                        node.NextNodes.Add(nextNodeId);
                    }
                }
            }
        }
        
        private int GetLayerStartIndex(int layer)
        {
            int index = 0;
            for (int i = 1; i < layer; i++)
            {
                index += layerNodeCounts[i];
            }
            return index;
        }
        
        private int GetLayerNodeCount(int layer)
        {
            if (layer > totalLayers) return 0;
            return layerNodeCounts[layer];
        }
        
        /// <summary>
        /// 获取当前可用的节点
        /// </summary>
        public List<MapNode> GetAvailableNodes()
        {
            List<MapNode> available = new List<MapNode>();
            
            // 找到当前层的所有节点
            List<int> currentLayerNodeIds = new List<int>();
            for (int i = 0; i < nodes.Count; i++)
            {
                if (nodes[i].Layer == currentLayer && i <= currentNodeIndex + 2)
                {
                    // 添加可选的后续节点
                    foreach (int nextId in nodes[i].NextNodes)
                    {
                        if (!nodes[nextId].IsVisited)
                        {
                            available.Add(nodes[nextId]);
                        }
                    }
                }
            }
            
            // 去重
            HashSet<int> uniqueIds = new HashSet<int>();
            List<MapNode> result = new List<MapNode>();
            foreach (var node in available)
            {
                if (!uniqueIds.Contains(node.ID))
                {
                    uniqueIds.Add(node.ID);
                    result.Add(node);
                }
            }
            
            return result;
        }
        
        /// <summary>
        /// 选择节点
        /// </summary>
        public void SelectNode(int nodeId)
        {
            MapNode selectedNode = nodes.Find(n => n.ID == nodeId);
            if (selectedNode != null)
            {
                currentNodeIndex = nodeId;
                Debug.Log($"选择节点: {selectedNode.GetNodeIcon()} {selectedNode.GetNodeName()} (第{selectedNode.Layer}层)");
                
                // 根据节点类型进入对应场景
                EnterNode(selectedNode);
            }
        }
        
        /// <summary>
        /// 进入节点
        /// </summary>
        private void EnterNode(MapNode node)
        {
            switch (node.Type)
            {
                case NodeType.Combat:
                case NodeType.Elite:
                case NodeType.Boss:
                    // 进入战斗
                    BattleSystem.Instance.StartBattle(node.Type == NodeType.Boss);
                    break;
                    
                case NodeType.Shop:
                    // 进入商店
                    Debug.Log("进入商店");
                    // ShopSystem.Instance.OpenShop();
                    break;
                    
                case NodeType.Rest:
                    // 进入休息点
                    Debug.Log("进入休息点");
                    break;
                    
                case NodeType.Event:
                case NodeType.Treasure:
                case NodeType.Secret:
                    // 触发事件
                    Debug.Log($"触发事件: {node.GetNodeName()}");
                    break;
            }
        }
        
        /// <summary>
        /// 节点战斗胜利后调用
        /// </summary>
        public void OnNodeCompleted()
        {
            // 标记当前节点为已访问
            if (currentNodeIndex < nodes.Count)
            {
                nodes[currentNodeIndex].IsVisited = true;
            }
            
            // 检查是否通过当前层
            CheckLayerComplete();
        }
        
        /// <summary>
        /// 检查是否通过当前层
        /// </summary>
        private void CheckLayerComplete()
        {
            // 检查当前层所有节点是否都已访问
            bool layerComplete = true;
            for (int i = 0; i < nodes.Count; i++)
            {
                if (nodes[i].Layer == currentLayer && !nodes[i].IsVisited)
                {
                    layerComplete = false;
                    break;
                }
            }
            
            if (layerComplete)
            {
                Debug.Log($"第 {currentLayer} 层已完成!");
                
                if (currentLayer < totalLayers)
                {
                    currentLayer++;
                    Debug.Log($"进入第 {currentLayer} 层");
                }
                else
                {
                    Debug.Log("通关！恭喜！");
                }
            }
        }
        
        /// <summary>
        /// 获取当前节点
        /// </summary>
        public MapNode GetCurrentNode()
        {
            if (currentNodeIndex < nodes.Count)
                return nodes[currentNodeIndex];
            return null;
        }
        
        /// <summary>
        /// 获取当前层数
        /// </summary>
        public int GetCurrentLayer()
        {
            return currentLayer;
        }
        
        /// <summary>
        /// 获取总层数
        /// </summary>
        public int GetTotalLayers()
        {
            return totalLayers;
        }
        
        /// <summary>
        /// 获取所有节点（用于调试显示）
        /// </summary>
        public List<MapNode> GetAllNodes()
        {
            return nodes;
        }
    }
}
