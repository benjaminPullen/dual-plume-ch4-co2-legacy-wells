%% ----------------- Master Workflow: PCA + PCR + MLR Comparison -----------------
% Author: Benjamin Pullen
% Date: 10/09/2025
% Description: Complete analysis linking CH4 flux to environmental variables.

clear; close all; clc;

%% ----------------- Load Data -----------------
data = readtable("merged_flux_weather.xlsx");
bg_data = readtable("spring25_backgroundFluxes_continuous.xlsx");

%% ----------------- Compute Excess CH4 Flux -----------------
flux_raw = data.CH4_Flux;
bg_flux   = bg_data.CH4_Flux;
bg_mean   = mean(bg_flux, 'omitnan');
bg_std    = std(bg_flux, 'omitnan');
bg_thresh = bg_mean + 3*bg_std;

excess_flux = flux_raw - bg_thresh;
excess_flux(excess_flux < 0) = 0; 
data.Excess_CH4_Flux = excess_flux;

%% ----------------- Define Predictor Variables -----------------
predictorVars = data(:, { ...
    'W_m2SolarRadiation', ...
    'degreesWindDirection', ...
    'm_sWindSpeed', ...
    'm_sGustSpeed', ...
    'degree_CAirTemperature', ...
    'kPaVaporPressure', ...
    'kPaAtmosphericPressure', ...
    'kPaVPD', ...
    'm3_m3WaterContent', ...
    'degree_CSoilTemperature', ...
    'mS_cmSaturationExtractEC', ...
    'm3_m3WaterContent_1', ...
    'degree_CSoilTemperature_1', ...
    'mS_cmSaturationExtractEC_1', ...
    'kPaMatricPotential', ...
    'degree_CSoilTemperature_2', ...
    'degree_C30CmSoilTemperature4', ...
    'degree_C50CmSoilTemperature5', ...
    'degree_C100CmSoilTemperature6' ...
    }); 

predictorNames = predictorVars.Properties.VariableNames;
X = table2array(predictorVars);
y = data.Excess_CH4_Flux;

%% ----------------- PCA -----------------
Xz = zscore(X);
[coeff, score, latent, ~, explained, mu] = pca(Xz);
numPCs = 5; % first 5 PCs
topN = 5;  % top 5 variables per PC

% Scree plot with cumulative variance
figure('Position',[100 100 700 400]); hold on;
explainedPCs = explained(1:numPCs);
cumVar = cumsum(explainedPCs);

bar(1:numPCs, explainedPCs, 0.6, 'FaceColor',[0.2 0.6 0.8], 'DisplayName','Individual PC');
yyaxis right
plot(1:numPCs, cumVar, '-o', 'Color',[0.9 0.3 0.2], 'LineWidth',2, 'MarkerSize',8, 'DisplayName','Cumulative');
ylabel('Cumulative Variance (%)','FontSize',12);
yyaxis left
ylabel('Variance Explained (%)','FontSize',12);
xlabel('Principal Component','FontSize',12);
xticks(1:numPCs); xticklabels(strcat("PC", string(1:numPCs)));
title('Variance Explained and Cumulative Variance by PCs','FontSize',14);
grid on; box on;
legend('Location','northwest');

%% ----------------- Top Variable Loadings -----------------
topVars = cell(topN, numPCs);
topVals = nan(topN, numPCs);
for pc = 1:numPCs
    loadings = coeff(:,pc);
    [~, idx] = sort(abs(loadings), 'descend');
    topVars(:,pc) = predictorNames(idx(1:topN))';
    topVals(:,pc) = loadings(idx(1:topN));
end

% Heatmap of top variable loadings
figure('Position',[100 100 700 500]);
imagesc(topVals); colormap(parula); clim([-1 1]); colorbar;
xlabel('Principal Component','FontSize',12); ylabel('Rank','FontSize',12);
title('Top Variable Loadings per PC','FontSize',14);
set(gca, 'XTick', 1:numPCs, 'XTickLabel', strcat("PC", string(1:numPCs)), 'FontSize',10);
set(gca, 'YTick', 1:topN, 'YTickLabel', strcat("Rank", string(1:topN)));
for r = 1:topN
    for c = 1:numPCs
        text(c, r, sprintf('%s\n%.2f', topVars{r,c}, topVals(r,c)), ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'FontSize',9,'FontWeight','bold','Color','k');
    end
end
axis tight; box on;

%% ----------------- Correlation of PCs with CH4 Flux -----------------
pc_flux_corr = zeros(1,numPCs);
pc_flux_pval = zeros(1,numPCs);
for pc = 1:numPCs
    [r,p] = corr(score(:,pc), y, 'Rows','complete');
    pc_flux_corr(pc) = r;
    pc_flux_pval(pc) = p;
end

