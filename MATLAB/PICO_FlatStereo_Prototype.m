clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

screenid = 2;
participant = input('Participant ID: ','s');

L = uint8(imread('PassedImageL.tiff'));
R = uint8(imread('PassedImageR.tiff'));

sbs = [L R];

[w, rect] = Screen('OpenWindow', screenid, 128);
Screen('TextSize', w, 40);

tex = Screen('MakeTexture', w, sbs);

Screen('DrawTexture', w, tex, [], rect);
DrawFormattedText(w, ...
    'Which shape do you see?\n\nPress any key to respond', ...
    'center', 40, 255);
Screen('Flip', w);

startTime = GetSecs;
[~, keyTime, keyCode] = KbWait;
responseKey = KbName(find(keyCode,1));
rt = keyTime - startTime;

Screen('CloseAll');

results = table({participant}, {responseKey}, rt, ...
    'VariableNames', {'Participant','Response','RT'});

writetable(results, 'PICO_FlatStereo_TestResults.csv');

disp(results);