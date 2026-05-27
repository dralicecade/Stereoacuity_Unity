clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

screenid = 2;

L = uint8(imread('PassedImageL.tiff'));
R = uint8(imread('PassedImageR.tiff'));

sbs = [L R];

[w, rect] = Screen('OpenWindow', screenid, 128);
tex = Screen('MakeTexture', w, sbs);

Screen('DrawTexture', w, tex, [], rect);
Screen('Flip', w);   

KbWait;
Screen('CloseAll'); 