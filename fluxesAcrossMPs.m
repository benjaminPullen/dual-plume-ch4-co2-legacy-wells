%% -- Comparative boxplots of fluxes by monitoring period (MP11, 2025) --
clear; clc

% Load each monitoring period sheet
MP_A = readtable("spring25_wellheadFluxes_continuous.xlsx", "Sheet", "MP_C");
MP_B = readtable("spring25_wellheadFluxes_continuous.xlsx", "Sheet", "MP_D");
MP_C = readtable("spring25_wellheadFluxes_continuous.xlsx", "Sheet", "MP_E");
MP_D = readtable("spring25_wellheadFluxes_continuous.xlsx", "Sheet", "MP_F");

% Clean NaNs
co2_A = rmmissing(MP_A.CO2_Flux);
co2_B = rmmissing(MP_B.CO2_Flux);
co2_C = rmmissing(MP_C.CO2_Flux);
co2_D = rmmissing(MP_D.CO2_Flux);

ch4_A = rmmissing(MP_A.CH4_Flux);
ch4_B = rmmissing(MP_B.CH4_Flux);
ch4_C = rmmissing(MP_C.CH4_Flux);
ch4_D = rmmissing(MP_D.CH4_Flux);

periods = ["MP_A","MP_B","MP_C","MP_D"];

%% -- CO₂ plot --
figure('Color','w');

X_co2 = [repmat("MP_A",numel(co2_A),1);
         repmat("MP_B",numel(co2_B),1);
         repmat("MP_C",numel(co2_C),1);
         repmat("MP_D",numel(co2_D),1)];

Y_co2 = [co2_A; co2_B; co2_C; co2_D];

% Plot
h1 = boxchart(categorical(X_co2,periods), Y_co2, ...
    'BoxFaceColor',[0 114 178]/255, ... % blue
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x', 'MarkerColor','k'); % outliers: black x

xlabel('Monitoring Period','FontSize',14,'FontWeight','bold');
ylabel('CO₂ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ Flux by Monitoring Period (MP11, 2025)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

% Annotate n above each box (outside box)
nVals_co2 = [numel(co2_A), numel(co2_B), numel(co2_C), numel(co2_D)];
yl = ylim;
ylim([yl(1) yl(2)*1.1])
yOffset = (yl(2)-yl(1))*0.05; % offset above box
for i = 1:4
    text(i, max(Y_co2(X_co2==periods(i))) + yOffset, ...
        sprintf('n=%d', nVals_co2(i)), ...
        'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','k');
end

%% -- CH₄ plot --
figure('Color','w');

X_ch4 = [repmat("MP_A",numel(ch4_A),1);
         repmat("MP_B",numel(ch4_B),1);
         repmat("MP_C",numel(ch4_C),1);
         repmat("MP_D",numel(ch4_D),1)];

Y_ch4 = [ch4_A; ch4_B; ch4_C; ch4_D];

% Plot
h2 = boxchart(categorical(X_ch4,periods), Y_ch4, ...
    'BoxFaceColor',[213 94 0]/255, ... % orange
    'BoxFaceAlpha',0.7, ...
    'MarkerStyle','x', 'MarkerColor','k'); % outliers: black x

xlabel('Monitoring Period','FontSize',14,'FontWeight','bold');
ylabel('CH₄ Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CH₄ Flux by Monitoring Period (MP11, 2025)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;

% Annotate n above each box (outside box)
nVals_ch4 = [numel(ch4_A), numel(ch4_B), numel(ch4_C), numel(ch4_D)];
yl = ylim;
ylim([yl(1) yl(2)*1.1])
yOffset = (yl(2)-yl(1))*0.05;
for i = 1:4
    text(i, max(Y_ch4(X_ch4==periods(i))) + yOffset, ...
        sprintf('n=%d', nVals_ch4(i)), ...
        'HorizontalAlignment','center','FontSize',12,'FontWeight','bold','Color','k');
end

%% -- Combined CO₂ & CH₄ plot --
figure('Color','w');

% Combine data into one vector
Y_all = [co2_A; co2_B; co2_C; co2_D;
         ch4_A; ch4_B; ch4_C; ch4_D];

% Monitoring period labels (string → categorical, enforce order)
periods = ["MP_A","MP_B","MP_C","MP_D"];
X_all = [repmat("MP_A",numel(co2_A),1);
         repmat("MP_B",numel(co2_B),1);
         repmat("MP_C",numel(co2_C),1);
         repmat("MP_D",numel(co2_D),1);
         repmat("MP_A",numel(ch4_A),1);
         repmat("MP_B",numel(ch4_B),1);
         repmat("MP_C",numel(ch4_C),1);
         repmat("MP_D",numel(ch4_D),1)];
X_all = categorical(X_all, periods);

% Gas type grouping (string → categorical)
G_all = [repmat("CO2", numel(co2_A)+numel(co2_B)+numel(co2_C)+numel(co2_D),1);
         repmat("CH4", numel(ch4_A)+numel(ch4_B)+numel(ch4_C)+numel(ch4_D),1)];
G_all = categorical(G_all, ["CO2","CH4"]);

% Plot grouped boxcharts
h = boxchart(X_all, Y_all, 'GroupByColor', G_all);

% Styling
h(1).BoxFaceColor = [0 114 178]/255; % CO₂ = blue
h(2).BoxFaceColor = [213 94 0]/255;  % CH₄ = orange
h(1).BoxFaceAlpha = 0.7;
h(2).BoxFaceAlpha = 0.7;
h(1).MarkerStyle = 'x'; h(1).MarkerColor = 'k'; % outliers
h(2).MarkerStyle = 'x'; h(2).MarkerColor = 'k';

xlabel('Monitoring Period','FontSize',14,'FontWeight','bold');
ylabel('Flux (μmol m^{-2} s^{-1})','FontSize',14,'FontWeight','bold');
title('CO₂ & CH₄ Flux by Monitoring Period (MP11, 2025)','FontSize',16,'FontWeight','bold');
set(gca,'FontSize',12,'LineWidth',1.2);
grid on;
legend(h,{'CO₂','CH₄'},'FontSize',12,'Location','northeast'); % top-right

%% -- Annotate n above each box --
nVals_co2 = [numel(co2_A), numel(co2_B), numel(co2_C), numel(co2_D)];
nVals_ch4 = [numel(ch4_A), numel(ch4_B), numel(ch4_C), numel(ch4_D)];

yl = ylim;
ylim([yl(1) yl(2)*1.2]) % add headroom
yOffset = (yl(2)-yl(1))*0.05;

for i = 1:4
    % CO₂ (left of group i)
    text(i-0.15, max(Y_all(X_all==periods(i) & G_all=="CO2")) + yOffset, ...
        sprintf('n=%d', nVals_co2(i)), ...
        'HorizontalAlignment','center','FontSize',11,'FontWeight','bold','Color',[0 114 178]/255);

    % CH₄ (right of group i)
    text(i+0.15, max(Y_all(X_all==periods(i) & G_all=="CH4")) + yOffset, ...
        sprintf('n=%d', nVals_ch4(i)), ...
        'HorizontalAlignment','center','FontSize',11,'FontWeight','bold','Color',[213 94 0]/255);
end