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
params.interval_limit = 1000 * 1e-3;
params.period_after_end = 500 * 1e-3;
params.dt = mean(diff(data_table.Time), 'omitnan');
%% Detect light events
light_events = detect_light_events(data_table, params);
%% Detect movement events
movement_events = detect_movement_events(data_table, params, light_events);
%% Mark events on time series
for iname = 2:numel(variable_names)
    yname = variable_names{iname};
    figure()
    clf;
    plot(data_table.Time, data_table.(yname),'.-')
    hold on
    threshold = mean(data_table.(yname), 'omitnan') ...
        + movement_threshold_std * std(data_table.(yname), 'omitnan');
    plot(data_table.Time, ones(size(data_table,1),1) * threshold, 'r--')
    plot(data_table.Time(movement_events.(yname).onset), ...
        data_table.(yname)(movement_events.(yname).onset), 'ro', 'markersize',10,'linewidth',2)
    plot(data_table.Time(light_events.onset), ...
        data_table.(yname)(light_events.onset), 'm*', 'markersize',10,'linewidth',2)
    for i = 1:movement_events.(yname).n_events
        ibeg = max(1,movement_events.(yname).onset(i) - 1);
        iend = min(numel(data_table.Time), movement_events.(yname).offset(i));
        area(data_table.Time(ibeg:iend), data_table.(yname)(ibeg:iend), ...
            'edgecolor','none','facecolor','r','facealpha',0.5)
    end
    xlabel('Time (s)')
    ylabel('Change in pixel intensity')
    title(yname)
    legend('Time series','Movement threshold','Movement event onset','Light event','Movement event')
end
%% Plot events one by one
% figure()
% clf;
% yname = variable_names{2};
% for i = 1:movement_events.(yname).n_events
%     ibeg = max(movement_events.(yname).onset(i)-1,1);
%     iend = min(movement_events.(yname).offset(i)+1,numel(data_table.(yname)));
%     subplot(movement_events.(yname).n_events,1,i)
%     plot(data_table.Time(ibeg:iend), data_table.(yname)(ibeg:iend),'.-')
%     hold on
%     threshold = mean(data_table.(yname), 'omitnan') + movement_threshold_std * std(data_table.(yname), 'omitnan');
%     plot(data_table.Time(ibeg:iend), ones(size(ibeg:iend)) * threshold, 'r--')
% end
