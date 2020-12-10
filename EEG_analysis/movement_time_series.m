% This script processes time series that contain pixel change rates
% processed from video clips. It detects movement events by the following
% criterion:
% - signal above 3 standard deviations of the mean with gaps of less than
%   1000ms below threshold in between 
% In addition, events that occurr simultaneously in each time series and
% are above 5 standard deviations

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
params.interval_limit = 100 * 1e-3;
params.period_after_end = 50 * 1e-3;
params.dt = mean(diff(data_table.Time), 'omitnan');
%% Detect light events
light_events = detect_light_events(data_table, params);
%% Detect movement events
movement_events = detect_movement_events(data_table, params, light_events);
%% Mark events on time series
plot_movement_events(data_table, movement_events, light_events, params);