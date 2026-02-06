%% MonteCarlo_SnapshotResampling_CH4_v2.m
% Expands the original script with:
% 1) Units-based pooled summary (median/IQR/5-95 of snapshot flux)
% 2) Contribution-based episodicity metric (top 5% time contribution)
% 3) Optional n-snapshots/day design curve (n=1,2,3,5)

clear; clc;

%% USER SETTINGS
xlsxFile   = 'spring25_wellheadFluxes_continuous.xlsx';
sheetName  = 'All measurements';

N          = 500;     % Monte Carlo draws per day (single snapshot)
misrepFac  = 2.0;     % factor threshold for under/over (existing)

% Units-based pooled summary uses draws directly
% Contribution-based episodicity settings
useContributionEpisodicity = true;
topTimeFrac = 0.05;          % "top ~5% of time" by contribution

% Monitoring design curve settings
doNSnapshotCurve = true;
nList = [1 2 3 5];            % number of snapshots/day to simulate
toleranceFrac = 0.50;         % ±50% of true mean => within [0.5, 1.5] * mu_d

% Data filters
removeNaNs       = true;
minPointsPerDay  = 5;

% Random seed
rng(42);

%% READ DATA
opts = detectImportOptions(xlsxFile, 'Sheet', sheetName);

needVars = {'Start_Time','CH4_Flux'};
for k = 1:numel(needVars)
    if ~any(strcmp(opts.VariableNames, needVars{k}))
        error('Required variable "%s" not found in sheet "%s".', needVars{k}, sheetName);
    end
end

T = readtable(xlsxFile, opts, 'Sheet', sheetName);

if ~isdatetime(T.Start_Time)
    try
        T.Start_Time = datetime(T.Start_Time, 'InputFormat','yyyy-MM-dd HH:mm:ss');
    catch
        T.Start_Time = datetime(T.Start_Time);
    end
end

if ~isnumeric(T.CH4_Flux)
    T.CH4_Flux = str2double(string(T.CH4_Flux));
end

if removeNaNs
    T = T(~isnat(T.Start_Time) & ~isnan(T.CH4_Flux), :);
end

T.Day = dateshift(T.Start_Time, 'start', 'day');

%% GROUP BY DAY
days = unique(T.Day);
days = sort(days);

allDraws = cell(numel(days),1);
dayStats = [];
contribStats = [];   % contribution episodicity per-day

%% MONTE CARLO PER DAY (SINGLE-SNAPSHOT)
for d = 1:numel(days)
    thisDay = days(d);
    idx = (T.Day == thisDay);
    x = T.CH4_Flux(idx);

    if numel(x) < minPointsPerDay
        continue;
    end

    mu = mean(x, 'omitnan');  % true daily mean
    if mu == 0 || isnan(mu)
        continue;
    end

    % ---- single snapshot MC ----
    drawIdx = randi(numel(x), N, 1);
    xStar   = x(drawIdx);

    R    = xStar ./ mu;
    logR = log10(R);

    pUnder  = mean(R < 1/misrepFac);
    pOver   = mean(R > misrepFac);
    pWithin = mean(R >= 1/misrepFac & R <= misrepFac);

    Rmed = median(R);
    R05  = prctile(R, 5);
    R95  = prctile(R, 95);

    allDraws{d} = table( ...
        repmat(thisDay, N, 1), xStar, repmat(mu, N, 1), R, logR, ...
        'VariableNames', {'Day','SnapshotFlux','DailyMean','Ratio','Log10Ratio'} ...
    );

    dayStats = [dayStats; table( ...
        thisDay, numel(x), mu, min(x), max(x), ...
        pUnder, pWithin, pOver, ...
        Rmed, R05, R95, ...
        'VariableNames', { ...
            'Day','nPoints','DailyMean','DailyMin','DailyMax', ...
            'P_UnderByFac','P_WithinFac','P_OverByFac', ...
            'Ratio_Median','Ratio_P05','Ratio_P95' ...
        } ...
    )]; 

    % ---- contribution-based episodicity ----
    if useContributionEpisodicity
        % Contribution proxy per observation:
        % If sampling interval is constant, total daily emission is proportional to sum(x).
        % Contribution share = x / sum(x) (after handling negatives/zeros if needed).
        xPos = x;
        % If negative flux can occur and you want conservative treatment:
        % clamp negatives to zero for contribution accounting
        xPos(xPos < 0) = 0;

        sumX = sum(xPos);
        if sumX <= 0
            topFracTime = NaN;
            topFracEmis = NaN;
            pHitTop = NaN;
        else
            % Sort by flux descending: highest contributors first
            [xSorted, order] = sort(xPos, 'descend');

            % Cumulative emission fraction
            cumEmis = cumsum(xSorted) / sumX;

            % Find smallest set of points that accounts for topTimeFrac of time
            nTop = max(1, round(topTimeFrac * numel(x)));
            topFracTime = nTop / numel(x);
            topFracEmis = sum(xSorted(1:nTop)) / sumX;

            % Probability random snapshot lands in that top-time subset
            pHitTop = topFracTime;
        end

        contribStats = [contribStats; table( ...
            thisDay, numel(x), topFracTime, topFracEmis, pHitTop, ...
            'VariableNames', {'Day','nPoints','TopTimeFraction','TopEmissionFraction','P_SnapshotHitsTopTime'} ...
        )]; 
    end

