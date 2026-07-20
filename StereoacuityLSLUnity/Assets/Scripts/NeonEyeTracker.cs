using UnityEngine;
using PupilLabs;

public class EyeTrackingManager : MonoBehaviour
{
    [Header("Neon Provider")]
    public GazeDataProvider gazeProvider;

    [Header("Current Gaze")]
    public bool hasGaze;
    public Vector3 gazeOrigin;
    public Vector3 gazeDirection;
    public Vector2 gazePoint;
    public Ray gazeRay;

    [Header("Diagnostics")]
    public int gazeSamplesReceived;

    private float nextLogTime;
    private bool subscribed;

    private void Awake()
    {
        Debug.Log("[EyeTrackingManager] Awake.");
    }

    private void OnEnable()
    {
        Debug.Log("[EyeTrackingManager] Enabled.");
        SubscribeToProvider();
    }

    private void Start()
    {
        // Subscribe again here in case the Neon provider was not ready
        // when OnEnable was first called.
        SubscribeToProvider();

        if (gazeProvider == null)
        {
            Debug.LogError(
                "[EyeTrackingManager] No GazeDataProvider assigned."
            );
        }
        else
        {
            Debug.Log(
                "[EyeTrackingManager] Provider assigned: " +
                gazeProvider.gameObject.name +
                " / " +
                gazeProvider.GetType().Name
            );

            Debug.Log(
                "[EyeTrackingManager] Provider active=" +
                gazeProvider.gameObject.activeInHierarchy +
                ", component enabled=" +
                gazeProvider.enabled
            );
        }
    }

    private void Update()
    {
        if (Time.unscaledTime >= nextLogTime)
        {
            nextLogTime = Time.unscaledTime + 1f;

            Debug.Log(
                "[EyeTrackingManager] subscribed=" +
                subscribed +
                ", hasGaze=" +
                hasGaze +
                ", samples=" +
                gazeSamplesReceived
            );
        }
    }

    private void SubscribeToProvider()
    {
        if (gazeProvider == null)
        {
            Debug.LogWarning(
                "[EyeTrackingManager] Cannot subscribe: provider is null."
            );

            return;
        }

        // Prevent accidental duplicate subscriptions.
        gazeProvider.gazeDataReady.RemoveListener(
            OnGazeDataReady
        );

        gazeProvider.gazeDataReady.AddListener(
            OnGazeDataReady
        );

        subscribed = true;

        Debug.Log(
            "[EyeTrackingManager] Subscribed to gazeDataReady."
        );
    }

    private void OnDisable()
    {
        if (gazeProvider != null)
        {
            gazeProvider.gazeDataReady.RemoveListener(
                OnGazeDataReady
            );
        }

        subscribed = false;

        Debug.Log(
            "[EyeTrackingManager] Disabled and unsubscribed."
        );
    }

    public void OnGazeDataReady(
        GazeDataProvider provider)
    {
        gazeSamplesReceived++;
        hasGaze = true;

        gazeRay = provider.GazeRay;
        gazeOrigin = gazeRay.origin;
        gazeDirection = gazeRay.direction;
        gazePoint = provider.RawGazePoint;

        if (
            gazeSamplesReceived <= 5 ||
            gazeSamplesReceived % 100 == 0
        )
        {
            Debug.Log(
                "[EyeTrackingManager] Gaze sample " +
                gazeSamplesReceived +
                ": origin=" +
                gazeOrigin +
                ", direction=" +
                gazeDirection +
                ", point=" +
                gazePoint
            );
        }
    }
}