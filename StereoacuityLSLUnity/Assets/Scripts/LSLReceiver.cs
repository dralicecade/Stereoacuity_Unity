using UnityEngine;
using LSL;

public class LSLReceiver : MonoBehaviour
{
    private StreamInlet inlet;
    private float nextResolveTime = 0f;
    private float resolveInterval = 1f;

    void Start()
    {
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
            Debug.Log("Received from MATLAB: " + sample[0]);
        }
    }

    private void TryResolveStream()
    {
        if (Time.time < nextResolveTime) return;

        nextResolveTime = Time.time + resolveInterval;

        Debug.Log("Looking for LSL stream...");

        StreamInfo[] results = LSL.LSL.resolve_stream("type", "Markers", 1, 0.1);

        if (results.Length > 0)
        {
            inlet = new StreamInlet(results[0]);
            Debug.Log("Connected to LSL stream.");
        }
    }
}