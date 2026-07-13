using System;
using System.IO;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class NeonConnectionManager : MonoBehaviour
{
    [Header("UI")]
    [SerializeField] private TMP_InputField ipInput;
    [SerializeField] private TMP_Text statusText;
    [SerializeField] private Button saveButton;
    [SerializeField] private Button startExperimentButton;
    [SerializeField] private GameObject setupCanvas;

    private string ConfigPath =>
        Path.Combine(Application.persistentDataPath, "config.json");

    private void Start()
    {
        if (saveButton != null)
            saveButton.onClick.AddListener(SaveIpAddress);

        if (startExperimentButton != null)
            startExperimentButton.onClick.AddListener(StartExperiment);

        LoadCurrentIp();
    }

    private void OnDestroy()
    {
        if (saveButton != null)
            saveButton.onClick.RemoveListener(SaveIpAddress);

        if (startExperimentButton != null)
            startExperimentButton.onClick.RemoveListener(StartExperiment);
    }

    private void LoadCurrentIp()
    {
        if (!File.Exists(ConfigPath))
        {
            SetStatus($"Config file not found:\n{ConfigPath}");
            return;
        }

        try
        {
            string json = File.ReadAllText(ConfigPath);
            NeonConfig config = JsonUtility.FromJson<NeonConfig>(json);

            if (config?.rtspSettings == null)
            {
                SetStatus("Could not read Neon RTSP settings.");
                return;
            }

            if (ipInput != null)
                ipInput.text = config.rtspSettings.ip;

            SetStatus($"Current Companion IP: {config.rtspSettings.ip}");
        }
        catch (Exception ex)
        {
            SetStatus($"Could not read configuration:\n{ex.Message}");
        }
    }

    public void SaveIpAddress()
    {
        string ip = ipInput != null ? ipInput.text.Trim() : "";

        if (!IsValidIpv4(ip))
        {
            SetStatus("Enter a valid IPv4 address.");
            return;
        }

        if (!File.Exists(ConfigPath))
        {
            SetStatus($"Config file not found:\n{ConfigPath}");
            return;
        }

        try
        {
            string json = File.ReadAllText(ConfigPath);
            NeonConfig config = JsonUtility.FromJson<NeonConfig>(json);

            if (config?.rtspSettings == null)
            {
                SetStatus("Could not read Neon RTSP settings.");
                return;
            }

            config.rtspSettings.autoIp = false;
            config.rtspSettings.ip = ip;

            File.WriteAllText(
                ConfigPath,
                JsonUtility.ToJson(config, true)
            );

            PlayerPrefs.SetString("NeonCompanionIp", ip);
            PlayerPrefs.Save();

            SetStatus(
                $"Saved Companion IP: {ip}\n" +
                "Restart Play mode if the address has changed."
            );
        }
        catch (Exception ex)
        {
            SetStatus($"Could not save configuration:\n{ex.Message}");
        }
    }

    public void StartExperiment()
    {
        if (setupCanvas != null)
            setupCanvas.SetActive(false);

        Debug.Log("[NeonConnectionManager] Researcher setup completed.");
    }

    private static bool IsValidIpv4(string ip)
    {
        return System.Net.IPAddress.TryParse(ip, out var address)
            && address.AddressFamily ==
               System.Net.Sockets.AddressFamily.InterNetwork;
    }

    private void SetStatus(string message)
    {
        Debug.Log($"[NeonConnectionManager] {message}");

        if (statusText != null)
            statusText.text = message;
    }

    [Serializable]
    private class NeonConfig
    {
        public RtspSettings rtspSettings;
        public SensorCalibration sensorCalibration;
    }

    [Serializable]
    private class RtspSettings
    {
        public bool autoIp;
        public string deviceName;
        public string ip;
        public bool useUdp;
        public int port;
        public int dnsPort;
        public int timeEchoPort;
    }

    [Serializable]
    private class SensorCalibration
    {
        public Offset offset;
    }

    [Serializable]
    private class Offset
    {
        public Vector3 position;
        public Vector3 rotation;
    }
}