using System.Collections.Generic;
using UnityEngine;

namespace ZhouXing.Game.Audio
{
    /// <summary>
    /// 音频类型
    /// </summary>
    public enum AudioType
    {
        BGM,      // 背景音乐
        SFX,      // 音效
        VO,       // 语音
        AMB        // 环境音
    }

    /// <summary>
    /// 场景音乐配置
    /// </summary>
    [System.Serializable]
    public class SceneMusic
    {
        public string sceneName;
        public AudioClip bgm;
        public float bgmVolume = 0.8f;
    }

    /// <summary>
    /// 音效配置
    /// </summary>
    [System.Serializable]
    public class SoundEffect
    {
        public string name;
        public AudioClip clip;
        public float volume = 1.0f;
    }

    /// <summary>
    /// 音频设置
    /// </summary>
    [System.Serializable]
    public class AudioSettings
    {
        public float masterVolume = 1.0f;
        public float bgmVolume = 0.8f;
        public float sfxVolume = 1.0f;
        public float voVolume = 1.0f;
        public float ambVolume = 0.5f;
        public bool isMuted = false;
    }

    /// <summary>
    /// 音频管理器 - 管理背景音乐和音效
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        private static AudioManager _instance;
        public static AudioManager Instance => _instance;

        // 音频设置
        [Header("音频设置")]
        [SerializeField] private AudioSettings audioSettings = new AudioSettings();

        // 音频源
        [Header("音频源")]
        [SerializeField] private AudioSource bgmSource;
        [SerializeField] private AudioSource sfxSource;
        [SerializeField] private AudioSource voSource;
        [SerializeField] private AudioSource ambSource;

        // BGM列表
        [Header("BGM列表")]
        [SerializeField] private AudioClip titleBGM;
        [SerializeField] private AudioClip battleBGM;
        [SerializeField] private AudioClip bossBGM;
        [SerializeField] private AudioClip shopBGM;
        [SerializeField] private AudioClip restBGM;
        [SerializeField] private AudioClip victoryBGM;
        [SerializeField] private AudioClip defeatBGM;

        // 当前BGM
        private AudioClip currentBGM;
        private bool isBGMFading = false;

        void Awake()
        {
            _instance = this;
            InitializeAudioSources();
            LoadSettings();
        }

        /// <summary>
        /// 初始化音频源
        /// </summary>
        private void InitializeAudioSources()
        {
            // 创建音频源
            if (bgmSource == null)
            {
                bgmSource = CreateAudioSource("BGM Source", true);
                bgmSource.loop = true;
            }

            if (sfxSource == null)
            {
                sfxSource = CreateAudioSource("SFX Source", false);
            }

            if (voSource == null)
            {
                voSource = CreateAudioSource("VO Source", false);
            }

            if (ambSource == null)
            {
                ambSource = CreateAudioSource("AMB Source", true);
                ambSource.loop = true;
            }
        }

        private AudioSource CreateAudioSource(string name, bool playOnAwake)
        {
            GameObject obj = new GameObject(name);
            obj.transform.SetParent(transform);

            AudioSource source = obj.AddComponent<AudioSource>();
            source.playOnAwake = playOnAwake;
            source.outputAudioMixerGroup = null;

            return source;
        }

        #region BGM控制

        /// <summary>
        /// 播放BGM
        /// </summary>
        public void PlayBGM(AudioClip clip, float fadeTime = 1f)
        {
            if (clip == null) return;

            if (isBGMFading) return;

            if (currentBGM == clip)
            {
                // 已经在播放这首BGM
                return;
            }

            StartCoroutine(FadeToNewBGM(clip, fadeTime));
        }

        /// <summary>
        /// 播放标题BGM
        /// </summary>
        public void PlayTitleBGM()
        {
            PlayBGM(titleBGM);
        }

        /// <summary>
        /// 播放战斗BGM
        /// </summary>
        public void PlayBattleBGM()
        {
            PlayBGM(battleBGM);
        }

        /// <summary>
        /// 播放BOSS BGM
        /// </summary>
        public void PlayBossBGM()
        {
            PlayBGM(bossBGM);
        }

