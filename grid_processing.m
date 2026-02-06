%% ----------------- Processing Surfer Grids -----------------
% Author: Benjamin Pullen
% Date: 11/09/2025

clear; close all; clc;

%% ------------------ User Inputs ------------------
co2_files = {
    'SS1_CO2_NATN_RAW.asc', 'SS2_CO2_NATN_RAW.asc', 'SS4_CO2_NATN_RAW.asc',...
    'SS5_CO2_NATN_RAW.asc', 'SS6_CO2_NATN_RAW.asc'};
ch4_files = {
    'SS1_CH4_NATN_RAW.asc', 'SS2_CH4_NATN_RAW.asc',...
    'SS4_CH4_NATN_RAW.asc', 'SS5_CH4_NATN_RAW.asc', 'SS6_CH4_NATN_RAW.asc'};

% Background thresholds (mean + 3*std)
bg_data = readtable("spring25_backgroundFluxes_continuous.xlsx");
co2_threshold = mean(bg_data.CO2_Flux,'omitnan') + 3*std(bg_data.CO2_Flux,'omitnan');
ch4_threshold = mean(bg_data.CH4_Flux,'omitnan') + 3*std(bg_data.CH4_Flux,'omitnan');

%% ------------------ Run Analysis ------------------
co2_results = processFluxFiles(co2_files, co2_threshold);
ch4_results = processFluxFiles(ch4_files, ch4_threshold);

%% ------------------ Day-to-Day Footprint Overlap ------------------
[co2_overlap, co2_disp] = computeFootprintOverlap(co2_results, co2_threshold);
[ch4_overlap, ch4_disp] = computeFootprintOverlap(ch4_results, ch4_threshold);

%% ------------------ Panel Figure (a–f) ------------------
figure('Color','w','Units','centimeters','Position',[2 2 28 18]);

% Colours
co2_color = [0 0.45 0.74];    % blue
ch4_color = [0.85 0.33 0.10]; % orange

commonFontSize = 12;                              
markerSize = 7;       
lineW = 1.8;          

%% (a) Footprint Area
ax1 = subplot(2,3,1); hold on;
plot(ax1, 1:numel(co2_results), [co2_results.area], '-o','Color',co2_color,'LineWidth',lineW,'MarkerSize',markerSize);
plot(ax1, 1:numel(ch4_results), [ch4_results.area], '-s','Color',ch4_color,'LineWidth',lineW,'MarkerSize',markerSize);
set(ax1,'YScale','linear'); ylim([0.1 max([ [co2_results.area],[ch4_results.area] ])*1.2]);
xlabel(ax1,'Survey Number'); ylabel(ax1,'Area (m²)'); %title(ax1,'(a) Footprint Area');
legend(ax1,{'CO_{2}','CH_{4}'},'Location','best','FontSize',commonFontSize);
grid(ax1,'on'); set(ax1,'FontSize',commonFontSize,'LineWidth',1.2);

%% (b) Compactness
ax2 = subplot(2,3,2); hold on;
plot(ax2, 1:numel(co2_results), [co2_results.compactness], '-o','Color',co2_color,'LineWidth',lineW,'MarkerSize',markerSize);
plot(ax2, 1:numel(ch4_results), [ch4_results.compactness], '-s','Color',ch4_color,'LineWidth',lineW,'MarkerSize',markerSize);
xlabel(ax2,'Survey Number'); ylabel(ax2,'P²/4πA'); %title(ax2,'(b) Footprint Compactness');
legend(ax2,{'CO_{2}','CH_{4}'},'Location','best','FontSize',commonFontSize);
grid(ax2,'on'); set(ax2,'FontSize',commonFontSize,'LineWidth',1.2);

%% (c) Centroid Displacement Directions (Polar)
tempAx = subplot(2,3,3); pos = get(tempAx,'Position'); delete(tempAx);
pax = polaraxes('Position', pos); hold(pax,'on');

dx_co2 = diff([co2_results.fluxWeightedCentroidX]);
dy_co2 = diff([co2_results.fluxWeightedCentroidY]);
mag_co2 = sqrt(dx_co2.^2 + dy_co2.^2);
ang_co2 = mod(atan2d(dx_co2, dy_co2),360);

dx_ch4 = diff([ch4_results.fluxWeightedCentroidX]);
dy_ch4 = diff([ch4_results.fluxWeightedCentroidY]);
mag_ch4 = sqrt(dx_ch4.^2 + dy_ch4.^2);
ang_ch4 = mod(atan2d(dx_ch4, dy_ch4),360);

if isempty(mag_co2) && isempty(mag_ch4)
    text(0.5,0.5,'No displacement data','Units','normalized', ...
        'HorizontalAlignment','center','Parent',pax,'FontSize',commonFontSize,'Color',[0.4 0.4 0.4]);
else
    if ~isempty(mag_co2)
        polarplot(pax, deg2rad(ang_co2), mag_co2, '-o', ...
            'Color', co2_color,'MarkerFaceColor',co2_color, ...
            'LineWidth',lineW,'MarkerSize',markerSize);
    end
    if ~isempty(mag_ch4)
        polarplot(pax, deg2rad(ang_ch4), mag_ch4, '-s', ...
            'Color', ch4_color,'MarkerFaceColor',ch4_color, ...
            'LineWidth',lineW,'MarkerSize',markerSize);
    end
end

