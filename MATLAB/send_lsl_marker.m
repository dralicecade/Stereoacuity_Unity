% send_lsl_marker.m
% Minimal MATLAB -> Unity LSL marker sender

clear; clc;

% Path to liblsl-Matlab folder
% Change this once you download/extract liblsl-Matlab
lslPath = fullfile(pwd, 'liblsl-Matlab');
addpath(genpath(lslPath));

disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Creating LSL outlet...');

info = lsl_streaminfo( ...
    lib, ...
    'MATLAB_to_Unity', ...   % stream name
    'Markers', ...           % stream type Unity is looking for
    1, ...                   % one channel
    0, ...                   % irregular sampling rate
    'cf_string', ...         % string markers
    'matlab_unity_test_001' ...
);

outlet = lsl_outlet(info);

disp('LSL outlet created.');
disp('Start Unity Play mode now if it is not already running.');
pause(2);

marker = 'TRIAL_START,1,40';

disp('Waiting 5 seconds for Unity to connect...');
pause(5);

for i = 1:5
    disp(['Sending marker: ', marker]);
    outlet.push_sample({marker});
    pause(1);
end

disp('Done.');