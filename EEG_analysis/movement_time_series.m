% This script processes time series that contain pixel change rates
% processed from video clips. It detects movement events and light events,
% plots them, and displays statistical information about detected events.

%% Run tests
runtests('test_movement_time_series.m')
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
%% Set parameters
params = get_params_for_movement_time_series(true);
params.dt = mean(diff(data_table.Time), 'omitnan');
%% Detect light events
light_events = detect_light_events(data_table, params);
%% Detect movement events
movement_events = detect_movement_events(data_table, params, light_events);
if ~isempty(control_table)
    movement_events_ctrl = detect_movement_events(data_table_ctrl, params, light_events);
end
%% Mark events on time series
plot_movement_events(data_table, movement_events, light_events, params);
if ~isempty(control_table)
    plot_movement_events(data_table_ctrl, movement_events_ctrl, light_events, params);
end
%% Do statistics and visualise
movement_event_statistics(data_table, movement_events,...
    'baseline',1.0,'visualize',true,'normalize',true,'verbose',true,true,'linkaxes',true);
if ~isempty(control_table)
    movement_event_statistics(data_table_ctrl, movement_events_ctrl,...
        'baseline',1.0,'visualize',true,'normalize',true,'verbose',true,'linkaxes',true);
end
%% Export events
eeglab_movement_events = convert_events(movement_events);
eeg = pop_loadset();
eeg = pop_importevent(eeg,'event',eeglab_movement_events,...
    'fields',{'type','latency','duration'},'append','yes');
eeg.event_detection_parameters = params;
%% Save output
[out_file_name,out_path_name] = uiputfile('*.set','Select output file',...
    [eeg.setname '_movement.set']);
pop_saveset(eeg,'savemode','twofiles',...
    'filename',out_file_name,...
    'filepath',out_path_name);