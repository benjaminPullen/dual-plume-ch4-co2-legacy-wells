% File
filename = 'spring25_spatialSurveys_ordered.xlsx';

% Sheet names
sheets = {'SS1','SS2','SS3','SS4','SS5','SS6'};

% Variables of interest
vars = {'CO2_Flux', 'CH4_Flux', 'Excess_CO2','Excess_CH4', 'CO2e_Flux', 'CH4e_Flux', };

% Preallocate storage (21 monitoring points × 3 variables × 6 sheets)
numSheets = numel(sheets) - 1;
numPoints = 21;
numVars = numel(vars);
allData = nan(numPoints, numVars, numSheets);

% Loop through each sheet
for i = 1:numSheets
    T = readtable(filename, 'Sheet', sheets{i});

    % Extract the three variables as numeric array
    allData(:,:,i) = T{1:numPoints, vars};
end

% Average across the 3rd dimension (sheets)
avgData = mean(allData, 3, 'omitnan');

% Turn into a table with monitoring point IDs
MP = (1:numPoints)'; % Monitoring point numbers
avgTable = array2table(avgData, 'VariableNames', vars);
avgTable.MP = MP;
avgTable = movevars(avgTable, 'MP', 'before', 1);