clear; clc;
AssertOpenGL;
Screen('Preference','SkipSyncTests',1);

try
    hmd = PsychVRHMD('AutoSetupHMD', ...
        'Stereoscopic', ...
        'DebugDisplay NoTimingSupport NoTimestampingSupport', ...
        0.2);

    if isempty(hmd)
        error('No HMD detected by PsychVRHMD.');
    end

    info = PsychVRHMD('GetInfo', hmd)

    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseVirtualReality', hmd);

    screenid = max(Screen('Screens'));
    [win, rect] = PsychImaging('OpenWindow', screenid, 128);

    L = uint8(imread('PassedImageL.tiff'));
    R = uint8(imread('PassedImageR.tiff'));

    texL = Screen('MakeTexture', win, L);
    texR = Screen('MakeTexture', win, R);

    % Left eye buffer
    Screen('SelectStereoDrawBuffer', win, 0);
    Screen('FillRect', win, 128);