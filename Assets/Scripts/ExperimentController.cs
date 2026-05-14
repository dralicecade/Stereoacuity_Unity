// ExperimentController.cs
// Orchestrates the stereoacuity experiment trial loop.
//
// Trial sequence
// ──────────────
// 1. Wait until LSLManager is connected to the MATLAB QUEST stream.
// 2. Poll for the next QUEST-suggested disparity from MATLAB.
// 3. Show a fixation cross for a configurable interval.
// 4. Present the RDS stimulus.
// 5. Wait for the subject to press one of four response keys (arrow keys).
// 6. Record whether the answer was correct and send the result back to MATLAB.
// 7. Show a blank inter-trial interval, then repeat.
//
// The experiment ends automatically after MaxTrials, or can be quit at any
// time with the EscapeKey.
//
// Response task: four-alternative forced-choice (4AFC) — the target can be in
// one of four quadrants.  Chance performance is 25 %.  The subject presses
// Up / Down / Left / Right arrow keys to indicate perceived target location.
// This is communicated to ExperimentController through the
// StereoAcuityStimulus.TargetQuadrant property (set randomly each trial).

using System.Collections;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(LSLManager))]
public class ExperimentController : MonoBehaviour
{
    // -----------------------------------------------------------------------
    // Inspector fields
    // -----------------------------------------------------------------------
    [Header("Scene References")]
    [SerializeField] private StereoAcuityStimulus stimulus;
    [SerializeField] private Text                 statusText;

    [Header("Timing (seconds)")]
    [Tooltip("Duration of the fixation cross before each stimulus.")]
    [SerializeField] private float fixationDurationSec = 0.5f;

    [Tooltip("Maximum time allowed for the subject to respond.")]
    [SerializeField] private float responseTimeoutSec = 3.0f;

    [Tooltip("Duration of blank screen between trials.")]
    [SerializeField] private float interTrialIntervalSec = 0.5f;

    [Header("Experiment")]
    [Tooltip("Stop automatically after this many trials (0 = run until manually stopped).")]
    [SerializeField] private int maxTrials = 50;

    [Tooltip("Key that immediately ends the experiment.")]
    [SerializeField] private KeyCode escapeKey = KeyCode.Escape;

    // -----------------------------------------------------------------------
    // Private state
    // -----------------------------------------------------------------------
    private LSLManager _lslManager;
    private int        _trialNumber = 0;
    private bool       _running     = false;

    // Which quadrant (0–3: Top, Right, Bottom, Left) contains the disparate
    // target this trial.
    private int _targetQuadrant;

    // Keyboard codes for the four response directions.
    private static readonly KeyCode[] ResponseKeys =
    {
        KeyCode.UpArrow,
        KeyCode.RightArrow,
        KeyCode.DownArrow,
        KeyCode.LeftArrow,
    };

    // -----------------------------------------------------------------------
    // Unity lifecycle
    // -----------------------------------------------------------------------
    private void Awake()
    {
        _lslManager = GetComponent<LSLManager>();
    }

    private void Start()
    {
        SetStatus("Waiting for MATLAB QUEST connection…");
        StartCoroutine(RunExperiment());
    }

    private void Update()
    {
        if (Input.GetKeyDown(escapeKey) && _running)
        {
            StopAllCoroutines();
            stimulus.HideStimulus();
            SetStatus("Experiment stopped by user.");
            Debug.Log("[Experiment] Stopped by user.");
        }
    }

    // -----------------------------------------------------------------------
    // Experiment loop
    // -----------------------------------------------------------------------
    private IEnumerator RunExperiment()
    {
        // Wait for LSL connection to MATLAB
        while (!_lslManager.IsConnectedToMatlab)
            yield return null;

        _running = true;
        SetStatus("Connected. Starting experiment…");
        Debug.Log("[Experiment] Connected to MATLAB. Starting.");

        while (maxTrials == 0 || _trialNumber < maxTrials)
        {
            _trialNumber++;

            // ── Step 1: Wait for QUEST decision ─────────────────────────
            SetStatus($"Trial {_trialNumber} — waiting for MATLAB decision…");
            float? log10Disparity = null;
            while (log10Disparity == null)
            {
                log10Disparity = _lslManager.PollQuestDecision();
                yield return null;
            }

            float dispArcSec = Mathf.Pow(10f, log10Disparity.Value);
            Debug.Log($"[Experiment] Trial {_trialNumber}: disparity = {dispArcSec:F2} arcsec (log10 = {log10Disparity.Value:F3})");

            // ── Step 2: Fixation ─────────────────────────────────────────
            SetStatus("+");
            yield return new WaitForSeconds(fixationDurationSec);

            // ── Step 3: Present stimulus ──────────────────────────────────
            _targetQuadrant = Random.Range(0, 4);
            stimulus.ShowStimulus(dispArcSec);
            SetStatus($"Trial {_trialNumber} — respond with arrow keys");

            // ── Step 4: Collect response ──────────────────────────────────
            int  responseQuadrant = -1;
            bool timedOut         = false;
            float elapsed = 0f;

            while (responseQuadrant < 0 && elapsed < responseTimeoutSec)
            {
                for (int k = 0; k < ResponseKeys.Length; k++)
                {
                    if (Input.GetKeyDown(ResponseKeys[k]))
                    {
                        responseQuadrant = k;
                        break;
                    }
                }
                elapsed += Time.deltaTime;
                yield return null;
            }

            if (responseQuadrant < 0)
            {
                timedOut = true;
                Debug.Log($"[Experiment] Trial {_trialNumber}: response timed out.");
            }

            bool correct = !timedOut && (responseQuadrant == _targetQuadrant);

            // ── Step 5: Send result to MATLAB ─────────────────────────────
            stimulus.HideStimulus();
            _lslManager.SendTrialResult(log10Disparity.Value, correct);

            SetStatus(correct ? "✓ Correct" : timedOut ? "— Timeout" : "✗ Incorrect");
            Debug.Log($"[Experiment] Trial {_trialNumber}: correct = {correct}");

            // ── Step 6: Inter-trial interval ──────────────────────────────
            yield return new WaitForSeconds(interTrialIntervalSec);
        }

        // ── Experiment complete ───────────────────────────────────────────
        _running = false;
        SetStatus($"Experiment complete ({_trialNumber} trials). See MATLAB for threshold.");
        Debug.Log("[Experiment] All trials complete.");
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------
    private void SetStatus(string message)
    {
        if (statusText != null)
            statusText.text = message;
    }
}
