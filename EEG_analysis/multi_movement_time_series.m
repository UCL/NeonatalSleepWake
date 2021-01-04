% This script processes multiple time series that contain pixel change
% rates processed from video clips. It detects movement events and light
% events. It then plots the median of all events normalized to the same
% start and end time, and displays statistical information about the events.
%% Run tests
runtests('test_movement_time_series.m')
%% Get file names for I/O
[in_file_names,in_path_name] = uigetfile('*.csv','Select input files','multiselect','on');
%[out_file_name,out_path_name] = uiputfile('*.mat','Select output file','eeg_periodicity.mat');
if ~iscell(in_file_names)
    in_file_names = {in_file_names};
end
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
    [data_table, master_table] = merge_tables(data_table, master_table);
    %% Append to master table
    master_table = [master_table;data_table];
end
%% Set parameters
params = get_params_for_movement_time_series(true);
params.dt = median(diff(master_table.Time));
%% Detect light events
light_events = detect_light_events(master_table, params);
%% Detect movement events
movement_events = detect_movement_events(master_table, params, light_events);
%% Do statistics and visualise
movement_event_statistics(master_table, movement_events,...
     'baseline',1.0,'visualize',true,'normalize',true,'verbose',true,'linkaxes',true);