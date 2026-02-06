%% MonteCarlo_SnapshotResampling_CH4.m
% Site-specific snapshot (single-point) resampling
%
% Outputs:
%   - daySummary: per-day probabilities & stats
%   - pooledSummary: pooled-across-days probabilities & stats
%   - allDrawsTable: day-labelled Monte Carlo draws (optional export)

clear; clc;

%% USER SETTINGS
xlsxFile   = 'spring25_wellheadFluxes_continuous.xlsx';
sheetName  = 'All measurements';

N          = 500;     % Monte Carlo draws per day
misrepFac  = 2.0;     % "misrepresentation" factor threshold (e.g., 2 => under/over by >2x)

% "episodic event" definition
useEventMetric = true;
eventMode      = 'pctl';   % 'pctl' or 'absolute'
eventPctl       = 95;      % if mode = 'pctl'
eventAbsThresh  = 400;     % if mode = 'absolute'

% Data filters
removeNaNs     = true;
minPointsPerDay = 5;   % skip days with fewer points than this

% Random seed for reproducibility
rng(42);

%% READ DATA
opts = detectImportOptions(xlsxFile, 'Sheet', sheetName);

% Ensure the key vars are included
needVars = {'Start_Time','CH4_Flux'};
for k = 1:numel(needVars)
    if ~any(strcmp(opts.VariableNames, needVars{k}))
        error('Required variable "%s" not found in sheet "%s".', needVars{k}, sheetName);
    end
end

T = readtable(xlsxFile, opts, 'Sheet', sheetName);

% Coerce Start_Time to datetime if needed
if ~isdatetime(T.Start_Time)
    try
        T.Start_Time = datetime(T.Start_Time, 'InputFormat','yyyy-MM-dd HH:mm:ss');
    catch
        T.Start_Time = datetime(T.Start_Time);
    end
end

% Coerce CH4_Flux to numeric if needed
if ~isnumeric(T.CH4_Flux)
    T.CH4_Flux = str2double(string(T.CH4_Flux));
end

% Remove missing values
if removeNaNs
    T = T(~isnat(T.Start_Time) & ~isnan(T.CH4_Flux), :);
end

% Add a "Day" variable (start of day)
T.Day = dateshift(T.Start_Time, 'start', 'day');

%% GROUP BY DAY
days = unique(T.Day);
days = sort(days);

% Preallocate containers
allDraws = cell(numel(days),1);
dayStats = [];

%% MONTE CARLO PER DAY
for d = 1:numel(days)
    thisDay = days(d);
    idx = (T.Day == thisDay);
    x = T.CH4_Flux(idx);

    if numel(x) < minPointsPerDay
        continue; % skip sparse days
    end

    mu = mean(x, 'omitnan');  % "true" daily mean
    if mu == 0 || isnan(mu)
        continue;
    end

    % Event threshold
    if useEventMetric
        switch lower(eventMode)
            case 'pctl'
                thrEvent = prctile(x, eventPctl);
            case 'absolute'
                thrEvent = eventAbsThresh;
            otherwise
                error('Unknown eventMode: %s (use "pctl" or "absolute")', eventMode);
        end
    else
        thrEvent = NaN;
    end

    % Monte Carlo
    drawIdx = randi(numel(x), N, 1);
    xStar   = x(drawIdx);

    R = xStar ./ mu;          % snapshot-to-true ratio
    logR = log10(R);          % often plots better; keep both

    % Misrepresentation probabilities (per day)
    pUnder = mean(R < 1/misrepFac);
    pOver  = mean(R > misrepFac);
    pWithin = mean(R >= 1/misrepFac & R <= misrepFac);

    % Event detection / miss probability
    if useEventMetric
        pDetectEvent = mean(xStar >= thrEvent);
        pMissEvent   = 1 - pDetectEvent;
    else
        pDetectEvent = NaN;
        pMissEvent   = NaN;
    end

    % Summaries of ratios
    Rmed = median(R);
    R05  = prctile(R, 5);
    R95  = prctile(R, 95);

    % Store per-day draw table
    allDraws{d} = table( ...
        repmat(thisDay, N, 1), xStar, repmat(mu, N, 1), R, logR, ...
        'VariableNames', {'Day','SnapshotFlux','DailyMean','Ratio','Log10Ratio'} ...
    );

    % Store per-day stats
    dayStats = [dayStats; table( ...
        thisDay, numel(x), mu, min(x), max(x), ...
        pUnder, pWithin, pOver, ...
        Rmed, R05, R95, ...
        thrEvent, pDetectEvent, pMissEvent, ...
        'VariableNames', { ...
            'Day','nPoints','DailyMean','DailyMin','DailyMax', ...
            'P_UnderByFac','P_WithinFac','P_OverByFac', ...
            'Ratio_Median','Ratio_P05','Ratio_P95', ...
            'EventThreshold','P_DetectEvent','P_MissEvent' ...
        } ...
    )]; 
