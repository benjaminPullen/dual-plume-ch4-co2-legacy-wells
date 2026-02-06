function data = add_equiv_fluxes(data)
% add_equiv_fluxes Adds CO₂e and CH₄e flux columns (20-year horizon)
%   Input:  data (table) with variables "CH4_Flux" and "CO2_Flux"
%   Output: same table with added columns "CO2e_Flux" and "CH4e_Flux"

    % Background thresholds (mean + 3*std)
    bg_data = readtable("spring25_backgroundFluxes_continuous.xlsx");
    ch4_threshold = mean(bg_data.CH4_Flux,'omitnan') + 3*std(bg_data.CH4_Flux,'omitnan');
    co2_threshold = mean(bg_data.CO2_Flux,'omitnan') + 3*std(bg_data.CO2_Flux,'omitnan');
    GWP20_CH4 = 83;     % GWP20 of CH4 (fossil, IPCC AR6)
    GWP20_CO2 = 1;      % GWP20 of CO2

    % --- Subtract background ---
    CH4_excess = data.CH4_Flux - ch4_threshold;
    CO2_excess = data.CO2_Flux - co2_threshold;

    % Ensure no negative values (set to zero)
    CH4_excess(CH4_excess < 0) = 0;
    CO2_excess(CO2_excess < 0) = 0;

    % --- Convert to CO2-equivalents ---
    CO2e_flux = CH4_excess .* GWP20_CH4 + CO2_excess .* GWP20_CO2;

    % --- Convert to CH4-equivalents ---
    % Divide the CO2e flux by the GWP of methane
    CH4e_flux = CO2e_flux ./ GWP20_CH4;

    % --- Add to table ---
    data.CO2e_Flux = CO2e_flux;
    data.CH4e_Flux = CH4e_flux;
end