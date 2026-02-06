%% -- Comparative boxplots of spatial surveys (MP1–MP21 across SS1–SS6) --
clear; clc

% Load each spatial survey sheet
SS1 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS1");
SS2 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS2");
SS3 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS3");
SS4 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS4");
SS5 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS5");
SS6 = readtable("spring25_spatialSurveys_ordered.xlsx", "Sheet", "SS6");

% Convert CO2 and CH4 flux columns to numeric if they are cells
fluxVars = {'CO2_Flux','CH4_Flux'};
SS_list = {SS1,SS2,SS3,SS4,SS5,SS6};

for k = 1:numel(SS_list)
    for v = 1:numel(fluxVars)
        if iscell(SS_list{k}.(fluxVars{v}))
            SS_list{k}.(fluxVars{v}) = cellfun(@str2double, SS_list{k}.(fluxVars{v}));
        end
    end
end

% Reassign back to individual tables
[SS1,SS2,SS3,SS4,SS5,SS6] = deal(SS_list{:});

%% -- Extract CO₂ and CH₄ fluxes into long arrays --

nMP = 21;
MP_labels = "MP" + string(1:nMP);

% Stack CO2 and CH4 data from all surveys
CO2_all = [SS1.CO2_Flux; SS2.CO2_Flux; SS3.CO2_Flux; ...
           SS4.CO2_Flux; SS5.CO2_Flux; SS6.CO2_Flux];
CH4_all = [SS1.CH4_Flux; SS2.CH4_Flux; SS3.CH4_Flux; ...
           SS4.CH4_Flux; SS5.CH4_Flux; SS6.CH4_Flux];