        /// <summary>
        /// 播放商店BGM
        /// </summary>
        public void PlayShopBGM()
        {
            PlayBGM(shopBGM);
        }

        /// <summary>
        /// 播放休息BGM
        /// </summary>
        public void PlayRestBGM()
        {
            PlayBGM(restBGM);
        }

        /// <summary>
        /// 播放胜利BGM
        /// </summary>
        public void PlayVictoryBGM()
        {
            PlayBGM(victoryBGM, 0.5f);
        }

        /// <summary>
        /// 播放失败BGM
        /// </summary>
        public void PlayDefeatBGM()
        {
            PlayBGM(defeatBGM, 0.5f);
        }

        /// <summary>
        /// 停止BGM
        /// </summary>
        public void StopBGM(float fadeTime = 1f)
        {
            StartCoroutine(FadeVolume(bgmSource, 0, fadeTime, () =>
            {
                bgmSource.Stop();
                currentBGM = null;
            }));
        }

        /// <summary>
        /// 淡入淡出到新BGM
        /// </summary>
        private System.Collections.IEnumerator FadeToNewBGM(AudioClip newClip, float fadeTime)
        {
            isBGMFading = true;

            // 淡出当前BGM
            if (bgmSource.isPlaying)
            {
                yield return StartCoroutine(FadeVolume(bgmSource, 0, fadeTime / 2));
                bgmSource.Stop();
            }

            // 切换BGM
            bgmSource.clip = newClip;
            bgmSource.volume = 0;
            bgmSource.Play();

            // 淡入新BGM
            float targetVolume = audioSettings.masterVolume * audioSettings.bgmVolume;
            yield return StartCoroutine(FadeVolume(bgmSource, targetVolume, fadeTime / 2));

            currentBGM = newClip;
            isBGMFading = false;
        }

        /// <summary>
        /// 渐变音量
        /// </summary>
        private System.Collections.IEnumerator FadeVolume(AudioSource source, float targetVolume, float duration, System.Action onComplete = null)
        {
            float startVolume = source.volume;
            float elapsed = 0;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                source.volume = Mathf.Lerp(startVolume, targetVolume, elapsed / duration);
                yield return null;
            }

