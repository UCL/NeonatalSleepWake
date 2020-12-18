%% Run tests
runtests('test_movement_time_series.m')
%% Get file names for I/O
[in_file_names,in_path_name] = uigetfile('*.csv','Select input files','multiselect','on');
%[out_file_name,out_path_name] = uiputfile('*.mat','Select output file','eeg_periodicity.mat');
if ~iscell(in_file_names)
    in_file_names = {in_file_names};
end
%% Set parameters
params = get_params_for_movement_time_series(true);
params.dt = mean(diff(data_table.Time), 'omitnan');
%%
master_table = table();
for ifile = 1:numel(in_file_names)
    %% Read time series
    filename = in_file_names{ifile};
    full_table = readtable([in_path_name,filename]);
    % Filter out non-numeric columns
    % Go backwards to stop indices from going out of bounds
    for i = numel(full_table.Properties.VariableNames):-1:2
        var = full_table.Properties.VariableNames{i};
        if ~isnumeric(full_table.(var)) || ~all(isfinite(full_table.(var)))
            full_table.(var) = [];
        end
    end
    %% Process data table
    [data_table, data_table_ctrl, ~] = split_control_columns(full_table);
    assert(isequal(data_table.Properties.VariableNames, master_table.Properties.VariableNames) ||...
        isempty(master_table), ...
        'Labels of non-control columns must be equal in all input files')
    %% Append to master table
    master_table = [master_table;data_table];
end
%% Detect light events
light_events = detect_light_events(master_table, params);
%% Detect movement events
movement_events = detect_movement_events(master_table, params, light_events);
%% Do statistics and visualise
movement_event_statistics(master_table, movement_events,...
     'baseline',1.0,'visualize',true,'normalize',true,'verbose',true);