%% Load data
file = 'spring25_backgroundFluxes_continuous.xlsx';
tbl = readtable(file);

% Extract variables
CH4 = tbl.CH4_Flux;
CO2 = tbl.CO2_Flux;
time = datetime(tbl.Start_Time, 'InputFormat','yyyy-MM-dd HH:mm:ss');

%% Create Figure
figure('Position',[200 200 1400 600]);
%tiledlayout(1,2);

% Gas colors (CO2 = blue, CH4 = orange)
gas_colors = [213 94 0; 0 114 178] / 255;

%% Panel 1: Time series scatter plots
%nexttile;
hold on;

hCO2 = scatter(time, CO2, 20, 'filled', 'MarkerFaceAlpha',0.6);
hCH4 = scatter(time, CH4, 20, 'filled', 'MarkerFaceAlpha',0.6);

hold off;

legend([hCH4 hCO2], {'CH_{4} Flux', 'CO_{2} Flux'}, 'Location','best');
xlabel('Time');
ylabel('Flux (µmol m^{-2} s^{-1})');
grid on;


%% Panel 2: Box & Whisker Plot (Styled to Match Spatial Survey Figures)
figure('Position',[200 200 1400 600]);
%nexttile;
hold on;

% CH4 box
boxchart(ones(size(CH4)), CH4, ...
    'BoxFaceColor', gas_colors(1,:), ...
    'BoxFaceAlpha', 0.6, ...
    'MarkerStyle','x', ...
    'MarkerColor','k');

% CO2 box
boxchart(2*ones(size(CO2)), CO2, ...
    'BoxFaceColor', gas_colors(2,:), ...
    'BoxFaceAlpha', 0.6, ...
    'MarkerStyle','x', ...
    'MarkerColor','k');

% Axes formatting
xlim([0.5 2.5]);
set(gca,'XTick',[1 2], 'XTickLabel',{'CH_{4}','CO_{2}'}, 'FontSize',12, 'LineWidth',1.2);
ylabel('Flux (µmol m^{-2} s^{-1})');
%title('Distribution of Wellhead Fluxes');
grid on;
hold off;