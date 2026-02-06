%% ----------------- Processing Surfer Grids -----------------
% Author: Benjamin Pullen
% Date: 16/09/2025

clear; close all; clc;

%% ------------------ User Inputs ------------------
co2_files = {'2025rawCO2nn.asc'};
ch4_files = {'2025rawCH4nn.asc'};
% %% ------------------ User Inputs ------------------
% co2_files = {
%     'SS1_CO2_NATN_RAW.asc', 'SS2_CO2_NATN_RAW.asc', 'SS4_CO2_NATN_RAW.asc',...
%     'SS5_CO2_NATN_RAW.asc', 'SS6_CO2_NATN_RAW.asc'};
% ch4_files = {
%     'SS1_CH4_NATN_RAW.asc', 'SS2_CH4_NATN_RAW.asc', 'SS4_CH4_NATN_RAW.asc',...
%     'SS5_CH4_NATN_RAW.asc', 'SS6_CH4_NATN_RAW.asc'};

% % Background thresholds (mean + 3*std)
% bg_data = readtable("spring25_backgroundFluxes_continuous.xlsx");
% co2_threshold = mean(bg_data.CO2_Flux,'omitnan') + 3*std(bg_data.CO2_Flux,'omitnan');
% ch4_threshold = mean(bg_data.CH4_Flux,'omitnan') + 3*std(bg_data.CH4_Flux,'omitnan');

% Background thresholds (mean + 3*std)
bg_data = readtable("spring25_backgroundFluxes_continuous.xlsx");
co2_threshold = 2.5;
ch4_threshold = 0.5;

%% ------------------ Run Analysis ------------------
co2_results  = processFluxFiles(co2_files, co2_threshold);
ch4_results  = processFluxFiles(ch4_files, ch4_threshold);

%% ------------------ Day-to-Day Footprint Overlap ------------------
[co2_overlap, co2_disp]   = computeFootprintOverlap(co2_results, co2_threshold);
[ch4_overlap, ch4_disp]   = computeFootprintOverlap(ch4_results, ch4_threshold);

%% ------------------ Figures ------------------
set(groot,'defaultAxesFontSize',14);
set(groot,'defaultAxesLabelFontSizeMultiplier',1.2);
set(groot,'defaultAxesTitleFontSizeMultiplier',1.3);

% Define colours
co2_color  = [0 0.45 0.74];    % blue
ch4_color  = [0.85 0.33 0.10]; % reddish-orange
co2e_color = [0.47 0.67 0.19]; % green

% Figure 1: Footprint Area
figure('Color','w'); hold on;
plot(1:numel(co2_results), [co2_results.area], '-o','Color',co2_color,'LineWidth',2,'MarkerSize',10);
plot(1:numel(ch4_results), [ch4_results.area], '-s','Color',ch4_color,'LineWidth',2,'MarkerSize',10);
xlabel('Survey Number'); ylabel('Area (m²)'); title('Footprint Area'); grid on;
legend('CO₂','CH₄','Location','best'); xticks(1:max([numel(co2_results),numel(ch4_results)]));

% Figure 2: Compactness
figure('Color','w'); hold on;
plot([co2_results.compactness], '-o','Color',co2_color,'LineWidth',2,'MarkerSize',10);
plot([ch4_results.compactness], '-s','Color',ch4_color,'LineWidth',2,'MarkerSize',10);
xlabel('Survey Number'); ylabel('P²/4πA'); title('Footprint Compactness'); grid on;
legend('CO₂','CH₄','Location','best'); xticks(1:max([numel(co2_results),numel(ch4_results)]));

% Figure 3: Flux-Weighted Centroid Trajectories
figure('Color','w'); hold on;
plot([co2_results.fluxWeightedCentroidX],[co2_results.fluxWeightedCentroidY],'-o','Color',co2_color,'LineWidth',2,'MarkerSize',10);
plot([ch4_results.fluxWeightedCentroidX],[ch4_results.fluxWeightedCentroidY],'-s','Color',ch4_color,'LineWidth',2,'MarkerSize',10);
xlabel('X (m)'); ylabel('Y (m)'); title('Flux-Weighted Centroid Trajectories'); grid on; axis equal;
legend('CO₂','CH₄, Location','best');

% Figure 4: Footprint Stability
figure('Color','w'); 
subplot(1,2,1); hold on;
plot(2:numel(co2_results), co2_overlap,'-o','Color',co2_color,'LineWidth',2,'MarkerSize',10);
plot(2:numel(ch4_results), ch4_overlap,'-s','Color',ch4_color,'LineWidth',2,'MarkerSize',10);
xlabel('Survey Number'); ylabel('Fractional Overlap'); title('Day-to-Day Footprint Overlap'); grid on;
legend('CO₂','CH₄'); xticks(2:max([numel(co2_results),numel(ch4_results)]));

