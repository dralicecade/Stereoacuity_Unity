% run_quest_lsl.m
%
% MATLAB controller for the stereoacuity experiment.
%
% Implements a QUEST adaptive staircase that communicates with the
% Unity stimulus display over Lab Streaming Layer (LSL):
%
%   Unity outlet  "UnityTrialResults"   (2 ch): [log10_disparity, correct]
%   MATLAB outlet "MATLABQuestDecisions"(1 ch): [log10_disparity_next]
%
% Prerequisites
% ─────────────
%  1. Download the MATLAB LSL toolbox from
%       https://github.com/labstreaminglayer/liblsl-Matlab
%     and add it to your MATLAB path, e.g.:
%       addpath(genpath('path/to/liblsl-Matlab'))
%
%  2. The Psychophysics Toolbox (PTB-3) provides QuestCreate / QuestUpdate.
%     If PTB is not available, a minimal QUEST implementation is included at
%     the bottom of this file and used automatically.
%
%  3. Start Unity and load the StereoacuityScene before running this script.

% =========================================================================
% Configuration
% =========================================================================

cfg.numTrials        = 50;      % Total number of adaptive trials
cfg.tGuess           = log10(60);  % Initial QUEST guess: 60 arcsec (log10)
cfg.tGuessSd         = 2.0;        % SD of initial guess (log10 arcsec)
cfg.pThreshold       = 0.75;       % Target proportion correct at threshold
cfg.beta             = 3.5;        % Psychometric function slope
cfg.delta            = 0.01;       % Lapse rate
cfg.gamma            = 0.25;       % Chance level (4AFC → 0.25)
cfg.streamSearchSec  = 30;         % Max seconds to wait for Unity stream

cfg.outletName = 'MATLABQuestDecisions';
cfg.inletName  = 'UnityTrialResults';

% =========================================================================
% Initialise LSL
% =========================================================================

fprintf('Loading LSL library…\n');
lib = lsl_loadlib();

% Create MATLAB → Unity outlet
outletInfo = lsl_streaminfo(lib, cfg.outletName, 'Markers', 1, 0, ...
                            'cf_float32', 'matlab_quest_controller');
outlet = lsl_outlet(outletInfo);
fprintf('LSL outlet "%s" created.\n', cfg.outletName);

% Find Unity → MATLAB inlet
fprintf('Searching for Unity stream "%s" (timeout: %d s)…\n', ...
        cfg.inletName, cfg.streamSearchSec);
results = {};
tSearch = tic;
while isempty(results)
    results = lsl_resolve_byprop(lib, 'name', cfg.inletName, 1, 2.0);
    if isempty(results) && toc(tSearch) > cfg.streamSearchSec
        error('Could not find Unity stream "%s" within %d seconds. ' ...
              'Make sure Unity is running.', cfg.inletName, cfg.streamSearchSec);
    end
end
inlet = lsl_inlet(results{1});
fprintf('Connected to Unity stream "%s".\n', cfg.inletName);

% =========================================================================
% Initialise QUEST
% =========================================================================

useQuestPTB = exist('QuestCreate', 'file') == 2;
if useQuestPTB
    q = QuestCreate(cfg.tGuess, cfg.tGuessSd, cfg.pThreshold, ...
                    cfg.beta, cfg.delta, cfg.gamma);
    q.normalizePdf = true;
    fprintf('Using Psychtoolbox QuestCreate.\n');
else
    q = quest_create(cfg.tGuess, cfg.tGuessSd, cfg.pThreshold, ...
                     cfg.beta, cfg.delta, cfg.gamma);
    fprintf('Using built-in QUEST implementation.\n');
end

% =========================================================================
% Trial loop
% =========================================================================

results_log = zeros(cfg.numTrials, 3);  % [trial, log10_disp, correct]

fprintf('\n%-8s %-14s %-10s %-14s\n', 'Trial', 'Disp(arcsec)', 'Correct', 'Est.thresh');
fprintf('%s\n', repmat('-', 1, 50));

