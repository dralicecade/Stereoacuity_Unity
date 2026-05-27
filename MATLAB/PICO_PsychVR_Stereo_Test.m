clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

try
    hmd = PsychVRHMD('AutoSetupHMD', 'Stereoscopic', ...
        'DebugDisplay NoTimingSupport NoTimestampingSupport', 0.1);

    if isempty(hmd)
        error('No HMD detected by PsychVRHMD.');
    end

    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseVRHMD', hmd);

    screenid = max(Screen('Screens'));
    [win, winRect] = PsychImaging('OpenWindow', screenid, 128);

    L = uint8(imread('PassedImageL.tiff'));
    R = uint8(imread('PassedImageR.tiff'));

    texL = Screen('MakeTexture', win, L);
    texR = Screen('MakeTexture', win, R);

    Screen('SelectStereoDrawBuffer', win, 0); % left eye
    Screen('FillRect', win, 128);
    Screen('DrawTexture', win, texL, [], CenterRectOnPoint([0 0 800 800], winRect(3)/2, winRect(4)/2));

    Screen('SelectStereoDrawBuffer', win, 1); % right eye
    Screen('FillRect', win, 128);
    Screen('DrawTexture', win, texR, [], CenterRectOnPoint([0 0 800 800], winRect(3)/2, winRect(4)/2));

    Screen('Flip', win);

    KbWait;

    sca;
    PsychVRHMD('Close', hmd);

catch ME
    sca;
    PsychVRHMD('Close');
    rethrow(ME);
end