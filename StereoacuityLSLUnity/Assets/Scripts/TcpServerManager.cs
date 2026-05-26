using System;
using System.Collections.Concurrent;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using UnityEngine;
using UnityEngine.Events;

public class TcpServerManager : MonoBehaviour
{
    [Header("TCP Settings")]
    public int port = 5005;

    [Header("Experiment Manager")]
    public ExperimentManager experimentManager;

    private TcpListener listener;
    private TcpClient client;
    private NetworkStream stream;
    private Thread listenerThread;
    private volatile bool running = false;

    private readonly ConcurrentQueue<string> messageQueue = new ConcurrentQueue<string>();

    [System.Serializable]
    public class ExperimentEndEvent : UnityEvent { }



    [Header("Events")]
    public ExperimentEndEvent OnExperimentEnd;


    private void Start()
    {
        StartServer();
    }

    private void OnApplicationQuit()
    {
        StopServer();
    }

    public void StartServer()
    {
        if (running)
            return;

        running = true;

        listenerThread = new Thread(ListenForClient);
        listenerThread.IsBackground = true;
        listenerThread.Start();

        Debug.Log($"TCP Server started on port {port}");
    }

    private void ListenForClient()
    {
        try
        {
            listener = new TcpListener(IPAddress.Any, port);
            listener.Start();

            Debug.Log("TCP Server listening...");

            while (running)
            {
                client = listener.AcceptTcpClient();
                stream = client.GetStream();

                Debug.Log("MATLAB connected to Unity TCP server.");

                byte[] buffer = new byte[4096];

                while (running && client.Connected)
                {
                    if (stream.DataAvailable)
                    {
                        int bytesRead = stream.Read(buffer, 0, buffer.Length);

                        if (bytesRead > 0)
                        {
                            string message = Encoding.UTF8.GetString(buffer, 0, bytesRead).Trim();
                            Debug.Log("Received TCP message: " + message);
                            messageQueue.Enqueue(message);
                        }
                    }

                    Thread.Sleep(5);
                }
            }
        }
        catch (Exception e)
        {
            if (running)
                Debug.LogError("TCP Server error: " + e.Message);
        }
    }

    private void Update()
    {
        while (messageQueue.TryDequeue(out string message))
        {
            HandleMessage(message);
        }
    }

    private void HandleMessage(string message)
    {
        if (message == "EXPERIMENT_END")
        {
            Debug.Log("Experiment end message received.");
            OnExperimentEnd?.Invoke();
            SendMessageToClient("EXPERIMENT_END_RECEIVED,OK");
            return;
        }

        string[] parts = message.Split(',');

        if (parts.Length < 6)
        {
            Debug.LogError("Invalid TCP message: " + message);
            SendMessageToClient("ERROR,INVALID_MESSAGE");
            return;
        }

        string command = parts[0];
        string trialIdText = parts[1];
        string valueText = parts[2];
        string targetSymbol = parts[3];
        string leftImagePath = parts[4];
        string rightImagePath = parts[5];

        if (command != "TRIAL_START")
        {
            SendMessageToClient($"ERROR,{trialIdText},UNKNOWN_COMMAND");
            return;
        }

        if (!int.TryParse(trialIdText, out int trialId))
        {
            SendMessageToClient($"ERROR,{trialIdText},INVALID_TRIAL_ID");
            return;
        }

        if (!float.TryParse(valueText, out float value))
        {
            SendMessageToClient($"ERROR,{trialIdText},INVALID_VALUE");
            return;
        }

        Debug.Log(
            $"Triggering trial. Trial ID: {trialId}, " +
            $"Value: {value}, Symbol: {targetSymbol}, " +
            $"Left: {leftImagePath}, Right: {rightImagePath}"
        );

        if (experimentManager != null)
        {
            experimentManager.StartTrialFromTcp(
                trialId,
                value,
                targetSymbol,
                leftImagePath,
                rightImagePath
            );
        }
        else
        {
            Debug.LogError("ExperimentManager reference is missing on TcpServerManager.");
            SendMessageToClient($"ERROR,{trialId},NO_EXPERIMENT_MANAGER");
        }
    }

    public void SendMessageToClient(string message)
    {
        try
        {
            if (stream != null && stream.CanWrite)
            {
                byte[] data = Encoding.UTF8.GetBytes(message + "\n");
                stream.Write(data, 0, data.Length);
                stream.Flush();

                Debug.Log("Sent TCP message: " + message);
            }
        }
        catch (Exception e)
        {
            Debug.LogError("TCP send error: " + e.Message);
        }
    }

    private void StopServer()
    {
        running = false;

        try
        {
            stream?.Close();
            client?.Close();
            listener?.Stop();

            if (listenerThread != null && listenerThread.IsAlive)
                listenerThread.Join(500);
        }
        catch (Exception e)
        {
            Debug.LogError("TCP stop error: " + e.Message);
        }

        Debug.Log("TCP Server stopped.");
    }
}