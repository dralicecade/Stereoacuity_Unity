clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

screenid = 2;   % your second monitor / PICO mirror

% Basic stimulus settings
WhichSymbol = 2;      % TAO
ThisSymbol  = 1;      % Butterfly
carrierType = 1;      % Disk
usePregen   = 1;
imSize      = 2048;
OffXpixel   = 16;     % test disparity

% Generate stereo stimulus
ThisStim = MakeStereoStimulus(imSize, 2*OffXpixel, WhichSymbol-1, ThisSymbol, carrierType, usePregen);

% Extract left/right planes from the existing red/green packed image
rightImage = ThisStim(:,:,1);
leftImage  = ThisStim(:,:,2);

% Make side-by-side image
sbsImage = [leftImage rightImage];

% Open screen and show it
[w, rect] = Screen('OpenWindow', screenid, 128);
tex = Screen('MakeTexture', w, uint8(sbsImage));

Screen('DrawTexture', w, tex, [], rect);
Screen('Flip', w);

KbWait;
Screen('CloseAll');