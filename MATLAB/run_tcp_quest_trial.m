clear;
clc;

participantId = input("Enter participant ID: ", "s");
participantId = string(strtrim(participantId));

thisFile = mfilename("fullpath");
matlabFolder = fileparts(thisFile);
repoRoot = fileparts(matlabFolder);
unityProjectRoot = fullfile(repoRoot, "StereoacuityLSLUnity");

stimulusFolder = fullfile(unityProjectRoot, "Assets", "Stimuli", "Generated");
outputFolder = fullfile(repoRoot, "Participant_Data");

if ~isfolder(stimulusFolder), mkdir(stimulusFolder); end
if ~isfolder(outputFolder), mkdir(outputFolder); end

addpath(genpath(matlabFolder));
addpath(genpath(repoRoot));

host = "127.0.0.1";
port = 5005;

symbolNames = ["butterfly","car","duck","flower","heart", ...
               "house","moon","rabbit","rocket","tree"];

nSymbols = numel(symbolNames);
nTrials = input("Number of QUEST trials? [20]: ");
if isempty(nTrials), nTrials = 20; end

%% QUEST settings
tGuess = input("Initial log threshold guess? [-1]: ");
if isempty(tGuess), tGuess = -1; end

tGuessSd = input("Guess SD? [2]: ");
if isempty(tGuessSd), tGuessSd = 2; end

pThreshold = 1/nSymbols + (1 - 1/nSymbols)/2;
beta = 3.5;
delta = 0.01;
gamma = 1/nSymbols;

q = QuestCreate(tGuess, tGuessSd, pThreshold, beta, delta, gamma);
q.normalizePdf = 1;

%% Stimulus settings from supervisor script
whichSymbolSet = 2;      % 2 = TAO in supervisor script
carrierType = 1;         % 1 = disks, 2 = noise
usePregen = 1;
imSize = 4096/2;

results = table();

disp("Connecting to Unity TCP server...");
t = tcpclient(host, port);
pause(0.5);
disp("Connected.");

for trialId = 1:nTrials

    targetIdx = randi(nSymbols);
    targetSymbol = symbolNames(targetIdx);

    tTest = QuestQuantile(q);
    stimOffsetPix = 8 * 10^tTest;

    % Supervisor script uses 2 * OffXpixel
    thisStim = MakeStereoStimulus( ...
        imSize, ...
        2 * stimOffsetPix, ...
        whichSymbolSet - 1, ...
        targetIdx, ...
        carrierType, ...
        usePregen);

    thisStim = (thisStim - 128) .* 127 ./ 250 + 128;
    thisStim = uint8(max(min(thisStim, 255), 0));

    leftImg = thisStim(:,:,1);
    rightImg = thisStim(:,:,2);

    leftPath = fullfile(stimulusFolder, ...
        sprintf("quest_%03d_%s_LEFT.png", trialId, targetSymbol));
    rightPath = fullfile(stimulusFolder, ...
        sprintf("quest_%03d_%s_RIGHT.png", trialId, targetSymbol));

    imwrite(leftImg, leftPath);
    imwrite(rightImg, rightPath);

    msg = sprintf("TRIAL_START,%d,%.6f,%s,%s,%s", ...
        trialId, stimOffsetPix, targetSymbol, leftPath, rightPath);

    fprintf("\nSending trial %d: target=%s, tTest=%.3f, offsetPix=%.3f\n", ...
        trialId, targetSymbol, tTest, stimOffsetPix);

    matlabSendTime = datetime("now", "Format", "yyyy-MM-dd HH:mm:ss.SSS");
    write(t, uint8([char(msg) newline]));

    timeout = 30;
    tic;
    trialCompleteReceived = false;

    response = "";
    accuracy = "";
    rtSeconds = NaN;

    while toc < timeout

        if t.NumBytesAvailable > 0
            data = read(t, t.NumBytesAvailable, "uint8");
            newResponse = string(strtrim(char(data)));
            disp(newResponse);

            lines = splitlines(newResponse);

            for j = 1:numel(lines)
                line = strtrim(lines(j));

                if startsWith(line, sprintf("TRIAL_COMPLETE,%d", trialId))
                    parts = split(line, ",");

                    response = parts(3);
                    accuracy = parts(4);
                    rtSeconds = str2double(parts(5));

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
        warning("No TRIAL_COMPLETE received for trial %d.", trialId);
        response = "TIMEOUT";
        accuracy = "TIMEOUT";
        correct = 0;
    else
        correct = strcmpi(accuracy, "CORRECT");
    end

    q = QuestUpdate(q, tTest, correct);

    newRow = table( ...
        participantId, ...
        trialId, ...
        targetSymbol, ...
        string(response), ...
        string(accuracy), ...
        correct, ...
        tTest, ...
        stimOffsetPix, ...
        rtSeconds, ...
        matlabSendTime, ...
        datetime("now", "Format", "yyyy-MM-dd HH:mm:ss.SSS"), ...
        'VariableNames', { ...
            'participantId', ...
            'trialId', ...
            'targetSymbol', ...
            'response', ...
            'accuracy', ...
            'correct', ...
            'questLogIntensity', ...
            'stimOffsetPix', ...
            'rtSeconds', ...
            'matlabSendTime', ...
            'matlabReceiveTime' ...
        });

    results = [results; newRow];

    fprintf("Trial %d: response=%s, %s, QUEST updated.\n", ...
        trialId, response, accuracy);
end

write(t, uint8(['EXPERIMENT_END' newline]));
pause(0.2);

thresholdLog = QuestMean(q);
thresholdOffsetPix = 8 * 10^thresholdLog;

timestamp = datestr(now, "yyyymmdd_HHMMSS");
safeParticipantId = regexprep(participantId, '[^\w\-]', '_');

csvPath = fullfile(outputFolder, ...
    "participant_" + safeParticipantId + "_QUEST_results_" + string(timestamp) + ".csv");

matPath = fullfile(outputFolder, ...
    "participant_" + safeParticipantId + "_QUEST_state_" + string(timestamp) + ".mat");

writetable(results, csvPath);
save(matPath, "q", "results", "thresholdLog", "thresholdOffsetPix");

disp(" ");
disp("QUEST complete.");
fprintf("Estimated threshold log intensity: %.4f\n", thresholdLog);
fprintf("Estimated threshold offset pixels: %.4f\n", thresholdOffsetPix);
disp("Saved:");
disp(csvPath);
disp(matPath);

clear t;