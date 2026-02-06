function results = convert_flux_volume(volume_umol_s, gasType)
% convert_flux_volume Convert Surfer "volume under surface" to emissions
%
% INPUTS:
%   volume_umol_s - integrated surface [µmol/s]
%   gasType       - 'CH4' or 'CO2' (case insensitive)
%
% OUTPUT:
%   results - struct with fields:
%       mol_per_s       - mol/s of input gas
%       g_per_day       - g/day of input gas
%       kg_per_day      - kg/day of input gas
%       tonnes_per_year - tonnes/year of input gas
%       CH4e_per_day    - kg/day CH4e (20-yr horizon)
%       CH4e_per_year   - tonnes/year CH4e (20-yr horizon)
%       CO2e_per_day    - kg/day CO2e (20-yr horizon)
%       CO2e_per_year   - tonnes/year CO2e (20-yr horizon)

    % --- Constants ---
    MW_CH4 = 16;                 % g/mol
    MW_CO2 = 44;                 % g/mol
    GWP20_CH4 = 83;              % IPCC AR6 fossil CH4
    GWP20_CO2 = 1;               % CO2 baseline
    sec_per_day = 86400;
    days_per_year = 365;

    % --- Convert input volume to mol/s ---
    mol_per_s = volume_umol_s / 1e6;

    % --- Determine molecular weight ---
    switch lower(gasType)
        case 'ch4'
            MW = MW_CH4;
        case 'co2'
            MW = MW_CO2;
        otherwise
            error('gasType must be ''CH4'' or ''CO2''');
    end

    % --- Mass flows ---
    g_per_day = mol_per_s * MW * sec_per_day;
    kg_per_day = g_per_day / 1000;
    tonnes_per_year = g_per_day * days_per_year / 1e6;

    % --- Convert to CH4e (20-year horizon) ---
    if strcmpi(gasType, 'ch4')
        % CH4 direct equivalence
        CH4e_per_day = kg_per_day;
        CH4e_per_year = tonnes_per_year;
        % For CO2e: multiply CH4 mass by GWP20(CH4)
        g_per_day_CO2e = g_per_day * GWP20_CH4;
    else
        % CO2 to CH4e using GWP ratio
        CO2e_to_CH4e = (MW_CH4/MW_CO2) / GWP20_CH4;
        g_per_day_CH4e = g_per_day * CO2e_to_CH4e;
        CH4e_per_day = g_per_day_CH4e / 1000;
        CH4e_per_year = g_per_day_CH4e * days_per_year / 1e6;
        % For CO2e: CO2 is baseline, 1 g = 1 g CO2e
        g_per_day_CO2e = g_per_day * GWP20_CO2;
    end

    % --- CO2e results ---
    CO2e_per_day = g_per_day_CO2e / 1000;
    CO2e_per_year = g_per_day_CO2e * days_per_year / 1e6;

    % --- Package results ---
    results.mol_per_s = mol_per_s;
    results.g_per_day = g_per_day;
    results.kg_per_day = kg_per_day;
    results.tonnes_per_year = tonnes_per_year;
    results.kg_CH4e_per_day = CH4e_per_day;
    results.tonnes_CH4e_per_year = CH4e_per_year;
    results.kg_CO2e_per_day = CO2e_per_day;
    results.tonnes_CO2e_per_year = CO2e_per_year;
end