end

allDrawsTable = vertcat(allDraws{:});
validDays = unique(allDrawsTable.Day);

if isempty(validDays)
    error('No valid days processed. Check Start_Time parsing, CH4_Flux values, and minPointsPerDay.');
end

%% POOLED SUMMARY (FROM RATIOS)
Rall = allDrawsTable.Ratio;

pooledSummary = table();
pooledSummary.nDays = numel(validDays);
pooledSummary.NperDay = N;
pooledSummary.TotalDraws = height(allDrawsTable);

pooledSummary.P_UnderByFac = mean(Rall < 1/misrepFac);
pooledSummary.P_WithinFac  = mean(Rall >= 1/misrepFac & Rall <= misrepFac);
pooledSummary.P_OverByFac  = mean(Rall > misrepFac);

pooledSummary.Ratio_Median = median(Rall);
pooledSummary.Ratio_P05    = prctile(Rall, 5);
pooledSummary.Ratio_P95    = prctile(Rall, 95);

%% Units-based pooled summary (snapshot flux in real units)
% Day-weighted "true" mean = mean of daily means (each day equal weight)
trueMean_dayWeighted = mean(dayStats.DailyMean, 'omitnan');

snap = allDrawsTable.SnapshotFlux;
unitsSummary = table();
unitsSummary.TrueDailyMean_DayWeighted = trueMean_dayWeighted;

unitsSummary.SnapshotFlux_Median = median(snap);
unitsSummary.SnapshotFlux_P25    = prctile(snap, 25);
unitsSummary.SnapshotFlux_P75    = prctile(snap, 75);
unitsSummary.SnapshotFlux_P05    = prctile(snap, 5);
unitsSummary.SnapshotFlux_P95    = prctile(snap, 95);

% Optional: also include absolute error stats (helpful for intuition)
absErr = abs(snap - allDrawsTable.DailyMean);
unitsSummary.AbsError_Median = median(absErr);
unitsSummary.AbsError_P95    = prctile(absErr, 95);

%% Contribution-based episodicity pooled summary
if useContributionEpisodicity && ~isempty(contribStats)
    contribPooled = table();
    contribPooled.TopTimeFraction_Target = topTimeFrac;

    % Equal weight across days:
    contribPooled.MeanTopEmissionFraction = mean(contribStats.TopEmissionFraction, 'omitnan');
    contribPooled.RangeTopEmissionFraction_P05 = prctile(contribStats.TopEmissionFraction, 5);
    contribPooled.RangeTopEmissionFraction_P95 = prctile(contribStats.TopEmissionFraction, 95);

    % Probability a random snapshot lands in that top-time interval
    contribPooled.P_SnapshotHitsTopTime = mean(contribStats.P_SnapshotHitsTopTime, 'omitnan');
else
    contribPooled = table();
end

