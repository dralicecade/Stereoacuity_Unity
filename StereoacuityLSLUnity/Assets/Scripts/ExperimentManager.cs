using System;
using System.Collections;
using System.IO;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using TMPro;

public class ExperimentManager : MonoBehaviour
{
    [Header("Stimulus")]
    public GameObject stimulusCube;

    [Header("Stimulus Images")]
    public RawImage leftStimulusImage;
    public RawImage rightStimulusImage;

    [Header("Instruction Text")]
    public TextMeshProUGUI instructionText;

    [Header("Response UI")]
    public GameObject responsePanel;

    [Header("TCP")]
    public TcpServerManager tcpServer;

    [Header("Eye Tracking")]
    public GazeStreamRecorder gazeRecorder;

    private bool trialRunning = false;
    private bool responseReceived = false;

    private string currentTargetSymbol;
    private string response;
    private float responseTime;

    private void Start()
    {
        HideStimuli();

        if (responsePanel != null)
            responsePanel.SetActive(false);

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "You will see a hidden shape briefly appear on the screen.\n" +
                "After each trial, select the symbol you saw.\n" +
                "If you are unsure, please make your best guess.\n" +
                "Waiting to begin...";
        }

        Cursor.visible = true;
        Cursor.lockState = CursorLockMode.None;

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("waiting_for_experiment");