end

% Combine all draws
allDrawsTable = vertcat(allDraws{:});

%% POOLED SUMMARY (EQUAL-WEIGHT DAYS)
% To ensure each day contributes equally, compute pooled probs from day-level probs
% and compute pooled ratio stats by stacking equal N draws per day (already equal N).
validDays = unique(allDrawsTable.Day);
nDays = numel(validDays);

if nDays == 0
    error('No valid days processed. Check Start_Time parsing, CH4_Flux values, and minPointsPerDay.');
end

Rall = allDrawsTable.Ratio;

pooledSummary = table();
pooledSummary.nDays = nDays;
pooledSummary.NperDay = N;
pooledSummary.TotalDraws = height(allDrawsTable);

pooledSummary.P_UnderByFac = mean(Rall < 1/misrepFac);
pooledSummary.P_WithinFac  = mean(Rall >= 1/misrepFac & Rall <= misrepFac);
pooledSummary.P_OverByFac  = mean(Rall > misrepFac);

pooledSummary.Ratio_Median = median(Rall);
pooledSummary.Ratio_P05    = prctile(Rall, 5);
pooledSummary.Ratio_P95    = prctile(Rall, 95);

if useEventMetric
    % pooled "miss event" is best reported as mean of per-day miss probs (equal-weight)
    pooledSummary.P_MissEvent = mean(dayStats.P_MissEvent, 'omitnan');
else
    pooledSummary.P_MissEvent = NaN;
end

%% DISPLAY RESULTS
disp('--- Per-day summary (first 10 rows) ---');
disp(head(dayStats, 10));

disp('--- Pooled summary ---');
disp(pooledSummary);

%% QUICK PLOTS
% 1) Ratio distributions by day (boxplot of log10 ratio)
figure;
boxplot(allDrawsTable.Log10Ratio, allDrawsTable.Day);
yline(0,'--'); % log10(1)=0
ylabel('log_{10}( Snapshot / Daily mean )');
xlabel('Day');
title(sprintf('Single-point snapshot resampling (N=%d/day), misrep factor=%.2g', N, misrepFac));
grid on;

% 2) Misrepresentation probabilities by day
figure;
bar(dayStats.Day, [dayStats.P_UnderByFac, dayStats.P_WithinFac, dayStats.P_OverByFac], 'stacked');
ylabel('Probability');
xlabel('Day');
legend(sprintf('Under by >%.2gx', misrepFac), sprintf('Within %.2gx', misrepFac), sprintf('Over by >%.2gx', misrepFac), 'Location','best');
title('Per-day probability of mischaracterisation (single snapshot)');
grid on;

% 3) Miss-event probability by day (if enabled)
if useEventMetric
    figure;
    bar(dayStats.Day, dayStats.P_MissEvent);
    ylabel('P(miss episodic event)');
    xlabel('Day');
    title(sprintf('Event miss probability (event=%s)', eventMode));
    grid on;
end

%% EXPORT TABLES
writetable(dayStats, 'daySummary_CH4_snapshotMC.csv');
writetable(pooledSummary, 'pooledSummary_CH4_snapshotMC.csv');
writetable(allDrawsTable, 'allDraws_CH4_snapshotMC.csv');