clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

screens = Screen('Screens');
screenid = max(screens);

% Load the uploaded left/right test images
leftIm  = imread('PassedImageL.tiff');
rightIm = imread('PassedImageR.tiff');

[w, rect] = Screen('OpenWindow', screenid, 128);
Screen('TextSize', w, 32);

[screenX, screenY] = RectSize(rect);

% Resize for simple side-by-side presentation
imgSize = round(screenY * 0.8);
leftIm  = imresize(leftIm,  [imgSize imgSize]);
rightIm = imresize(rightIm, [imgSize imgSize]);
 
leftTex  = Screen('MakeTexture', w, leftIm);
rightTex = Screen('MakeTexture', w, rightIm);

leftRect  = CenterRectOnPoint([0 0 imgSize imgSize], screenX*0.25, screenY*0.5);
rightRect = CenterRectOnPoint([0 0 imgSize imgSize], screenX*0.75, screenY*0.5);

Screen('DrawTexture', w, leftTex, [], leftRect);
Screen('DrawTexture', w, rightTex, [], rightRect);

DrawFormattedText(w, 'Left/right stereo image test\nPress any key to close', ...
    'center', 40, 255);

Screen('Flip', w);
KbWait;

Screen('CloseAll');