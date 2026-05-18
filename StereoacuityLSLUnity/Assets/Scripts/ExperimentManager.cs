using System;
using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using TMPro;

public class ExperimentManager : MonoBehaviour
{
    [Header("Stimulus")]
    public GameObject stimulusCube;

    [Header("Instruction Text")]
    public TextMeshProUGUI instructionText;

    [Header("TCP")]
    public TcpServerManager tcpServer;

    private bool trialRunning = false;

    public void StartTrialFromTcp(int trialId, float value, string targetSymbol)
    {
        Debug.Log($"Target symbol for this trial: {targetSymbol}");
        
        if (trialRunning)
        {
            Debug.LogWarning("Trial trigger ignored because a trial is already running.");
            tcpServer.SendMessageToClient($"ERROR,{trialId},TRIAL_ALREADY_RUNNING");
            return;
        }

        StartCoroutine(RunTrial(trialId, value));
    }

    private IEnumerator RunTrial(int trialId, float value)
    {
        trialRunning = true;

        string response = "";
        float responseTime = -1f;

        stimulusCube.SetActive(false);

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text = "Press 'Space' to start";
        }

        tcpServer.SendMessageToClient($"TRIAL_READY,{trialId},OK");

        while (Keyboard.current == null || !Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            yield return null;
        }

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(false);
        }

        stimulusCube.SetActive(true);
        stimulusCube.transform.position = new Vector3(value * 0.01f, 0f, 3f);

        float trialStartTime = Time.realtimeSinceStartup;
        string unityStartWallClock = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");

        Debug.Log($"Running trial {trialId}");

        tcpServer.SendMessageToClient(
            $"TRIAL_STARTED,{trialId},OK,{trialStartTime:F6},{unityStartWallClock}"
        );

        float maxResponseWindow = 5f;

        while (Time.realtimeSinceStartup - trialStartTime < maxResponseWindow)
        {
            if (Keyboard.current != null && Keyboard.current.leftArrowKey.wasPressedThisFrame)
            {
                response = "LEFT";
                responseTime = Time.realtimeSinceStartup;
                break;
            }

            if (Keyboard.current != null && Keyboard.current.rightArrowKey.wasPressedThisFrame)
            {
                response = "RIGHT";
                responseTime = Time.realtimeSinceStartup;
                break;
            }

            yield return null;
        }

        stimulusCube.SetActive(false);

        if (response == "")
        {
            response = "NO_RESPONSE";
            responseTime = Time.realtimeSinceStartup;
        }

        string unityResponseWallClock = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
        float rt = responseTime - trialStartTime;

        Debug.Log($"Trial {trialId} complete. Response: {response}, RT: {rt:F3}");

        tcpServer.SendMessageToClient(
            $"TRIAL_COMPLETE,{trialId},{response},{rt:F6},{trialStartTime:F6},{responseTime:F6},{unityStartWallClock},{unityResponseWallClock}"
        );

        trialRunning = false;
    }
}