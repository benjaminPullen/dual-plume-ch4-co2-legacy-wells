function data = add_excess_fluxes(data)
% add_excess_fluxes Adds columns for excess CH4 and CO2 fluxes
%   Input:  data (table) with variables "CH4_Flux" and "CO2_Flux"
%   Output: same table with added columns "Excess_CH4" and "Excess_CO2"

    % Background thresholds (mean + 3*std)
    bg_data = readtable('spring25_backgroundFluxes_continuous.xlsx');
    ch4_threshold = mean(bg_data.CH4_Flux,'omitnan') + 3*std(bg_data.CH4_Flux,'omitnan');
    co2_threshold = mean(bg_data.CO2_Flux,'omitnan') + 3*std(bg_data.CO2_Flux,'omitnan');

    % --- Compute excess fluxes ---
    Excess_CH4 = data.CH4_Flux - ch4_threshold;
    Excess_CO2 = data.CO2_Flux - co2_threshold;

    % --- Ensure no negative values (set to zero) ---
    Excess_CH4(Excess_CH4 < 0) = 0;
    Excess_CO2(Excess_CO2 < 0) = 0;

    % --- Add to table ---
    data.Excess_CH4 = Excess_CH4;
    data.Excess_CO2 = Excess_CO2;
end