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

        symbolSourceFolder =  "C:\Users\alice.cade\Documents\Stereoacuity_Unity\StereoacuityLSLUnity\Assets\Stimuli\TAO_Symbols\tiffs - reg";
        
        sourceImagePath = fullfile(symbolSourceFolder, targetSymbol + "_reg.tif");
        
        if ~exist(sourceImagePath, "file")
            error("Could not find symbol image: %s", sourceImagePath);
        end
        
        symbolImg = imread(sourceImagePath);
        
        if ndims(symbolImg) == 3
            symbolGray = rgb2gray(symbolImg);
        else
            symbolGray = symbolImg;
        end
        
        symbolGray = im2double(symbolGray);
        
        % Parameters
        canvasSize = 600;
        symbolSize = 280;
        disparityPx = 40;  % exaggerated for debugging
        
        symbolGray = imresize(symbolGray, [symbolSize symbolSize]);
        
        % Assumes dark symbol on light background
        symbolMask = symbolGray < 0.5;
        
        % Use the same noise carrier for both eyes
        baseNoise = rand(canvasSize, canvasSize);
        
        leftImg = baseNoise;
        rightImg = baseNoise;
        
        rowStart = round((canvasSize - symbolSize) / 2) + 1;
        centreColStart = round((canvasSize - symbolSize) / 2) + 1;
        
        leftColStart = centreColStart - round(disparityPx / 2);
        rightColStart = centreColStart + round(disparityPx / 2);
        
        rows = rowStart:(rowStart + symbolSize - 1);
        leftCols = leftColStart:(leftColStart + symbolSize - 1);
        rightCols = rightColStart:(rightColStart + symbolSize - 1);
        
        symbolContrast = 0.35;
        
        leftPatch = leftImg(rows, leftCols);
        leftPatch(symbolMask) = leftPatch(symbolMask) * symbolContrast;
        leftImg(rows, leftCols) = leftPatch;
        
        rightPatch = rightImg(rows, rightCols);
        rightPatch(symbolMask) = rightPatch(symbolMask) * symbolContrast;
        rightImg(rows, rightCols) = rightPatch;
        
        leftRGB = uint8(255 * repmat(leftImg, 1, 1, 3));
        rightRGB = uint8(255 * repmat(rightImg, 1, 1, 3));
        
        leftFilename = sprintf("trial_%03d_%s_LEFT.png", trialId, targetSymbol);
        rightFilename = sprintf("trial_%03d_%s_RIGHT.png", trialId, targetSymbol);
        
        leftStimulusPath = fullfile(stimulusFolder, leftFilename);
        rightStimulusPath = fullfile(stimulusFolder, rightFilename);
        
        imwrite(leftRGB, leftStimulusPath);
        imwrite(rightRGB, rightStimulusPath);
        
        % For now, keep sending the left image to Unity so the existing pipeline still works.
        stimulusPath = leftStimulusPath;

        msg = sprintf("TRIAL_START,%d,%g,%s,%s", trialId, value, targetSymbol, stimulusPath);

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

        pause(0.1);
    end

    disp(" ");
    disp("Sending experiment end message...");
    
    write(t, uint8(['EXPERIMENT_END' newline]));
    
    pause(0.2);

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