subplot(1,2,2); hold on;
plot(2:numel(co2_results), co2_disp,'-o','Color',co2_color,'LineWidth',2,'MarkerSize',10);
plot(2:numel(ch4_results), ch4_disp,'-s','Color',ch4_color,'LineWidth',2,'MarkerSize',10);
xlabel('Survey Number'); ylabel('Centroid Displacement (m)'); title('Flux-Weighted Centroid Displacement'); grid on;
legend('CO₂','CH₄'); xticks(2:max([numel(co2_results),numel(ch4_results)]));

% Figure 5: Compass-Oriented Rose Diagram
co2_orient  = [co2_results.orientation];
ch4_orient  = [ch4_results.orientation];

figure('Name','Footprint Orientation Rose','Color','w');
h1 = polarhistogram(deg2rad(co2_orient),36,'FaceColor',co2_color,'FaceAlpha',0.5,'EdgeColor','k'); 
hold on;
h2 = polarhistogram(deg2rad(ch4_orient),36,'FaceColor',ch4_color,'FaceAlpha',0.5,'EdgeColor','k');
title('Flux Footprint Orientation (Compass)');
thetalim([0 180]);
theta_ref = deg2rad([0 90 180]); % N, E, S
rmax = max([h1.Values,h2.Values])*1.1;
for t = theta_ref
    polarplot([t t],[0 rmax],'k--','LineWidth',1.2);
end
thetalim([0 180]); ax = gca; ax.ThetaDir = 'clockwise'; ax.ThetaZeroLocation='top';
title('Flux Footprint Orientation (0-180°)'); 
legend({'CO₂','CH₄'},'Location','best');

%% ------------------ Functions ------------------
function results = processFluxFiles(flux_files, threshold)
    results = struct();
    for k = 1:numel(flux_files)
        % --- Load grid ---
        gridData = readASC(flux_files{k});
        gridData(gridData == 1.70141e+38) = NaN; % Surfer NoData
        info = readASCinfo(flux_files{k});
        cellsize = info.cellsize;

        % --- Binary mask above threshold ---
        BW = gridData > threshold;

        % --- Handle empty footprint case ---
        if ~any(BW,'all')
            results(k).filename = flux_files{k};
            results(k).area = 0; results(k).perimeter = 0; results(k).compactness = NaN;
            results(k).centroid = [NaN NaN]; results(k).fluxWeightedCentroidX = NaN;
            results(k).fluxWeightedCentroidY = NaN; results(k).orientation = NaN; 
            continue;
        end

        % --- Footprint metrics (geometry-based) ---
        area = sum(BW,'all')*cellsize^2;
        perim = sum(bwperim(BW,8),'all')*cellsize;
        compactness = (perim^2)/(4*pi*area);
        s = regionprops(BW,'Centroid','Orientation');
        centroid = s.Centroid*cellsize; % polygon centroid
        orientation = mod(s.Orientation+90,180); % fold to 0–180°

        % --- Flux-weighted centroid ---
        gridMasked = gridData; 
        gridMasked(~BW) = NaN; % only keep flux > threshold

        [nrows,ncols] = size(gridMasked);
        xv = info.xllcorner + (0:ncols-1)*cellsize + cellsize/2;
        yv = info.yllcorner + (nrows-1:-1:0)*cellsize + cellsize/2;
        [X,Y] = meshgrid(xv, yv);

        F = gridMasked;
        totalFlux = nansum(F(:));

        fluxX = nansum(X(:).*F(:)) / totalFlux;
        fluxY = nansum(Y(:).*F(:)) / totalFlux;

        % --- Save results ---
        results(k).filename = flux_files{k};
        results(k).area = area; 
        results(k).perimeter = perim; 
        results(k).compactness = compactness;
        results(k).centroid = centroid; 
        results(k).fluxWeightedCentroidX = fluxX;
        results(k).fluxWeightedCentroidY = fluxY; 
        results(k).orientation = orientation;
    end
end

