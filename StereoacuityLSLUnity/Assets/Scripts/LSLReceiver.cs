using UnityEngine;
using LSL;

public class LSLReceiver : MonoBehaviour
{
    private StreamInlet inlet;

    void Start()
    {
        Debug.Log("Looking for LSL stream...");

        StreamInfo[] results = LSL.LSL.resolve_stream("type", "Markers", 1, 5.0);

        if (results.Length > 0)
        {
            inlet = new StreamInlet(results[0]);
            Debug.Log("Connected to LSL stream.");
        }
        else
        {
            Debug.LogWarning("No LSL stream found yet.");
        }
    }

    void Update()
    {
        if (inlet == null) return;

        string[] sample = new string[1];
        double timestamp = inlet.pull_sample(sample, 0.0f);

        if (timestamp != 0.0)
        {
            Debug.Log("Received from MATLAB: " + sample[0]);
        }
    }
}