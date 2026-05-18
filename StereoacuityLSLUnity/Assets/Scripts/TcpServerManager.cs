using System;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using UnityEngine;
using System.Collections.Concurrent;
using UnityEngine.Events;

public class TcpServerManager : MonoBehaviour
{
    [Header("TCP Settings")]
    public int port = 5005;

    private TcpListener listener;
    private TcpClient client;
    private NetworkStream stream;
    private Thread listenerThread;
    private volatile bool running = false;

    private ConcurrentQueue<string> messageQueue = new ConcurrentQueue<string>();

    [System.Serializable]
    public class TrialStartEvent : UnityEvent<int, float, string> { }

    [Header("Events")]
    public TrialStartEvent OnTrialStart;

    void Start()
    {
        StartServer();
    }

    void OnApplicationQuit()
    {
        StopServer();
    }

    public void StartServer()
    {
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

                byte[] buffer = new byte[1024];

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
            Debug.LogError("TCP Server error: " + e.Message);
        }
    }

    private void HandleMessage(string message)
    {
        // Expected format:
        // TRIAL_START,1,40

        string[] parts = message.Split(',');

        if (parts.Length < 4)
        {
            SendMessageToClient("ERROR,INVALID_MESSAGE");
            return;
        }

        string command = parts[0];
        string trialId = parts[1];
        string value = parts[2];
        string targetSymbol = parts[3];

        if (command == "TRIAL_START")
        {
            if (!int.TryParse(trialId, out int parsedTrialId))
            {
                SendMessageToClient($"ERROR,{trialId},INVALID_TRIAL_ID");
                return;
            }

            if (!float.TryParse(value, out float parsedValue))
            {
                SendMessageToClient($"ERROR,{trialId},INVALID_VALUE");
                return;
            }

            Debug.Log($"Triggering trial. Trial ID: {parsedTrialId}, Value: {parsedValue}, Symbol: {targetSymbol}");

            OnTrialStart?.Invoke(parsedTrialId, parsedValue, targetSymbol);

            SendMessageToClient($"TRIAL_STARTED,{parsedTrialId},OK");
        }
        else
        {
            SendMessageToClient($"ERROR,{trialId},UNKNOWN_COMMAND");
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
                {
                    listenerThread.Join(500);
                }
        }
        catch (Exception e)
            {
                if (running)
                Debug.LogError("TCP Server error: " + e.Message);
            }

        Debug.Log("TCP Server stopped.");
    }

    void Update()
    {
        while (messageQueue.TryDequeue(out string message))
        {
            HandleMessage(message);
        }
    }
}