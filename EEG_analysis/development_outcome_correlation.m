% This script compares baby development outcome data with the results of
% EEG periodicity analysis performed by the eeg_visualizations.m or
% eeg_batch.m scripts. The development outcome data is read in from an
% MS excel file. The outputs are collected in a table that can be written
% out as an MS excel file at the end of the script execution.
%% Read excel table
[filename,pathname] = uigetfile('*.xls*');
full_table = readtable([pathname,filename], 'UseExcel', true);
outcome_table = full_table(:,{'BRUK','Shankaran_num','Cog','Lang_interp','Motor_interpolated'});
%% Read data from eeg_visualisations
uiopen('load');
%% Add columns for period and amplitude to the table
n = size(outcome_table,1);
% Find unique channel names
c = extractfield(eeg_periodicity_data,'channels');
unique_channels = unique(cat(2,c{:}));
% Create columns for each data field
outcome_table.deleted_fraction = NaN(n,1);
for i = 1:numel(unique_channels)
    channel = unique_channels{i};
    outcome_table.([channel, '_period']) = NaN(n,1);
    outcome_table.([channel, '_amplitude']) = NaN(n,1);
    outcome_table.([channel, '_r_powerN_sparsity']) = NaN(n,1);
    outcome_table.([channel, '_p_powerN_sparsity']) = NaN(n,1);
    outcome_table.([channel, '_mean_powerN']) = NaN(n,1);
    outcome_table.([channel, '_median_powerN']) = NaN(n,1);
end

for i = 1:numel(eeg_periodicity_data)
    data = eeg_periodicity_data(i);
    for j = 1:data.nchannels
        channel = data.channels{j};
        field_p = [channel,'_period'];
        field_a = [channel,'_amplitude'];
        field_rcoeff = [channel,'_r_powerN_sparsity'];
        field_pcoeff = [channel,'_p_powerN_sparsity'];
        field_pmean = [channel,'_mean_powerN'];
        field_pmedian = [channel,'_median_powerN'];
        outcome_table.(field_p)(outcome_table.BRUK == data.BRUK) = hours(data.period(j));
        outcome_table.(field_a)(outcome_table.BRUK == data.BRUK) = data.amplitude(j);
        outcome_table.(field_rcoeff)(outcome_table.BRUK == data.BRUK) = data.corrcoef_r(j);
        outcome_table.(field_pcoeff)(outcome_table.BRUK == data.BRUK) = data.corrcoef_p(j);
        outcome_table.(field_pmean)(outcome_table.BRUK == data.BRUK) = data.mean_power(j);
        outcome_table.(field_pmedian)(outcome_table.BRUK == data.BRUK) = data.median_power(j);
    end
    outcome_table.deleted_fraction(outcome_table.BRUK == data.BRUK) = data.deleted_fraction;
end
%% TODO: Get correlation coefficients
% [ ] Ignore NaN's with corrcoef(X,Y,'rows','complete')

%%
[out_file_name,out_path_name] = uiputfile('*.xlsx','Select output file','outcome_table.xlsx');
if out_file_name ~= 0
    writetable(outcome_table,[out_path_name,out_file_name])
end

