using UnityEngine;
using UnityEngine.InputSystem;
using LSL;

public class LSLSender : MonoBehaviour
{
    private StreamOutlet outlet;

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
        if (Keyboard.current != null && Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            string marker = "UNITY_SPACE_PRESS";
            outlet.push_sample(new string[] { marker });

            Debug.Log("Sent to MATLAB: " + marker);
        }
    }
}
