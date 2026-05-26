using UnityEngine;

public class VRCanvasFollower : MonoBehaviour
{
    public Transform targetCamera;
    public float distance = 2.0f;
    public float heightOffset = 0.0f;

    void LateUpdate()
    {
        if (targetCamera == null)
            return;

        transform.position =
            targetCamera.position +
            targetCamera.forward * distance +
            Vector3.up * heightOffset;

        transform.rotation = Quaternion.LookRotation(
            transform.position - targetCamera.position
        );
    }
}