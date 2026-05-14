using UnityEngine;
using UnityEngine.InputSystem;
using LSL;

public class LSLSender : MonoBehaviour
{
    private StreamOutlet outlet;

    public LSLReceiver receiver;

    void Start()
    {
        StreamInfo info = new StreamInfo(
            "Unity_to_MATLAB",
            "Markers",
            1,
            0,
            channel_format_t.cf_string,
            "unity_matlab_test_001"
        );

        outlet = new StreamOutlet(info);

        Debug.Log("Unity LSL outlet created.");
    }

    void Update()
    {
        if (receiver == null) return;

        if (!receiver.TrialActive) return;

        if (Keyboard.current.leftArrowKey.wasPressedThisFrame)
        {
            SendResponse("left");
        }

        if (Keyboard.current.rightArrowKey.wasPressedThisFrame)
        {
            SendResponse("right");
        }
    }

    private void SendResponse(string response)
    {
        float rt = Time.time - receiver.StimulusOnsetTime;

        string message =
            $"RESPONSE,{receiver.CurrentTrialID},{response},{rt:F3}";

        outlet.push_sample(new string[] { message });

        Debug.Log("Sent to MATLAB: " + message);

        receiver.EndTrial();
    }
}