        Debug.Log("Cursor enabled");
    }

    public void StartTrialFromTcp(
        int trialId,
        float value,
        string targetSymbol,
        string leftImagePath,
        string rightImagePath)
    {
        if (trialRunning)
        {
            Debug.LogWarning(
                "Trial trigger ignored because a trial is already running."
            );

            if (tcpServer != null)
            {
                tcpServer.SendMessageToClient(
                    $"ERROR,{trialId},TRIAL_ALREADY_RUNNING"
                );
            }

            return;
        }

        currentTargetSymbol = targetSymbol;

        if (gazeRecorder != null)
        {
            gazeRecorder.SetTrialContext(
                trialId,
                value,
                targetSymbol
            );
        }

        Debug.Log(
            $"Target symbol for this trial: {currentTargetSymbol}"
        );

        Debug.Log($"Left image path: {leftImagePath}");
        Debug.Log($"Right image path: {rightImagePath}");

        StartCoroutine(
            RunTrial(
                trialId,
                value,
                leftImagePath,
                rightImagePath
            )
        );
    }

    private IEnumerator RunTrial(
        int trialId,
        float value,
        string leftImagePath,
        string rightImagePath)
    {
        trialRunning = true;
        responseReceived = false;

        response = "";
        responseTime = -1f;

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("waiting_for_start");

        HideStimuli();

        if (responsePanel != null)
            responsePanel.SetActive(false);

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "Focus on the centre of the screen.\n\n" +
                "Press SPACE to start.";
        }

        if (tcpServer != null)
        {
            tcpServer.SendMessageToClient(
                $"TRIAL_READY,{trialId},OK"
            );
        }

        while (
            Keyboard.current == null ||
            !Keyboard.current.spaceKey.wasPressedThisFrame
        )
        {
            yield return null;
        }

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("loading_stimulus");

        if (instructionText != null)
            instructionText.gameObject.SetActive(false);

        Texture2D leftTex =
            LoadTextureFromFile(leftImagePath);

        Texture2D rightTex =
            LoadTextureFromFile(rightImagePath);

        if (leftStimulusImage != null && leftTex != null)
        {
            leftStimulusImage.texture = leftTex;
            leftStimulusImage.gameObject.SetActive(true);
        }
        else
        {
            Debug.LogError(
                $"Could not load left image: {leftImagePath}"
            );
        }

        if (rightStimulusImage != null && rightTex != null)
        {
            rightStimulusImage.texture = rightTex;
            rightStimulusImage.gameObject.SetActive(true);
        }
        else
        {
            Debug.LogError(
                $"Could not load right image: {rightImagePath}"
            );
        }

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("stimulus_visible");

        float trialStartTime =
            Time.realtimeSinceStartup;

        string unityStartWallClock =
            DateTime.Now.ToString(
                "yyyy-MM-dd HH:mm:ss.fff"
            );

        Debug.Log($"Running trial {trialId}");

        if (tcpServer != null)
        {
            tcpServer.SendMessageToClient(
                $"TRIAL_STARTED,{trialId},OK," +
                $"{trialStartTime:F6}," +
                $"{unityStartWallClock}"
            );
        }

        yield return new WaitForSeconds(2f);

        HideStimuli();

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("response_selection");

        responseReceived = false;

        if (instructionText != null)
            instructionText.gameObject.SetActive(false);

        if (responsePanel != null)
            responsePanel.SetActive(true);

        while (!responseReceived)
        {
            if (Keyboard.current != null)
            {
                if (
                    Keyboard.current.bKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("butterfly");
                }

                if (
                    Keyboard.current.mKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("moon");
                }

                if (
                    Keyboard.current.cKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("car");
                }

                if (
                    Keyboard.current.dKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("duck");
                }

                if (
                    Keyboard.current.fKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("flower");
                }

                if (
                    Keyboard.current.hKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("heart");
                }

                if (
                    Keyboard.current.oKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("house");
                }

                if (
                    Keyboard.current.rKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("rabbit");
                }

                if (
                    Keyboard.current.tKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("tree");
                }

                if (
                    Keyboard.current.kKey.wasPressedThisFrame
                )
                {
                    OnSymbolSelected("rocket");
                }
            }

            yield return null;
        }

        if (gazeRecorder != null)
            gazeRecorder.SetPhase("response_received");

        string unityResponseWallClock =
            DateTime.Now.ToString(
                "yyyy-MM-dd HH:mm:ss.fff"
            );

        float rt =
            responseTime - trialStartTime;

        bool correct =
            string.Equals(
                response,
                currentTargetSymbol,
                StringComparison.OrdinalIgnoreCase
            );

        string accuracy =
            correct ? "CORRECT" : "INCORRECT";

        Debug.Log(
            $"Trial {trialId} complete. " +
            $"Target: {currentTargetSymbol}, " +
            $"Response: {response}, " +
            $"{accuracy}, RT: {rt:F3}"
        );

        if (tcpServer != null)
        {
            tcpServer.SendMessageToClient(
                $"TRIAL_COMPLETE," +
                $"{trialId}," +
                $"{response}," +
                $"{accuracy}," +
                $"{rt:F6}," +
                $"{trialStartTime:F6}," +
                $"{responseTime:F6}," +
                $"{unityStartWallClock}," +
                $"{unityResponseWallClock}"
            );
        }

        trialRunning = false;

        if (gazeRecorder != null)
            gazeRecorder.ClearTrialContext();

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "Preparing the next trial...";
        }
    }

    public void OnSymbolSelected(
        string selectedSymbol
    )
    {
        response = selectedSymbol;

        responseTime =
            Time.realtimeSinceStartup;

        if (responsePanel != null)
            responsePanel.SetActive(false);

        responseReceived = true;

        Debug.Log(
            $"Participant selected: {selectedSymbol}"
        );
    }

    private void HideStimuli()
    {
        if (stimulusCube != null)
            stimulusCube.SetActive(false);

        if (leftStimulusImage != null)
            leftStimulusImage.gameObject.SetActive(false);

        if (rightStimulusImage != null)
            rightStimulusImage.gameObject.SetActive(false);
    }

    private Texture2D LoadTextureFromFile(
        string path
    )
    {
        if (!File.Exists(path))
        {
            Debug.LogError(
                $"Stimulus file not found: {path}"
            );

            return null;
        }

        byte[] fileData =
            File.ReadAllBytes(path);

        Texture2D tex =
            new Texture2D(2, 2);

        bool loaded =
            tex.LoadImage(fileData);

        return loaded ? tex : null;
    }

    public void EndExperiment()
    {
        Debug.Log("Experiment complete.");

        trialRunning = false;
        responseReceived = false;

        HideStimuli();

        if (responsePanel != null)
            responsePanel.SetActive(false);

        if (gazeRecorder != null)
        {
            gazeRecorder.SetPhase(
                "experiment_complete"
            );

            gazeRecorder.StopRecording();
        }

        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            instructionText.text =
                "Test Complete\n\n" +
                "Thank you for participating.";
        }
    }
}