% Build corresponding MP labels (repeat for each survey)
MP_all = repmat(MP_labels',6,1);

%% -- CO₂ plot --
figure('Color','w');

h1 = boxchart(categorical(MP_all,MP_labels), CO2_all, ...
    'BoxFaceColor',[0 114 178]/255, ... % blue
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x','MarkerColor','k'); % black outliers

xlabel('Monitoring Point','FontSize',14,'FontWeight','bold');
ylabel('CO₂ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ Flux Across Spatial Surveys (SS1–SS6)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

%% -- CH₄ plot --
figure('Color','w');

h2 = boxchart(categorical(MP_all,MP_labels), CH4_all, ...
    'BoxFaceColor',[213 94 0]/255, ... % orange
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x','MarkerColor','k'); % black outliers

xlabel('Monitoring Point','FontSize',14,'FontWeight','bold');
ylabel('CH₄ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CH₄ Flux Across Spatial Surveys (SS1–SS6)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;


%% -- Combined CO₂ & CH₄ plot with secondary axis for Central Offset --
figure('Color','w');
hold on;

% CO₂ boxplots
h1 = boxchart(categorical(MP_all,MP_labels), CO2_all, ...
    'BoxFaceColor',[0 114 178]/255, ... % blue
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x','MarkerColor','k'); % black outliers

% CH₄ boxplots (grouped with CO₂)
h2 = boxchart(categorical(MP_all,MP_labels), CH4_all, ...
    'BoxFaceColor',[213 94 0]/255, ... % orange
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x','MarkerColor','k'); % black outliers

% Primary axis (flux)
xlabel('Monitoring Point','FontSize',14,'FontWeight','bold');
ylabel('Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ & CH₄ Flux Across Spatial Surveys (SS1–SS6)', ...
    'FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

yyaxis right
marker = plot(1:21, SS1.Central_Offset, 'v', ...
    'MarkerSize',6, ...
    'MarkerFaceColor',[1 0.85 0], ...   % yellow fill
    'MarkerEdgeColor','k', ...       % no border
    'HandleVisibility','on');          % keep out of legend
ylabel('Distance from Hotspot (m)','FontSize',14,'FontWeight','bold');
set(gca,'YColor',[1 0.85 0]); % grey axis so it stays subtle

% Reset to left axis
yyaxis left

% Threshold lines
gas_colors = [0 114 178; 213 94 0]/255; % CO2=blue, CH4=orange
yline(1,'--','CO₂ threshold','Color',gas_colors(1,:), ...
    'LineWidth',1.5,'LabelHorizontalAlignment','left', 'LabelVerticalAlignment','top',...
    'FontSize',12);
yline(0.3,'--','CH₄ threshold','Color',gas_colors(2,:), ...
    'LineWidth',1.5,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'FontSize',12);

% Legend
legend([h1 h2 marker],{'CO₂','CH₄', 'Monitoring Point'},'FontSize',12,'Location','best');
hold off;


%% -- Combined CO₂ & CH₄ plot (side-by-side) --
figure('Color','w');

% Build grouping variable: same length as flux data
gas_all  = [repmat("CO₂",numel(CO2_all),1); repmat("CH₄",numel(CH4_all),1)];
flux_all = [CO2_all; CH4_all];
MP_all2  = [MP_all; MP_all];  % repeat monitoring points for both gases

% Plot grouped boxcharts
h = boxchart(categorical(MP_all2,MP_labels), flux_all, ...
    'GroupByColor',gas_all, ...
    'MarkerStyle','x','MarkerColor','k','BoxFaceAlpha',0.7);

% Set colors manually (CO₂ = blue, CH₄ = orange)
colororder([0 114 178; 213 94 0]/255);

xlabel('Monitoring Point','FontSize',14,'FontWeight','bold');
ylabel('Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ & CH₄ Flux Across Spatial Surveys (SS1–SS6)', ...
    'FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

legend(h,{'CO₂','CH₄'},'FontSize',12,'Location','best');

%% -- Summary table of flux statistics across all MPs (NaNs removed) --

summaryTable = table;
summaryTable.MP = MP_labels';

CO2_stats = zeros(nMP,6); % min, Q1, median, mean, Q3, max
CH4_stats = zeros(nMP,6);

for i = 1:nMP
    % Extract fluxes for this MP across all surveys
    CO2_vals = CO2_all(MP_all == MP_labels(i));
    CH4_vals = CH4_all(MP_all == MP_labels(i));
    
    % Remove NaNs
    CO2_vals = CO2_vals(~isnan(CO2_vals));
    CH4_vals = CH4_vals(~isnan(CH4_vals));
    
    % CO2 stats
    CO2_stats(i,1) = min(CO2_vals);
    CO2_stats(i,2) = prctile(CO2_vals,25);
    CO2_stats(i,3) = median(CO2_vals);
    CO2_stats(i,4) = mean(CO2_vals);
    CO2_stats(i,5) = prctile(CO2_vals,75);
    CO2_stats(i,6) = max(CO2_vals);
    
    % CH4 stats
    CH4_stats(i,1) = min(CH4_vals);
    CH4_stats(i,2) = prctile(CH4_vals,25);
    CH4_stats(i,3) = median(CH4_vals);
    CH4_stats(i,4) = mean(CH4_vals);
    CH4_stats(i,5) = prctile(CH4_vals,75);
    CH4_stats(i,6) = max(CH4_vals);
end

% Assign to table
summaryTable.CO2_Min = CO2_stats(:,1);
summaryTable.CO2_Q1  = CO2_stats(:,2);
summaryTable.CO2_Median = CO2_stats(:,3);
summaryTable.CO2_Mean   = CO2_stats(:,4);
summaryTable.CO2_Q3  = CO2_stats(:,5);
summaryTable.CO2_Max = CO2_stats(:,6);

summaryTable.CH4_Min = CH4_stats(:,1);
summaryTable.CH4_Q1  = CH4_stats(:,2);
summaryTable.CH4_Median = CH4_stats(:,3);
summaryTable.CH4_Mean   = CH4_stats(:,4);
summaryTable.CH4_Q3  = CH4_stats(:,5);
summaryTable.CH4_Max = CH4_stats(:,6);

% Export to Excel
writetable(summaryTable,'MP_flux_summary.xlsx');

%% -- Publication-quality boxchart with thresholds and log y-axis --

% Gather all offsets and fluxes across surveys
Offset_all = [SS1.Central_Offset; SS2.Central_Offset; SS3.Central_Offset; ...
              SS4.Central_Offset; SS5.Central_Offset; SS6.Central_Offset];

CO2_all = [SS1.CO2_Flux; SS2.CO2_Flux; SS3.CO2_Flux; ...
           SS4.CO2_Flux; SS5.CO2_Flux; SS6.CO2_Flux];
CH4_all = [SS1.CH4_Flux; SS2.CH4_Flux; SS3.CH4_Flux; ...
           SS4.CH4_Flux; SS5.CH4_Flux; SS6.CH4_Flux];

% Concatenate into one array
flux_all    = [CO2_all; CH4_all];
Offset_all2 = [Offset_all; Offset_all];
gas_all     = [repmat("CO₂",numel(CO2_all),1); repmat("CH₄",numel(CH4_all),1)];

% Define offsets
offset_levels = [0 0.5 0.7 1 2 4];
gas_colors = [0 114 178; 213 94 0]/255; % CO2=blue, CH4=orange

%% Plot
figure('Color','w','Units','centimeters','Position',[2 2 20 12]);
hold on;

for i = 1:numel(offset_levels)
    o = offset_levels(i);
    
    % CO2 boxchart
    this_flux = flux_all(gas_all=="CO₂" & Offset_all2==o);
    if ~isempty(this_flux)
        boxchart(ones(size(this_flux))*o - 0.05, this_flux, ...
            'BoxFaceColor', gas_colors(1,:), ...
            'BoxFaceAlpha',0.5, ...
            'MarkerStyle','x', 'MarkerColor','k', ...
            'BoxWidth',0.08);
    end
    
    % CH4 boxchart
    this_flux = flux_all(gas_all=="CH₄" & Offset_all2==o);
    if ~isempty(this_flux)
        boxchart(ones(size(this_flux))*o + 0.05, this_flux, ...
            'BoxFaceColor', gas_colors(2,:), ...
            'BoxFaceAlpha',0.5, ...
            'MarkerStyle','x', 'MarkerColor','k', ...
            'BoxWidth',0.08);
    end
end

%% Axes & labels
xlabel('Central Offset from Hotspot (m)','FontSize',16,'FontWeight','bold');
ylabel('Flux (μmol m^{-2} s^{-1})','FontSize',16,'FontWeight','bold');
title('CO₂ & CH₄ Flux by Central Offset (SS1–SS6)','FontSize',18,'FontWeight','bold');
set(gca,'FontSize',14,'LineWidth',1.2);
xlim([-0.5 max(offset_levels)+0.5]);
grid on;

%% Threshold lines
yline(1,'--','CO₂ threshold','Color',gas_colors(1,:), ...
    'LineWidth',1.5,'LabelHorizontalAlignment','left', 'LabelVerticalAlignment','top',...
    'FontSize',12);
yline(0.3,'--','CH₄ threshold','Color',gas_colors(2,:), ...
    'LineWidth',1.5,'LabelHorizontalAlignment','left','LabelVerticalAlignment','bottom',...
    'FontSize',12);

%% Legend
plot(nan,nan,'s','MarkerFaceColor',gas_colors(1,:),'MarkerEdgeColor','none','MarkerSize',10);
plot(nan,nan,'s','MarkerFaceColor',gas_colors(2,:),'MarkerEdgeColor','none','MarkerSize',10);
legend({'CO₂','CH₄'},'FontSize',14,'Location','northeast','Box','off');

%% Final touches
set(gca,'XTick',offset_levels);
hold off;

% Export publication-quality figures
set(gcf,'Renderer','painters');
print(gcf,'Flux_by_Offset_Boxchart_Thresholds','-dpdf','-r300');
print(gcf,'Flux_by_Offset_Boxchart_Thresholds','-dpng','-r600');

%% -- Kruskal–Wallis test: CH₄ fluxes >1 m vs. background fluxes --

% Load background flux data
BG = readtable("spring25_backgroundFluxes_continuous.xlsx");
BG_flux = BG.CH4_Flux;
BG_flux = BG_flux(~isnan(BG_flux)); % remove NaNs

% Extract CH₄ fluxes at offsets > 1 m (from combined dataset above)
CH4_far = flux_all(gas_all=="CH₄" & Offset_all2 > 1);
CH4_far = CH4_far(~isnan(CH4_far)); % remove NaNs

% Combine data and define groups
data = [CH4_far; BG_flux];
groups = [repmat({'>1 m'}, numel(CH4_far), 1); ...
          repmat({'Background'}, numel(BG_flux), 1)];

% Perform Kruskal–Wallis test
[p, tbl, stats] = kruskalwallis(data, groups);
disp('Kruskal–Wallis p-value (CH₄ >1 m vs. Background):');
disp(p);

% Optional: post-hoc multiple comparison
if p < 0.05
    disp('Significant difference found. Running post-hoc comparison:');
    multcompare(stats);
end

% Boxplot visualization
figure('Color','w');
boxchart(categorical(groups), data, ...
    'BoxFaceColor',[213 94 0]/255, 'BoxFaceAlpha',0.6, ...
    'MarkerStyle','x','MarkerColor','k');
ylabel('CH₄ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CH₄ Flux: >1 m vs. Background (Kruskal–Wallis)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;
