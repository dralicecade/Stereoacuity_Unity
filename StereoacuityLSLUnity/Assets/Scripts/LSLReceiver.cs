using UnityEngine;
using UnityEngine.InputSystem;

public class LSLReceiver : MonoBehaviour
{
    void Start()
    {
        Debug.Log("LSLReceiver started.");
    }

    void Update()
    {
        if (Keyboard.current != null && Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            Debug.Log("Space key pressed.");
        }
    }
}