disp('--- PC Correlations with Excess CH4 Flux ---');
for pc = 1:numPCs
    fprintf('PC%d: r = %.3f, p = %.3f\n', pc, pc_flux_corr(pc), pc_flux_pval(pc));
end

% Bar plot of correlations
figure('Position',[100 100 600 400]);
bar(pc_flux_corr,'FaceColor',[0.3 0.7 0.4]);
xlabel('Principal Component','FontSize',12);
ylabel('Correlation with Excess CH4 Flux','FontSize',12);
title('PC Correlations with CH4 Flux','FontSize',14);
grid on; box on;

%% ----------------- PCR: Multiple Regression -----------------
mdl_PCR = fitlm(score(:,1:numPCs), y);

% Scatter plot observed vs predicted
yPred_PCR = predict(mdl_PCR, score(:,1:numPCs));
figure('Position',[100 100 600 400]);
scatter(y, yPred_PCR, 50, 'filled', 'MarkerFaceColor',[0.2 0.6 0.8]); hold on;
plot([min(y) max(y)], [min(y) max(y)], 'r--', 'LineWidth',2);
xlabel('Observed Excess CH_4 Flux','FontSize',12);
ylabel('Predicted Excess CH_4 Flux','FontSize',12);
title('PCR: Observed vs Predicted Flux','FontSize',14);
grid on; box on;

fprintf('\n--- PCR Model Statistics ---\n');
fprintf('R² = %.3f, Adjusted R² = %.3f, RMSE = %.3f\n', ...
    mdl_PCR.Rsquared.Ordinary, mdl_PCR.Rsquared.Adjusted, mdl_PCR.RMSE);
disp('PCR Coefficients:'); disp(mdl_PCR.Coefficients);

%% ----------------- MLR on Raw Predictors -----------------
mlrModel = fitlm(X, y, 'VarNames',[predictorNames, {'Excess_CH4_Flux'}]);
disp('--- Multiple Linear Regression ---');
disp(mlrModel);
fprintf('R² = %.3f, Adjusted R² = %.3f\n', mlrModel.Rsquared.Ordinary, mlrModel.Rsquared.Adjusted);

% Plot observed vs predicted MLR
yPred_MLR = predict(mlrModel, X);
figure('Position',[100 100 600 400]);
scatter(y, yPred_MLR, 50, 'filled', 'MarkerFaceColor',[0.3 0.7 0.4]); hold on;
plot([min(y) max(y)], [min(y) max(y)], 'r--', 'LineWidth',2);
xlabel('Observed Excess CH_4 Flux','FontSize',12);
ylabel('Predicted Excess CH_4 Flux','FontSize',12);
title('MLR: Observed vs Predicted Flux','FontSize',14);
grid on; box on;

%% ----------------- Compare MLR and PCR -----------------
sigMask = mlrModel.Coefficients.pValue < 0.05;
sigPredictors = mlrModel.Coefficients.Properties.RowNames(sigMask);

sigPCs = find(pc_flux_pval < 0.05);
fprintf('Significant PCs: '); fprintf('PC%d ', sigPCs); fprintf('\n');

% Create table linking MLR and PCR
allPredictors = predictorNames';
mlrSig = ismember(allPredictors, sigPredictors);
pcLoading = nan(length(allPredictors), numPCs);
for pc = 1:numPCs
    for r = 1:topN
        idx = find(strcmp(allPredictors, topVars{r,pc}));
        if ~isempty(idx)
            pcLoading(idx, pc) = topVals(r, pc);
        end
    end
end

comparisonTable = table(allPredictors, mlrSig, pcLoading(:,1), pcLoading(:,2), pcLoading(:,3), ...
    pcLoading(:,4), pcLoading(:,5), ...
    'VariableNames', {'Predictor','SignificantMLR','PC1_Loading','PC2_Loading','PC3_Loading','PC4_Loading','PC5_Loading'});
disp('--- Combined MLR + PCR Table ---');
disp(comparisonTable);

% Heatmap with MLR significance highlighted
% Replace NaNs with 0 for display purposes only
displayLoadings = pcLoading;
displayLoadings(isnan(displayLoadings)) = 0;

% Heatmap with MLR significance highlighted
figure('Position',[100 100 900 400]);
imagesc(displayLoadings); 
colormap(parula); 
clim([-1 1]); 
colorbar;
xlabel('PC','FontSize',12); 
ylabel('Predictors','FontSize',12);
yticks(1:length(allPredictors)); yticklabels(allPredictors);
xticks(1:numPCs); xticklabels(strcat("PC", string(1:numPCs)));
title('Top Variable Loadings Across PCs (MLR significance highlighted)', 'FontSize',14);
hold on;

% Highlight MLR significant predictors
[rows, ~] = find(mlrSig);
for r = 1:length(rows)
    x = linspace(0.5, numPCs+0.5, numPCs);
    yRow = rows(r) * ones(1, numPCs);
    plot(x, yRow, 'k-', 'LineWidth',1.5);
end
