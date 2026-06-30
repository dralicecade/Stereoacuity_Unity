using UnityEngine;
using PupilLabs;

public class EyeTrackingManager : MonoBehaviour
{
    public GazeDataProvider gazeProvider;

    public bool hasGaze;
    public Vector3 gazeOrigin;
    public Vector3 gazeDirection;
    public Vector2 gazePoint;
    public Ray gazeRay;

    private void OnEnable()
    {
        if (gazeProvider != null)
            gazeProvider.gazeDataReady.AddListener(OnGazeDataReady);
    }

    private void OnDisable()
    {
        if (gazeProvider != null)
            gazeProvider.gazeDataReady.RemoveListener(OnGazeDataReady);
    }

    public void OnGazeDataReady(GazeDataProvider provider)
    {
        hasGaze = true;

        gazeRay = provider.GazeRay;
        gazeOrigin = gazeRay.origin;
        gazeDirection = gazeRay.direction;
        gazePoint = provider.RawGazePoint;

        Debug.Log($"Gaze: origin={gazeOrigin}, dir={gazeDirection}, point={gazePoint}");
    }
}