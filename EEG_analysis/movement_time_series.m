% This script processes time series that contain pixel change rates
% processed from video clips. It detects movement events and light events,
% plots them, and displays statistical information about detected events.

%% Run tests
runtests('test_movement_time_series.m')
%% Read time series
[filename,pathname] = uigetfile('*.csv');
data_table = readtable([pathname,filename]);
%% Set parameters
params = struct();
params.movement_threshold_std = 3;
params.light_threshold_std = 5;
params.duration_limit = 40 * 1e-3;
params.interval_limit = 1000 * 1e-3;
params.period_after_end = 500 * 1e-3;
params.dt = mean(diff(data_table.Time), 'omitnan');
%% Detect light events
light_events = detect_light_events(data_table, params);
%% Detect movement events
movement_events = detect_movement_events(data_table, params, light_events);
%% Mark events on time series
plot_movement_events(data_table, movement_events, light_events, params);
%% Do statistics and visualise
movement_event_statistics(data_table, movement_events, true);