using UnityEngine;
using LSL;

public class LSLReceiver : MonoBehaviour
{
    public GameObject stimulusObject;

    private StreamInlet inlet;
    private float nextResolveTime = 0f;
    private float resolveInterval = 1f;

    private bool trialActive = false;
    private int currentTrialID = -1;
    private float currentDisparity = 0f;
    private float stimulusOnsetTime = 0f;

    public bool TrialActive => trialActive;
    public int CurrentTrialID => currentTrialID;
    public float StimulusOnsetTime => stimulusOnsetTime;

    void Start()
    {
        if (stimulusObject != null)
            stimulusObject.SetActive(false);

        Debug.Log("LSLReceiver started. Waiting for MATLAB stream...");
    }

    void Update()
    {
        if (inlet == null)
        {
            TryResolveStream();
            return;
        }

        string[] sample = new string[1];
        double timestamp = inlet.pull_sample(sample, 0.0f);

        if (timestamp != 0.0)
        {
            ProcessMessage(sample[0]);
        }
    }

    private void TryResolveStream()
    {
        if (Time.time < nextResolveTime) return;

        nextResolveTime = Time.time + resolveInterval;

        StreamInfo[] results = LSL.LSL.resolve_stream("name", "MATLAB_to_Unity", 1, 0.1);

        if (results.Length > 0)
        {
            inlet = new StreamInlet(results[0]);
            Debug.Log("Connected to MATLAB LSL stream.");
        }
    }

    private void ProcessMessage(string message)
    {
        Debug.Log("Raw message: " + message);

        string[] parts = message.Split(',');

        if (parts.Length < 3)
        {
            Debug.LogWarning("Invalid message format.");
            return;
        }

        if (parts[0] == "TRIAL_START")
        {
            currentTrialID = int.Parse(parts[1]);
            currentDisparity = float.Parse(parts[2]);

            StartTrial(currentTrialID, currentDisparity);
        }
    }

    private void StartTrial(int trialID, float disparity)
    {
        trialActive = true;
        stimulusOnsetTime = Time.time;

        if (stimulusObject != null)
            stimulusObject.SetActive(true);

        Debug.Log("Trial started.");
        Debug.Log("Trial ID: " + trialID);
        Debug.Log("Disparity: " + disparity + " arcsec");
        Debug.Log("Stimulus onset Unity time: " + stimulusOnsetTime);
    }

    public void EndTrial()
    {
        trialActive = false;

        if (stimulusObject != null)
            stimulusObject.SetActive(false);

        Debug.Log("Trial ended.");
    }
}