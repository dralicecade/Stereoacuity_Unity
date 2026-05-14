// LSLManager.cs
// Manages all Lab Streaming Layer (LSL) communication for the stereoacuity
// experiment.
//
// Outlet  (Unity → MATLAB)  stream name : "UnityTrialResults"
//   channel 0 : log10 disparity that was displayed (arcseconds, log10)
//   channel 1 : subject response  (1 = correct, 0 = incorrect)
//
// Inlet   (MATLAB → Unity)  stream name : "MATLABQuestDecisions"
//   channel 0 : log10 disparity to present next (arcseconds, log10)

using System.Collections;
using UnityEngine;
using LSL;

public class LSLManager : MonoBehaviour
{
    // -----------------------------------------------------------------------
    // Public state
    // -----------------------------------------------------------------------
    public bool IsConnectedToMatlab { get; private set; } = false;

    // -----------------------------------------------------------------------
    // Inspector fields
    // -----------------------------------------------------------------------
    [Tooltip("Name of the LSL outlet this Unity instance creates.")]
    [SerializeField] private string outletName = "UnityTrialResults";

    [Tooltip("Name of the LSL inlet produced by the MATLAB QUEST controller.")]
    [SerializeField] private string inletName = "MATLABQuestDecisions";

    [Tooltip("How long (seconds) to wait between stream-search retries.")]
    [SerializeField] private float searchRetryInterval = 1.0f;

    // -----------------------------------------------------------------------
    // Private LSL objects
    // -----------------------------------------------------------------------
    private StreamOutlet _trialResultsOutlet;
    private StreamInlet  _questDecisionInlet;

    // -----------------------------------------------------------------------
    // Unity lifecycle
    // -----------------------------------------------------------------------
    private void Awake()
    {
        // Create outlet immediately so MATLAB can find it while we search for
        // MATLAB's own outlet in parallel.
        var outletInfo = new StreamInfo(
            outletName,
            "Markers",
            channelCount: 2,
            nominalSrate: 0.0,          // irregular rate (event-driven)
            channelFormat: channel_format_t.cf_float32,
            sourceId: "unity_stereo_acuity");

        _trialResultsOutlet = new StreamOutlet(outletInfo);
        Debug.Log($"[LSL] Outlet '{outletName}' created.");

        StartCoroutine(FindQuestStreamCoroutine());
    }

    private void OnDestroy()
    {
        _trialResultsOutlet?.Dispose();
        _questDecisionInlet?.Dispose();
    }

    // -----------------------------------------------------------------------
    // Public API
    // -----------------------------------------------------------------------

    /// <summary>
    /// Send the result of a completed trial to MATLAB.
    /// </summary>
    /// <param name="log10Disparity">Log10 of the disparity (arcsec) that was shown.</param>
    /// <param name="correct">True if the subject answered correctly.</param>
    public void SendTrialResult(float log10Disparity, bool correct)
    {
        float[] sample = { log10Disparity, correct ? 1f : 0f };
        _trialResultsOutlet.push_sample(sample);
        Debug.Log($"[LSL] Sent trial result — disparity(log10): {log10Disparity:F3}, correct: {correct}");
    }

    /// <summary>
    /// Non-blocking poll for the next QUEST decision from MATLAB.
    /// Returns the log10 disparity (arcsec) to present, or null if no sample
    /// is available yet.
    /// </summary>
    public float? PollQuestDecision()
    {
        if (_questDecisionInlet == null)
            return null;

        float[] sample = new float[1];
        double ts = _questDecisionInlet.pull_sample(sample, timeout: 0.0);
        if (ts == 0.0)
            return null;

        Debug.Log($"[LSL] Received QUEST decision — disparity(log10): {sample[0]:F3}");
        return sample[0];
    }

    // -----------------------------------------------------------------------
    // Internal helpers
    // -----------------------------------------------------------------------
    private IEnumerator FindQuestStreamCoroutine()
    {
        Debug.Log($"[LSL] Searching for MATLAB QUEST stream '{inletName}'…");

        StreamInfo[] found = null;
        while (found == null || found.Length == 0)
        {
            found = LSL.LSL.resolve_stream("name", inletName, minimum: 1, timeout: 2.0);
            if (found == null || found.Length == 0)
            {
                Debug.Log($"[LSL] Stream '{inletName}' not found, retrying…");
                yield return new WaitForSeconds(searchRetryInterval);
            }
        }

        _questDecisionInlet = new StreamInlet(found[0]);
        IsConnectedToMatlab = true;
        Debug.Log($"[LSL] Connected to MATLAB QUEST stream '{inletName}'.");
    }
}