            source.volume = targetVolume;
            onComplete?.Invoke();
        }

        #endregion

        #region 音效控制

        /// <summary>
        /// 播放音效
        /// </summary>
        public void PlaySFX(AudioClip clip, float volumeScale = 1f)
        {
            if (clip == null || audioSettings.isMuted) return;

            sfxSource.PlayOneShot(clip, volumeScale * audioSettings.sfxVolume * audioSettings.masterVolume);
        }

        /// <summary>
        /// 播放指定名称的音效
        /// </summary>
        public void PlaySFX(string soundName)
        {
            // 可以通过字典查找音效
            Debug.Log($"播放音效: {soundName}");
        }

        #region 战斗音效

        /// <summary>
        /// 播放出招音效
        /// </summary>
        public void PlayMoveSound(Game.MoveType moveType)
        {
            // 根据出招类型播放不同音效
            switch (moveType)
            {
                case Game.MoveType.Circle:
                    // 出圆音效
                    break;
                case Game.MoveType.Triangle:
                    // 出三角音效
                    break;
                case Game.MoveType.Square:
                    // 出方音效
                    break;
            }
        }

        /// <summary>
        /// 播放攻击音效
        /// </summary>
        public void PlayAttackSound()
        {
            // 播放攻击音效
        }

        /// <summary>
        /// 播放受击音效
        /// </summary>
        public void PlayHitSound()
        {
            // 播放受击音效
        }

        /// <summary>
        /// 播放暴击音效
        /// </summary>
        public void PlayCritSound()
        {
            // 播放暴击音效
        }

        /// <summary>
        /// 播放格挡音效
        /// </summary>
        public void PlayBlockSound()
        {
            // 播放格挡音效
        }

        /// <summary>
        /// 播放连招触发音效
        /// </summary>
        public void PlayComboSound()
        {
            // 播放连招触发音效
        }

        /// <summary>
        /// 播放胜利音效
        /// </summary>
        public void PlayWinSound()
        {
            PlayVictoryBGM();
        }

        /// <summary>
        /// 播放失败音效
        /// </summary>
        public void PlayLoseSound()
        {
            PlayDefeatBGM();
        }

        #endregion

        #region UI音效

        /// <summary>
        /// 播放按钮点击音效
        /// </summary>
        public void PlayButtonClickSound()
        {
            // 播放按钮点击音效
        }

        /// <summary>
        /// 播放购买成功音效
        /// </summary>
        public void PlayBuySound()
        {
            // 播放购买成功音效
        }

        /// <summary>
        /// 播放获得物品音效
        /// </summary>
        public void PlayGetItemSound()
        {
            // 播放获得物品音效
        }

        #endregion

        #endregion

        #region 音量控制

        /// <summary>
        /// 设置主音量
        /// </summary>
        public void SetMasterVolume(float volume)
        {
            audioSettings.masterVolume = Mathf.Clamp01(volume);
            UpdateAllVolumes();
        }

        /// <summary>
        /// 设置BGM音量
        /// </summary>
        public void SetBGMVolume(float volume)
        {
            audioSettings.bgmVolume = Mathf.Clamp01(volume);
            bgmSource.volume = audioSettings.masterVolume * audioSettings.bgmVolume;
        }

        /// <summary>
        /// 设置音效音量
        /// </summary>
        public void SetSFXVolume(float volume)
        {
            audioSettings.sfxVolume = Mathf.Clamp01(volume);
        }

        /// <summary>
        /// 设置语音音量
        /// </summary>
        public void SetVOVolume(float volume)
        {
            audioSettings.voVolume = Mathf.Clamp01(volume);
        }

        /// <summary>
        /// 设置静音
        /// </summary>
        public void SetMuted(bool muted)
        {
            audioSettings.isMuted = muted;
            
            if (muted)
            {
                bgmSource.volume = 0;
            }
            else
            {
                UpdateAllVolumes();
            }
        }

        /// <summary>
        /// 更新所有音量
        /// </summary>
        private void UpdateAllVolumes()
        {
            bgmSource.volume = audioSettings.masterVolume * audioSettings.bgmVolume;
        }

        #endregion

        #region 设置保存

        /// <summary>
        /// 保存设置
        /// </summary>
        public void SaveSettings()
        {
            string json = JsonUtility.ToJson(audioSettings);
            PlayerPrefs.SetString("AudioSettings", json);
            PlayerPrefs.Save();
        }

        /// <summary>
        /// 加载设置
        /// </summary>
        public void LoadSettings()
        {
            string json = PlayerPrefs.GetString("AudioSettings", "");
            
            if (!string.IsNullOrEmpty(json))
            {
                try
                {
                    audioSettings = JsonUtility.FromJson<AudioSettings>(json);
                    Debug.Log("音频设置已加载");
                }
                catch
                {
                    Debug.LogWarning("音频设置加载失败");
                }
            }
            
            UpdateAllVolumes();
        }

        /// <summary>
        /// 重置为默认设置
        /// </summary>
        public void ResetToDefault()
        {
            audioSettings = new AudioSettings();
            UpdateAllVolumes();
            SaveSettings();
        }

        #endregion

        #region 便捷方法

        /// <summary>
        /// 获取音量设置
        /// </summary>
        public AudioSettings GetSettings()
        {
            return audioSettings;
        }

        /// <summary>
        /// BGM是否正在播放
        /// </summary>
        public bool IsBGMPlaying()
        {
            return bgmSource.isPlaying;
        }

        /// <summary>
        /// 暂停BGM
        /// </summary>
        public void PauseBGM()
        {
            bgmSource.Pause();
        }

        /// <summary>
        /// 恢复BGM
        /// </summary>
        public void ResumeBGM()
        {
            bgmSource.UnPause();
        }

        #endregion

        void OnDestroy()
        {
            SaveSettings();
        }
    }

    /// <summary>
    /// 音频扩展方法
    /// </summary>
    public static class AudioExtensions
    {
        /// <summary>
        /// 播放音效（便捷方法）
        /// </summary>
        public static void PlaySound(this AudioManager manager, AudioClip clip)
        {
            manager?.PlaySFX(clip);
        }
    }
}
