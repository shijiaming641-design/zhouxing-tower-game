using UnityEngine;

namespace ZhouXing.Effects
{
    /// <summary>
    /// 效果管理器 - 处理视觉和音效效果
    /// </summary>
    public class EffectManager : MonoBehaviour
    {
        public static EffectManager Instance { get; private set; }

        [Header("特效预制体")]
        public GameObject hitEffectPrefab;
        public GameObject victoryEffectPrefab;
        public GameObject defeatEffectPrefab;
        public GameObject healEffectPrefab;

        [Header("音效")]
        public AudioClip[] hitSounds;
        public AudioClip[] victorySounds;
        public AudioClip[] defeatSounds;

        private AudioSource audioSource;

        private void Awake()
        {
            Instance = this;
            audioSource = GetComponent<AudioSource>();
            if (audioSource == null)
            {
                audioSource = gameObject.AddComponent<AudioSource>();
            }
        }

        /// <summary>
        /// 播放受击效果
        /// </summary>
        public void PlayHitEffect(Vector3 position)
        {
            if (hitEffectPrefab != null)
            {
                Instantiate(hitEffectPrefab, position, Quaternion.identity);
            }
            PlayRandomSound(hitSounds);
        }

        /// <summary>
        /// 播放胜利效果
        /// </summary>
        public void PlayVictoryEffect(Vector3 position)
        {
            if (victoryEffectPrefab != null)
            {
                Instantiate(victoryEffectPrefab, position, Quaternion.identity);
            }
            PlayRandomSound(victorySounds);
        }

        /// <summary>
        /// 播放失败效果
        /// </summary>
        public void PlayDefeatEffect(Vector3 position)
        {
            if (defeatEffectPrefab != null)
            {
                Instantiate(defeatEffectPrefab, position, Quaternion.identity);
            }
            PlayRandomSound(defeatSounds);
        }

        /// <summary>
        /// 播放治疗效果
        /// </summary>
        public void PlayHealEffect(Vector3 position)
        {
            if (healEffectPrefab != null)
            {
                Instantiate(healEffectPrefab, position, Quaternion.identity);
            }
        }

        /// <summary>
        /// 播放随机音效
        /// </summary>
        private void PlayRandomSound(AudioClip[] sounds)
        {
            if (sounds != null && sounds.Length > 0)
            {
                AudioClip clip = sounds[Random.Range(0, sounds.Length)];
                audioSource.PlayOneShot(clip);
            }
        }
    }
}
