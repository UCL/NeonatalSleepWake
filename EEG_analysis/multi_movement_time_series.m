%% Run tests
runtests('test_movement_time_series.m')
%%
read_more = true;
while read_more
    %% Read time series
    [filename,pathname] = uigetfile('*.csv');
    full_table = readtable([pathname,filename]);
    % Filter out non-numeric columns
    % Go backwards to stop indices from going out of bounds
    for i = numel(full_table.Properties.VariableNames):-1:2
        var = full_table.Properties.VariableNames{i};
        if ~isnumeric(full_table.(var)) || ~all(isfinite(full_table.(var)))
            full_table.(var) = [];
        end
    end
    %% Process data table
    [data_table, data_table_ctrl, control_table] = split_control_columns(full_table);
    %% Append to master table
    
end
%% Set parameters
params = get_params_for_movement_time_series(true);
params.dt = mean(diff(data_table.Time), 'omitnan');
%% Do statistics and visualise
movement_event_statistics(data_table, movement_events);
if ~isempty(control_table)
    movement_event_statistics(data_table_ctrl, movement_events_ctrl);
