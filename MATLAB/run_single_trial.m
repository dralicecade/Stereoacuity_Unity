clear; clc;

lslPath = fullfile(pwd, 'liblsl-Matlab');
addpath(genpath(lslPath));

lib = lsl_loadlib();

% MATLAB -> Unity outlet
info = lsl_streaminfo(lib, ...
    'MATLAB_to_Unity', ...
    'Markers', ...
    1, ...
    0, ...
    'cf_string', ...
    'matlab_unity_trial_stream');

outlet = lsl_outlet(info);

% Unity -> MATLAB inlet
disp('Looking for Unity_to_MATLAB stream...');
result = lsl_resolve_byprop(lib, 'name', 'Unity_to_MATLAB');
inlet = lsl_inlet(result{1});

disp('Connected. Sending trial...');
pause(5);

disp('Sending trial...');
trialID = 1;
disparity = 40;

marker = sprintf('TRIAL_START,%d,%d', trialID, disparity);
outlet.push_sample({marker});
disp(['Sent: ', marker]);

disp('Waiting for Unity response...');

responseReceived = false;
tic;

while toc < 30
    [sample, timestamp] = inlet.pull_sample(0.1);

    if ~isempty(sample)
        disp('Received response:');
        disp(sample{1});
        responseReceived = true;
        break;
    end
end

if ~responseReceived
    warning('No response received within timeout.');
end

pause(1);

disp('Single trial complete.');