pax.ThetaZeroLocation = 'top'; pax.ThetaDir = 'clockwise';
pax.ThetaTick = [0 90 180 270]; pax.ThetaTickLabel = {'N','E','S','W'};
rmax = max([mag_co2(:); mag_ch4(:); eps]); pax.RLim = [0, rmax*1.2];
% Set radial ticks
pax.RTick = 0:0.5:rmax*1.2;

% Append ' m' to each tick label
pax.RTickLabel = arrayfun(@(x) sprintf('%.1f m',x), pax.RTick, 'UniformOutput',false);

%title(pax,'(c) Centroid Displacement Directions');
legend(pax,{'CO_{2}','CH_{4}'},'Location','best','FontSize',commonFontSize);
set(pax,'FontSize',commonFontSize,'LineWidth',1.2);

%% (d) Centroid Displacement
ax4 = subplot(2,3,4); hold on;
plot(ax4, 2:numel(co2_results), co2_disp,'-o','Color',co2_color,'LineWidth',lineW,'MarkerSize',markerSize);
plot(ax4, 2:numel(ch4_results), ch4_disp,'-s','Color',ch4_color,'LineWidth',lineW,'MarkerSize',markerSize);
xlabel(ax4,'Survey Number'); ylabel(ax4,'Displacement (m)'); %title(ax4,'(d) Centroid Displacement');
legend(ax4,{'CO_{2}','CH_{4}'},'Location','best','FontSize',commonFontSize);
grid(ax4,'on'); set(ax4,'FontSize',commonFontSize,'LineWidth',1.2);

%% (e) Day-to-Day Overlap (same species)
ax5 = subplot(2,3,5); hold on;
plot(ax5, 2:numel(co2_results), co2_overlap,'-o','Color',co2_color,'LineWidth',lineW,'MarkerSize',markerSize);
plot(ax5, 2:numel(ch4_results), ch4_overlap,'-s','Color',ch4_color,'LineWidth',lineW,'MarkerSize',markerSize);
ylim([0 1])
xlabel(ax5,'Survey Number'); ylabel(ax5,'Fractional Overlap'); %title(ax5,'(e) Day-to-Day Overlap');
legend(ax5,{'CO_{2}','CH_{4}'},'Location','best','FontSize',commonFontSize);
grid(ax5,'on'); set(ax5,'FontSize',commonFontSize,'LineWidth',1.2);

%% (f) CO₂–CH₄ Footprint Overlap
ax6 = subplot(2,3,6); hold on;
cross_overlap_co2inCH4 = NaN(1,numel(co2_results));
cross_overlap_ch4inCO2 = NaN(1,numel(ch4_results));
for k = 1:min(numel(co2_results),numel(ch4_results))
    BW_co2 = logical(readASC(co2_results(k).filename)>co2_threshold);
    BW_ch4 = logical(readASC(ch4_results(k).filename)>ch4_threshold);
    inter = sum(BW_co2 & BW_ch4,'all');
    cross_overlap_co2inCH4(k) = inter / sum(BW_co2,'all');
    cross_overlap_ch4inCO2(k) = inter / sum(BW_ch4,'all');
end
plot(ax6, 1:numel(cross_overlap_co2inCH4), cross_overlap_co2inCH4,'-o','Color',co2_color,'LineWidth',lineW,'MarkerSize',markerSize);
plot(ax6, 1:numel(cross_overlap_ch4inCO2), cross_overlap_ch4inCO2,'-s','Color',ch4_color,'LineWidth',lineW,'MarkerSize',markerSize);
xlabel(ax6,'Survey Number'); ylabel(ax6,'Fractional Overlap'); %title(ax6,'(f) CO₂–CH₄ Overlap');
legend(ax6,{'CO_{2} within CH_{4}','CH_{4} within CO_{2}'},'Location','best','FontSize',commonFontSize);
grid(ax6,'on'); set(ax6,'FontSize',commonFontSize,'LineWidth',1.2);

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

        % --- Flux-weighted centroid (center of mass of flux) ---
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


function info = readASCinfo(filename)
    fid=fopen(filename,'r'); info.ncols=sscanf(fgetl(fid),'ncols %d');
    info.nrows=sscanf(fgetl(fid),'nrows %d'); info.xllcorner=sscanf(fgetl(fid),'xllcorner %f');
    info.yllcorner=sscanf(fgetl(fid),'yllcorner %f'); info.cellsize=sscanf(fgetl(fid),'cellsize %f');
    info.nodata_value=sscanf(fgetl(fid),'nodata_value %f'); fclose(fid);
end

function grid = readASC(filename)
    fid = fopen(filename,'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    % Read header
    ncols = sscanf(fgetl(fid),'ncols %d');
    nrows = sscanf(fgetl(fid),'nrows %d');
    xllcorner = sscanf(fgetl(fid),'xllcorner %f');
    yllcorner = sscanf(fgetl(fid),'yllcorner %f');
    cellsize = sscanf(fgetl(fid),'cellsize %f');
    nodata = sscanf(fgetl(fid),'nodata_value %f');

    % Read grid values
    data = fscanf(fid, '%f', [ncols, nrows]);
    fclose(fid);

    if numel(data) ~= ncols*nrows
        error('Mismatch between header and grid size in %s', filename);
    end

    % Transpose to get [nrows x ncols]
    grid = data';
    
    % Replace NoData values with NaN
    grid(grid == nodata) = NaN;
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