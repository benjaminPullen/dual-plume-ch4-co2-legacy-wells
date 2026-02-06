%% ==============================================================
%  Box & Whisker Plots of CO2 & CH4 Flux Binned by Distance
%  (SS1–SS6 Spatial Surveys)
% ==============================================================

clear; clc

%% -- Load surveys --
SS1 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS1");
SS2 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS2");
SS3 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS3");
SS4 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS4");
SS5 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS5");
SS6 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS6");

SS_list = {SS1,SS2,SS3,SS4,SS5,SS6};
fluxVars = {'CO2_Flux','CH4_Flux'};

BG = readtable("spring25_backgroundFluxes_continuous.xlsx");

%% ==============================================================
% Add background fluxes and bin everything together
% ==============================================================

% Load background fluxes
BG = readtable("spring25_backgroundFluxes_continuous.xlsx");

fluxVars = {'CO2_Flux','CH4_Flux'};
for v = 1:numel(fluxVars)
    if iscell(BG.(fluxVars{v}))
        BG.(fluxVars{v}) = cellfun(@str2double, BG.(fluxVars{v}));
    end
end

BG_offset = 50 * ones(height(BG),1);

%% Combine all surveys + background into long arrays

Offset_all = [SS1.Central_Offset; SS2.Central_Offset; SS3.Central_Offset; ...
              SS4.Central_Offset; SS5.Central_Offset; SS6.Central_Offset; ...
              BG_offset];

CO2_all = [SS1.CO2_Flux; SS2.CO2_Flux; SS3.CO2_Flux; ...
           SS4.CO2_Flux; SS5.CO2_Flux; SS6.CO2_Flux; ...
           BG.CO2_Flux];

CH4_all = [SS1.CH4_Flux; SS2.CH4_Flux; SS3.CH4_Flux; ...
           SS4.CH4_Flux; SS5.CH4_Flux; SS6.CH4_Flux; ...
           BG.CH4_Flux];

%% ==============================================================
% Updated distance bins (last one is Background)
% ==============================================================

bin_edges = [0 0.5 1 2 4 8 100];   
bin_labels = [ ...
    "0–0.5 m"
    "0.5–1 m"
    "1–2 m"
    "2–4 m"
    "4–6 m"
    "Background (~50 m)" ];

% Digitize offsets into bins
bin_idx = discretize(Offset_all, bin_edges);

% Remove NaNs
valid = ~isnan(bin_idx);
bin_idx = bin_idx(valid);

CO2_all = CO2_all(valid);
CH4_all = CH4_all(valid);

%% ==============================================================
%  Create boxplots by distance bin
% ==============================================================

gas_colors = [213 94 0;0 114 178]/255; % CO2=blue, CH4=orange

%% ============================
% CO₂ Binned Boxplot
% ============================
figure('Color','w');
boxchart(categorical(bin_idx,1:numel(bin_labels),bin_labels), CO2_all, ...
    'BoxFaceColor',gas_colors(1,:), ...
    'BoxFaceAlpha',0.6, ...
    'MarkerStyle','x','MarkerColor','k');

xlabel('Distance Bin from Centre','FontSize',14,'FontWeight','bold');
ylabel('CO₂ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ Flux Binned by Distance (SS1–SS6)','FontSize',16,'FontWeight','bold');

set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

%% ============================
% CH₄ Binned Boxplot
% ============================
figure('Color','w');
boxchart(categorical(bin_idx,1:numel(bin_labels),bin_labels), CH4_all, ...
    'BoxFaceColor',gas_colors(2,:), ...
    'BoxFaceAlpha',0.6, ...
    'MarkerStyle','x','MarkerColor','k');

xlabel('Distance Bin from Centre','FontSize',14,'FontWeight','bold');
ylabel('CH₄ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CH₄ Flux Binned by Distance (SS1–SS6)','FontSize',16,'FontWeight','bold');

set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

%% ============================
% Side-by-side CO₂/CH₄ grouped boxplot
% ============================
gas_all = [repmat("CO₂",numel(CO2_all),1); repmat("CH₄",numel(CH4_all),1)];
flux_all = [CO2_all; CH4_all];
bin_idx2 = [bin_idx; bin_idx]; 

figure('Color','w');
hold on;

h = boxchart(categorical(bin_idx2,1:numel(bin_labels),bin_labels), flux_all, ...
    'GroupByColor', gas_all, ...
    'MarkerStyle','x','MarkerColor','k', ...
    'BoxFaceAlpha',0.6, ...
    'BoxWidth', 1);

colororder(gas_colors);

xlabel('Distance Bin from Centre','FontSize',14,'FontWeight','bold');
ylabel('Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ & CH₄ Flux by Distance Bins','FontSize',16,'FontWeight','bold');

legend(h,{'CH₄', 'CO₂'},'FontSize',12,'Location','best');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;
hold off;
