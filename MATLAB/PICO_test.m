AssertOpenGL;

Screen('Preference','SkipSyncTests',1);

screens = Screen('Screens')

screenid = max(screens);

[w, rect] = Screen('OpenWindow', screenid, 128);

Screen('TextSize', w, 40); 

DrawFormattedText(w, ...
    'PICO TEST\n\nPress any key', ...
    'center', 'center', 255);

Screen('Flip', w);

KbWait;

Screen('CloseAll');