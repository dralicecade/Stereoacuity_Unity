clear; clc;

lslPath = fullfile(pwd, 'liblsl-Matlab');
addpath(genpath(lslPath));

lib = lsl_loadlib();

info = lsl_streaminfo(lib, ...
    'MATLAB_to_Unity', ...
    'Markers', ...
    1, ...
    0, ...
    'cf_string', ...
    'matlab_unity_trial_stream');

outlet = lsl_outlet(info);

disp('Looking for Unity_to_MATLAB stream...');
result = lsl_resolve_byprop(lib, 'name', 'Unity_to_MATLAB');
inlet = lsl_inlet(result{1});

disp('Connected. Waiting 5 seconds for Unity receiver...');
pause(5);

disparities = [80 60 40 30 20];
results = table();

for trialID = 1:numel(disparities)

    disparity = disparities(trialID);
    marker = sprintf('TRIAL_START,%d,%d', trialID, disparity);

    disp(['Sending: ', marker]);
    outlet.push_sample({marker});

    responseReceived = false;
    tic;

    while toc < 30
        [sample, timestamp] = inlet.pull_sample(0.1);

        if ~isempty(sample)
            msg = sample{1};
            disp(['Received: ', msg]);

            parts = split(msg, ',');

            if numel(parts) >= 4 && parts(1) == "RESPONSE"
                results = [results; table( ...
                    str2double(parts(2)), ...
                    disparity, ...
                    string(parts(3)), ...
                    str2double(parts(4)), ...
                    timestamp, ...
                    'VariableNames', {'trial_id','disparity_arcsec','response','rt_seconds','lsl_timestamp'})];

                responseReceived = true;
                break;
            end
        end
    end

    if ~responseReceived
        warning('No response received for trial %d.', trialID);
    end

    pause(1);
end

disp(results);

save('trial_loop_results.mat', 'results');

disp('Trial loop complete. Results saved.');
disp('Leave MATLAB open for now; do not clear LSL objects manually.');