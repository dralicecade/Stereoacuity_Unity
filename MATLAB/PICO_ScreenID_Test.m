clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

screens = Screen('Screens')

for screenid = screens
    fprintf('\nTesting screen %d\n', screenid);
    [w, rect] = Screen('OpenWindow', screenid, 128);
    Screen('TextSize', w, 50);
    DrawFormattedText(w, sprintf('SCREEN %d\n\nPress any key', screenid), ...
        'center', 'center', 255);
    Screen('Flip', w);
    KbWait;
    Screen('CloseAll');
    WaitSecs(1);
end    