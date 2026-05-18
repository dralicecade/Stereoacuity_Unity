clear;
clc;

disp("MATLAB current folder:");
disp(pwd);

participantId = input("Enter participant ID: ", "s");

if strlength(strtrim(participantId)) == 0
    error("Participant ID cannot be empty.");
end

participantId = string(strtrim(participantId));

host = "127.0.0.1";
port = 5005;

trialValues = [40, -40, 20, -20, 0];
trialSymbols = ["butterfly", "heart", "house", "duck", "car"];

results = table();

disp("Connecting to Unity TCP server...");

try
    t = tcpclient(host, port);
    pause(0.5);

    disp("Connected.");

    for i = 1:numel(trialValues)

        trialId = i;
        value = trialValues(i);
        targetSymbol = trialSymbols(i);

        msg = sprintf("TRIAL_START,%d,%g,%s", trialId, value, targetSymbol);

        disp(" ");
        disp("Sending message:");
        disp(msg);

        matlabSendTime = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss.SSS");

        write(t, uint8([char(msg) newline]));

        timeout = 10;
        tic;

        trialCompleteReceived = false;

        response = "";
        rtSeconds = NaN;
        unityStartTime = NaN;
        unityResponseTime = NaN;
        unityStartWallClock = "";
        unityResponseWallClock = "";
        matlabReceiveTime = NaT;
        matlabReceiveTime.Format = "yyyy-MM-dd HH:mm:ss.SSS";

        accuracy = "";

        while toc < timeout

            if t.NumBytesAvailable > 0

                data = read(t, t.NumBytesAvailable, "uint8");
                newResponse = string(strtrim(char(data)));

                disp("Received response:");
                disp(newResponse);

                lines = splitlines(newResponse);

                for j = 1:numel(lines)

                    line = strtrim(lines(j));

                    if startsWith(line, sprintf("TRIAL_COMPLETE,%d", trialId))

                        parts = split(line, ",");

                        response = parts(3);
                        accuracy = parts(4);
                        rtSeconds = str2double(parts(5));
                        unityStartTime = str2double(parts(6));
                        unityResponseTime = str2double(parts(7));
                        
                        if numel(parts) >= 9
                            unityStartWallClock = parts(8);
                            unityResponseWallClock = parts(9);
                        else
                            unityStartWallClock = "";
                            unityResponseWallClock = "";
                            warning("Unity wall-clock fields were not received for trial %d.", trialId);
                        end

                        matlabReceiveTime = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss.SSS");

                        trialCompleteReceived = true;
                        break;
                    end
                end
            end

            if trialCompleteReceived
                break;
            end

            pause(0.01);
        end

        if ~trialCompleteReceived
            warning("No TRIAL_COMPLETE response received for trial %d.", trialId);
            response = "TIMEOUT";
            matlabReceiveTime = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss.SSS");
        end

        newRow = table( ...
            participantId, ...
            trialId, ...
            value, ...
            string(response), ...
            string(accuracy), ...
            rtSeconds, ...
            unityStartTime, ...
            unityResponseTime, ...
            string(unityStartWallClock), ...
            string(unityResponseWallClock), ...
            matlabSendTime, ...
            matlabReceiveTime, ...
            'VariableNames', { ...
                'participantId', ...
                'trialId', ...
                'value', ...
                'response', ...
                'accuracy', ...
                'rtSeconds', ...
                'unityStartTime', ...
                'unityResponseTime', ...
                'unityStartWallClock', ...
                'unityResponseWallClock', ...
                'matlabSendTime', ...
                'matlabReceiveTime' ...
            } ...
        );

        results = [results; newRow];

        fprintf("Trial %d complete: %s, RT = %.3f s\n", ...
            trialId, response, rtSeconds);

        pause(0.5);
    end

    outputFolder = "C:\Users\alice.cade\Documents\Stereoacuity_Unity\Participant_Data";

    if ~exist(outputFolder, "dir")
        mkdir(outputFolder);
    end

    timestamp = datestr(now, "yyyymmdd_HHMMSS");
    safeParticipantId = regexprep(participantId, '[^\w\-]', '_');

    filename = "participant_" + safeParticipantId + ...
        "_tcp_trial_results_" + string(timestamp) + ".csv";

    fullOutputPath = fullfile(outputFolder, filename);

    writetable(results, fullOutputPath);

    disp(" ");
    disp("All trials finished.");
    disp("Saved results to:");
    disp(fullOutputPath);

    clear t;

catch ME
    disp("TCP ERROR:");
    disp(ME.message);
end