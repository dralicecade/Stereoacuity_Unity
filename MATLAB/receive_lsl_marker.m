% receive_lsl_marker.m
% Minimal Unity -> MATLAB LSL marker receiver

clear; clc;

lslPath = fullfile(pwd, 'liblsl-Matlab');
addpath(genpath(lslPath));

disp('Loading LSL library...');
lib = lsl_loadlib();

disp('Looking for Unity_to_MATLAB LSL stream...');
result = lsl_resolve_byprop(lib, 'name', 'Unity_to_MATLAB');

disp('Connected to Unity stream.');
inlet = lsl_inlet(result{1});

disp('Waiting for Unity response...');

[sample, timestamp] = inlet.pull_sample();

disp('Received message:');
disp(sample{1});

pause(1);

clear inlet
clear result
clear lib

disp('Receiver closed cleanly.');