function results = processFluxFiles_noThreshold(flux_files)
    results = struct();
    for k = 1:numel(flux_files)
        gridData = readASC(flux_files{k});
        gridData(gridData == 1.70141e+38) = NaN; 
        info = readASCinfo(flux_files{k});
        cellsize = info.cellsize;

        BW = ~isnan(gridData);

        if ~any(BW,'all')
            results(k).filename = flux_files{k};
            results(k).area = 0; results(k).perimeter = 0; results(k).compactness = NaN;
            results(k).centroid = [NaN NaN]; results(k).fluxWeightedCentroidX = NaN;
            results(k).fluxWeightedCentroidY = NaN; results(k).orientation = NaN; 
            continue;
        end

        area = sum(BW,'all')*cellsize^2;
        perim = sum(bwperim(BW,8),'all')*cellsize;
        compactness = (perim^2)/(4*pi*area);
        s = regionprops(BW,'Centroid','Orientation');
        centroid = s.Centroid*cellsize;
        orientation = mod(s.Orientation+90,180);

        [nrows,ncols] = size(gridData);
        xv = info.xllcorner + (0:ncols-1)*cellsize + cellsize/2;
        yv = info.yllcorner + (nrows-1:-1:0)*cellsize + cellsize/2;
        [X,Y] = meshgrid(xv, yv);

        F = gridData;
        totalFlux = nansum(F(:));
        fluxX = nansum(X(:).*F(:)) / totalFlux;
        fluxY = nansum(Y(:).*F(:)) / totalFlux;

        results(k).filename = flux_files{k};
        results(k).area = area; 
        results(k).perimeter = perim; 
        results(k).compactness = compactness;
        results(k).centroid = centroid; 
        results(k).fluxWeightedCentroidX = fluxX;
        results(k).fluxWeightedCentroidY = fluxY; 
        results(k).orientation = orientation;
    end
end

function info = readASCinfo(filename)
    fid=fopen(filename,'r'); info.ncols=sscanf(fgetl(fid),'ncols %d');
    info.nrows=sscanf(fgetl(fid),'nrows %d'); info.xllcorner=sscanf(fgetl(fid),'xllcorner %f');
    info.yllcorner=sscanf(fgetl(fid),'yllcorner %f'); info.cellsize=sscanf(fgetl(fid),'cellsize %f');
    info.nodata_value=sscanf(fgetl(fid),'nodata_value %f'); fclose(fid);
end

function grid = readASC(filename)
    fid = fopen(filename,'r');
    if fid == -1, error('Cannot open file: %s', filename); end
    ncols = sscanf(fgetl(fid),'ncols %d');
    nrows = sscanf(fgetl(fid),'nrows %d');
    xllcorner = sscanf(fgetl(fid),'xllcorner %f');
    yllcorner = sscanf(fgetl(fid),'yllcorner %f');
    cellsize = sscanf(fgetl(fid),'cellsize %f');
    nodata = sscanf(fgetl(fid),'nodata_value %f');
    data = fscanf(fid, '%f', [ncols, nrows]); fclose(fid);
    if numel(data) ~= ncols*nrows
        error('Mismatch between header and grid size in %s', filename);
    end
    grid = data'; grid(grid == nodata) = NaN;
end

function [overlapFrac, centroidShift] = computeFootprintOverlap(results, threshold)
    n = numel(results); overlapFrac = NaN(1,n-1); centroidShift = NaN(1,n-1);
    for k = 2:n
        BW_prev = logical(readASC(results(k-1).filename)>threshold);
        BW_curr = logical(readASC(results(k).filename)>threshold);
        BW_prev(isnan(BW_prev))=0; BW_curr(isnan(BW_curr))=0;
        intersection=sum(BW_prev & BW_curr,'all'); unionArea=sum(BW_prev | BW_curr,'all');
        overlapFrac(k-1) = intersection/unionArea;
        dx=results(k).fluxWeightedCentroidX-results(k-1).fluxWeightedCentroidX;
        dy=results(k).fluxWeightedCentroidY-results(k-1).fluxWeightedCentroidY;
        centroidShift(k-1)=sqrt(dx^2+dy^2);
    end
end

function [overlapFrac, centroidShift] = computeFootprintOverlap_noThreshold(results)
    n = numel(results); overlapFrac = NaN(1,n-1); centroidShift = NaN(1,n-1);
    for k = 2:n
        BW_prev = ~isnan(readASC(results(k-1).filename));
        BW_curr = ~isnan(readASC(results(k).filename));
        intersection=sum(BW_prev & BW_curr,'all'); unionArea=sum(BW_prev | BW_curr,'all');
        overlapFrac(k-1) = intersection/unionArea;
        dx=results(k).fluxWeightedCentroidX-results(k-1).fluxWeightedCentroidX;
        dy=results(k).fluxWeightedCentroidY-results(k-1).fluxWeightedCentroidY;
        centroidShift(k-1)=sqrt(dx^2+dy^2);
    end
end