for trial = 1:cfg.numTrials

    % ── Get QUEST recommendation ──────────────────────────────────────────
    if useQuestPTB
        tTest = QuestQuantile(q);
    else
        tTest = quest_quantile(q);
    end
    % Clamp to a sensible physiological range: 1–3000 arcsec (log10: 0–3.48)
    tTest = max(0.0, min(3.48, tTest));

    % ── Send disparity to Unity ───────────────────────────────────────────
    outlet.push_sample(tTest);
    dispArcSec = 10^tTest;
    fprintf('%-8d %-14.2f', trial, dispArcSec);

    % ── Wait for response from Unity ──────────────────────────────────────
    sample = [];
    ts     = 0;
    tWait  = tic;
    while ts == 0
        [sample, ts] = inlet.pull_sample(0.5);
        if toc(tWait) > 10
            warning('Trial %d: No response received from Unity after 10 s.', trial);
            break;
        end
    end

    if isempty(sample)
        correct = 0;
        tLog    = tTest;
    else
        tLog    = sample(1);   % log10 disparity echoed by Unity
        correct = sample(2);   % 1 = correct, 0 = incorrect
    end

    % ── Update QUEST ──────────────────────────────────────────────────────
    if useQuestPTB
        q = QuestUpdate(q, tLog, correct);
        threshEst = 10^QuestMean(q);
    else
        q = quest_update(q, tLog, correct);
        threshEst = 10^quest_mean(q);
    end

    results_log(trial, :) = [trial, tLog, correct];
    fprintf(' %-10d %-14.2f\n', correct, threshEst);
end

% =========================================================================
% Report final threshold
% =========================================================================

if useQuestPTB
    finalThresh = 10^QuestMean(q);
    finalSD     = 10^QuestSd(q);
else
    finalThresh = 10^quest_mean(q);
    finalSD     = 10^quest_sd(q);
end

fprintf('\n%s\n', repmat('=', 1, 50));
fprintf('Final stereoacuity threshold : %.2f arcsec\n', finalThresh);
fprintf('SD of threshold estimate     : %.2f arcsec\n', finalSD);
fprintf('%s\n', repmat('=', 1, 50));

% =========================================================================
% Plot psychometric data
% =========================================================================

figure('Name', 'QUEST Threshold Estimation');
subplot(1,2,1);
plot(results_log(:,1), 10.^results_log(:,2), 'o-', 'LineWidth', 1.5);
yline(finalThresh, '--r', sprintf('%.1f arcsec', finalThresh));
xlabel('Trial number');
ylabel('Disparity tested (arcsec)');
title('Disparity sequence');
set(gca, 'YScale', 'log');
grid on;

subplot(1,2,2);
if useQuestPTB
    x = q.x + q.tGuess;
else
    x = q.x;
end
pdf = q.pdf ./ sum(q.pdf);
plot(10.^x, pdf, 'LineWidth', 2);
xlabel('Disparity threshold (arcsec)');
ylabel('Probability');
title('QUEST posterior PDF');
set(gca, 'XScale', 'log');
grid on;

% =========================================================================
% Clean up
% =========================================================================

clear outlet inlet;
fprintf('\nLSL streams closed.\n');

% =========================================================================
% Built-in minimal QUEST implementation
% (used only if Psychtoolbox QuestCreate is not available)
% =========================================================================

function q = quest_create(tGuess, tGuessSd, pThreshold, beta, delta, gamma)
% Initialise a QUEST structure using a Gaussian prior and a Weibull
% psychometric function.  Mirrors the Psychtoolbox QuestCreate API.
q.tGuess     = tGuess;
q.tGuessSd   = tGuessSd;
q.pThreshold = pThreshold;
q.beta       = beta;
q.delta      = delta;
q.gamma      = gamma;

% Build x-axis in log units (±5 SD around the guess)
q.grain = 0.01;
q.xMin  = tGuess - 5*tGuessSd;
q.xMax  = tGuess + 5*tGuessSd;
q.x     = (q.xMin : q.grain : q.xMax)';

% Gaussian prior
q.pdf   = normpdf(q.x, tGuess, tGuessSd);
q.pdf   = q.pdf ./ sum(q.pdf);
end

function q = quest_update(q, tTest, response)
% Update posterior given tTest (log10 disparity shown) and response (0/1).
% Likelihood: Weibull psychometric function evaluated at (tTest - x) for each
% candidate threshold x in q.x.
xRel       = tTest - q.x;   % stimulus relative to each candidate threshold
pCorrect   = q.delta*q.gamma + (1-q.delta).*(1 - (1-q.gamma).*exp(-10.^(q.beta.*xRel)));
if response
    likelihood = pCorrect;
else
    likelihood = 1 - pCorrect;
end
q.pdf = q.pdf .* likelihood;
q.pdf = q.pdf ./ sum(q.pdf);   % normalise
end

function t = quest_quantile(q)
% Return the stimulus level corresponding to the median of the posterior.
cdf = cumsum(q.pdf);
idx = find(cdf >= 0.5, 1, 'first');
if isempty(idx), idx = round(numel(q.x)/2); end
t   = q.x(idx);
end

function mu = quest_mean(q)
% Expected value of the posterior distribution.
mu = sum(q.x .* q.pdf);
end

function sd = quest_sd(q)
% Standard deviation of the posterior distribution.
mu = quest_mean(q);
sd = sqrt(sum((q.x - mu).^2 .* q.pdf));
end