%% n-snapshot/day curve (monitoring design takeaway)
if doNSnapshotCurve
    nCurve = table(nList(:), nan(numel(nList),1), nan(numel(nList),1), ...
        'VariableNames', {'nSnapshotsPerDay','P_WithinTolerance','P_SevereMischaracterisation'});

    for i = 1:numel(nList)
        nSnap = nList(i);

        withinAll = [];
        severeAll = [];

        for d = 1:numel(days)
            thisDay = days(d);
            idx = (T.Day == thisDay);
            x = T.CH4_Flux(idx);

            if numel(x) < minPointsPerDay
                continue;
            end

            mu = mean(x, 'omitnan');
            if mu == 0 || isnan(mu)
                continue;
            end

            % N simulated visits for this day:
            % each visit draws nSnap points with replacement and averages them
            visitMeans = nan(N,1);
            for v = 1:N
                drawIdx = randi(numel(x), nSnap, 1);
                visitMeans(v) = mean(x(drawIdx), 'omitnan');
            end

            ratioVisit = visitMeans ./ mu;

            % Within ±toleranceFrac => [1-tol, 1+tol]
            lo = 1 - toleranceFrac;
            hi = 1 + toleranceFrac;

            within = mean(ratioVisit >= lo & ratioVisit <= hi);

            severe = mean(ratioVisit < 1/misrepFac | ratioVisit > misrepFac);

            withinAll = [withinAll; within]; 
            severeAll = [severeAll; severe]; 
        end

        % Equal weight across days: average the per-day probabilities
        nCurve.P_WithinTolerance(i) = mean(withinAll, 'omitnan');
        nCurve.P_SevereMischaracterisation(i) = mean(severeAll, 'omitnan');
    end
else
    nCurve = table();
end

%% DISPLAY
disp('--- Per-day summary (dayStats, first 10 rows) ---');
disp(head(dayStats, 10));

disp('--- Pooled ratio summary (pooledSummary) ---');
disp(pooledSummary);

disp('--- NEW: Units-based pooled summary (unitsSummary) ---');
disp(unitsSummary);

if useContributionEpisodicity
    disp('--- NEW: Contribution-based episodicity pooled (contribPooled) ---');
    disp(contribPooled);
end

if doNSnapshotCurve
    disp('--- NEW: n-snapshot design curve (nCurve) ---');
    disp(nCurve);
end

%% PLOTS

% Units-based snapshot distribution (pooled)
figure;
histogram(snap);
xlabel('Snapshot CH_4 flux (same units as input)');
ylabel('Count');
title(sprintf('Pooled snapshot flux distribution (N=%d/day)', N));
grid on;
xline(unitsSummary.TrueDailyMean_DayWeighted, '--', 'True day-weighted mean');

% Contribution-based episodicity per day (top 5% time -> X% emissions)
if useContributionEpisodicity && ~isempty(contribStats)
    figure;
    bar(contribStats.Day, contribStats.TopEmissionFraction);
    ylabel(sprintf('Fraction of daily emissions in top %.0f%% of time', 100*topTimeFrac));
    xlabel('Day');
    title('Contribution-based episodicity (per day)');
    grid on;
end

% Monitoring design curve (probability within tolerance vs n)
if doNSnapshotCurve && ~isempty(nCurve)
    figure;
    plot(nCurve.nSnapshotsPerDay, nCurve.P_WithinTolerance, '-o');
    xlabel('Number of snapshots per day (n)');
    ylabel(sprintf('P(estimate within ±%.0f%% of true mean)', 100*toleranceFrac));
    title('Monitoring design sensitivity (site-specific demonstration)');
    grid on;

    figure;
    plot(nCurve.nSnapshotsPerDay, nCurve.P_SevereMischaracterisation, '-o');
    xlabel('Number of snapshots per day (n)');
    ylabel(sprintf('P(severe mischaracterisation; outside factor %.1f)', misrepFac));
    title('Severe mischaracterisation probability vs n');
    grid on;
end

%% EXPORTS
% writetable(dayStats, 'daySummary_CH4_snapshotMC.csv');
% writetable(pooledSummary, 'pooledSummary_CH4_snapshotMC.csv');
% writetable(allDrawsTable, 'allDraws_CH4_snapshotMC.csv');
% writetable(unitsSummary, 'unitsSummary_CH4_snapshotMC.csv');
% writetable(contribStats, 'contribStats_CH4_snapshotMC.csv');
% writetable(contribPooled, 'contribPooled_CH4_snapshotMC.csv');
% writetable(nCurve, 'nCurve_CH4_snapshotMC.csv');
