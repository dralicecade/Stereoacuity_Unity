clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

try
    PsychOpenXR('Verbosity', 4);

    hmd = PsychOpenXR('Open');

    PsychOpenXR('SetupRenderingParameters', hmd, 'Stereoscopic', ...
        'DebugDisplay NoTimingSupport NoTimestampingSupport', 0.1);

    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseVRHMD', hmd);

    screenid = max(Screen('Screens'));

    [win, winRect] = PsychImaging('OpenWindow', screenid, 128);

    L = uint8(imread('PassedImageL.tiff'));
    R = uint8(imread('PassedImageR.tiff'));

    texL = Screen('MakeTexture', win, L);
    texR = Screen('MakeTexture', win, R);

    dst = CenterRectOnPoint([0 0 900 900], winRect(3)/2, winRect(4)/2);

    Screen('SelectStereoDrawBuffer', win, 0); % left eye
    Screen('FillRect', win, 128);
    Screen('DrawTexture', win, texL, [], dst);

    Screen('SelectStereoDrawBuffer', win, 1); % right eye
    Screen('FillRect', win, 128);
    Screen('DrawTexture', win, texR, [], dst);

    Screen('Flip', win);

    KbWait;

    sca;
    PsychOpenXR('Close', hmd);

catch ME
    sca;
    PsychOpenXR('Close');
    rethrow(ME);
end