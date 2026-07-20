using System;
using System.Globalization;
using System.IO;
using System.Text;
using UnityEngine;

public class GazeStreamRecorder : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private EyeTrackingManager eyeTrackingManager;

    [Header("Recording")]
    [SerializeField] private bool startRecordingAutomatically = true;
    [SerializeField] private float flushIntervalSeconds = 1f;

    public bool IsRecording { get; private set; }
    public string CurrentFilePath { get; private set; }

    private StreamWriter writer;
    private float nextFlushTime;
    private float nextDiagnosticTime;
    private long sampleNumber;

    private int currentTrialId = -1;
    private float currentTrialValue = float.NaN;
    private string currentTargetSymbol = "";
    private string currentPhase = "idle";

    private static readonly CultureInfo Invariant =
        CultureInfo.InvariantCulture;

    private void Start()
    {
        Debug.Log("[GazeStreamRecorder VERSION 3] Start called.");

        if (eyeTrackingManager == null)
        {
            Debug.LogError(
                "[GazeStreamRecorder VERSION 3] " +
                "EyeTrackingManager is not assigned."
            );

            return;
        }

        Debug.Log(
            "[GazeStreamRecorder VERSION 3] " +
            "EyeTrackingManager assigned: " +
            eyeTrackingManager.gameObject.name
        );

        if (startRecordingAutomatically)
            StartRecording();
    }

    private void Update()
    {
        if (Time.unscaledTime >= nextDiagnosticTime)
        {
            nextDiagnosticTime = Time.unscaledTime + 1f;

            if (eyeTrackingManager == null)
            {
                Debug.LogError(
                    "[GazeStreamRecorder] EyeTrackingManager became null."
                );
            }
            else
            {
                Debug.Log(
                    "[GazeStreamRecorder] hasGaze=" +
                    eyeTrackingManager.hasGaze +
                    ", direction=" +
                    eyeTrackingManager.gazeDirection
                );
            }
        }

        if (!IsRecording || writer == null)
            return;

        if (eyeTrackingManager == null)
            return;

        if (!eyeTrackingManager.hasGaze)
            return;

        WriteGazeSample();

        if (Time.unscaledTime >= nextFlushTime)
        {
            writer.Flush();

            nextFlushTime =
                Time.unscaledTime + flushIntervalSeconds;
        }
    }

    public void StartRecording()
    {
        if (IsRecording)
            return;

        string folder = Path.Combine(
            Application.persistentDataPath,
            "GazeData"
        );

        Directory.CreateDirectory(folder);

        string timestamp =
            DateTime.Now.ToString("yyyyMMdd_HHmmss");

        CurrentFilePath = Path.Combine(
            folder,
            $"gaze_{timestamp}.csv"
        );

        try
        {
            writer = new StreamWriter(
                CurrentFilePath,
                false,
                new UTF8Encoding(false)
            );

            writer.WriteLine(
                "sample_number," +
                "pc_unix_time_ms," +
                "unity_time_s," +
                "trial_id," +
                "trial_value," +
                "target_symbol," +
                "phase," +
                "gaze_point_x," +
                "gaze_point_y," +
                "gaze_origin_x," +
                "gaze_origin_y," +
                "gaze_origin_z," +
                "gaze_direction_x," +
                "gaze_direction_y," +
                "gaze_direction_z"
            );

            writer.Flush();

            sampleNumber = 0;
            IsRecording = true;

            nextFlushTime =
                Time.unscaledTime + flushIntervalSeconds;

            Debug.Log(
                "[GazeStreamRecorder VERSION 3] Recording started: " +
                CurrentFilePath
            );
        }
        catch (Exception ex)
        {
            Debug.LogError(
                "[GazeStreamRecorder] Could not create CSV: " +
                ex
            );

            writer = null;
            IsRecording = false;
        }
    }

    private void WriteGazeSample()
    {
        try
        {
            long unixTimeMs =
                DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

            double unityTime =
                Time.realtimeSinceStartupAsDouble;

            Vector2 gazePoint =
                eyeTrackingManager.gazePoint;

            Vector3 gazeOrigin =
                eyeTrackingManager.gazeOrigin;

            Vector3 gazeDirection =
                eyeTrackingManager.gazeDirection;

            sampleNumber++;

            writer.WriteLine(string.Join(",",
                sampleNumber.ToString(Invariant),
                unixTimeMs.ToString(Invariant),
                unityTime.ToString("F6", Invariant),
                currentTrialId.ToString(Invariant),

                float.IsNaN(currentTrialValue)
                    ? ""
                    : currentTrialValue.ToString("G9", Invariant),

                CsvEscape(currentTargetSymbol),
                CsvEscape(currentPhase),

                gazePoint.x.ToString("F6", Invariant),
                gazePoint.y.ToString("F6", Invariant),

                gazeOrigin.x.ToString("F6", Invariant),
                gazeOrigin.y.ToString("F6", Invariant),
                gazeOrigin.z.ToString("F6", Invariant),

                gazeDirection.x.ToString("F6", Invariant),
                gazeDirection.y.ToString("F6", Invariant),
                gazeDirection.z.ToString("F6", Invariant)
            ));

            if (sampleNumber == 1)
            {
                writer.Flush();

                Debug.Log(
                    "[GazeStreamRecorder VERSION 3] " +
                    "First gaze row successfully written."
                );
            }
        }
        catch (Exception ex)
        {
            Debug.LogError(
                "[GazeStreamRecorder] Failed to write gaze row: " +
                ex
            );
        }
    }

    public void StopRecording()
    {
        if (!IsRecording && writer == null)
            return;

        try
        {
            writer?.Flush();
            writer?.Dispose();
        }
        catch (Exception ex)
        {
            Debug.LogError(
                "[GazeStreamRecorder] Error closing CSV: " +
                ex
            );
        }

        writer = null;
        IsRecording = false;

        Debug.Log(
            "[GazeStreamRecorder VERSION 3] Recording stopped. " +
            "Samples written: " +
            sampleNumber +
            ". File: " +
            CurrentFilePath
        );
    }

    private void OnDisable()
    {
        StopRecording();
    }

    private void OnApplicationQuit()
    {
        StopRecording();
    }

    public void SetTrialContext(
        int trialId,
        float trialValue,
        string targetSymbol)
    {
        currentTrialId = trialId;
        currentTrialValue = trialValue;
        currentTargetSymbol = targetSymbol ?? "";
        currentPhase = "trial_ready";
    }

    public void SetPhase(string phase)
    {
        currentPhase =
            string.IsNullOrWhiteSpace(phase)
                ? "unknown"
                : phase;
    }

    public void ClearTrialContext()
    {
        currentTrialId = -1;
        currentTrialValue = float.NaN;
        currentTargetSymbol = "";
        currentPhase = "intertrial";
    }

    private static string CsvEscape(string value)
    {
        if (string.IsNullOrEmpty(value))
            return "";

        return "\"" +
               value.Replace("\"", "\"\"") +
               "\"";
    }
}