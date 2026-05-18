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

    [Header("Response UI")]
    public GameObject responsePanel;

    [Header("TCP")]
    public TcpServerManager tcpServer;

    private bool trialRunning = false;
    private bool responseReceived = false;

    private string currentTargetSymbol;
    private string response;
    private float responseTime;

    private void Start()
    {
        if (stimulusCube != null)
            stimulusCube.SetActive(false);

        if (responsePanel != null)
            responsePanel.SetActive(false);

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "Stereoacuity Test\n\n" +
                "You will see a hidden shape briefly appear on the screen.\n\n" +
                "Try to keep your head still and look toward the centre of the screen.\n\n" +
                "After each stimulus, select the symbol you perceived.\n\n" +
                "If you are unsure, please make your best guess.\n\n" +
                "Waiting for the experiment to begin...";
        }
    }

    public void StartTrialFromTcp(int trialId, float value, string targetSymbol)
    {
        if (trialRunning)
        {
            Debug.LogWarning("Trial trigger ignored because a trial is already running.");

            if (tcpServer != null)
                tcpServer.SendMessageToClient($"ERROR,{trialId},TRIAL_ALREADY_RUNNING");

            return;
        }

        currentTargetSymbol = targetSymbol;

        Debug.Log($"Target symbol for this trial: {currentTargetSymbol}");

        StartCoroutine(RunTrial(trialId, value));
    }

    private IEnumerator RunTrial(int trialId, float value)
    {
        trialRunning = true;
        responseReceived = false;

        response = "";
        responseTime = -1f;

        // Hide everything except the ready instruction
        if (stimulusCube != null)
            stimulusCube.SetActive(false);

        if (responsePanel != null)
            responsePanel.SetActive(false);

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "Focus on the centre of the screen.\n\n" +
                "Press SPACE when ready to begin.";
        }

        if (tcpServer != null)
            tcpServer.SendMessageToClient($"TRIAL_READY,{trialId},OK");

        // Wait for Space press
        while (Keyboard.current == null ||
               !Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            yield return null;
        }

        // Hide instructions
        if (instructionText != null)
            instructionText.gameObject.SetActive(false);

        // Show stimulus
        if (stimulusCube != null)
        {
            stimulusCube.SetActive(true);
            stimulusCube.transform.position =
                new Vector3(value * 0.01f, 0f, 3f);
        }

        // Start stimulus timing
        float trialStartTime = Time.realtimeSinceStartup;
        string unityStartWallClock =
            DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");

        Debug.Log($"Running trial {trialId}");

        if (tcpServer != null)
        {
            tcpServer.SendMessageToClient(
                $"TRIAL_STARTED,{trialId},OK,{trialStartTime:F6},{unityStartWallClock}"
            );
        }

        // Stimulus visible for 2 seconds
        yield return new WaitForSeconds(2f);

        // Hide stimulus
        if (stimulusCube != null)
            stimulusCube.SetActive(false);

        // Show response panel
        responseReceived = false;

        if (responsePanel != null)
            responsePanel.SetActive(true);

        // Wait for participant to click a symbol
        while (!responseReceived)
        {
            yield return null;
        }

        string unityResponseWallClock =
            DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");

        float rt = responseTime - trialStartTime;

        bool correct = string.Equals(
            response,
            currentTargetSymbol,
            StringComparison.OrdinalIgnoreCase
        );

        string accuracy = correct ? "CORRECT" : "INCORRECT";

        Debug.Log(
            $"Trial {trialId} complete. Target: {currentTargetSymbol}, " +
            $"Response: {response}, {accuracy}, RT: {rt:F3}"
        );

        if (tcpServer != null)
        {
            tcpServer.SendMessageToClient(
                $"TRIAL_COMPLETE,{trialId},{response},{accuracy},{rt:F6},{trialStartTime:F6},{responseTime:F6},{unityStartWallClock},{unityResponseWallClock}"
            );
        }

        trialRunning = false;
    }

    public void OnSymbolSelected(string selectedSymbol)
    {
        response = selectedSymbol;
        responseTime = Time.realtimeSinceStartup;

        if (responsePanel != null)
            responsePanel.SetActive(false);

        responseReceived = true;

        Debug.Log($"Participant selected: {selectedSymbol}");
    }
}