%% Run tests
runtests('test_movement_time_series.m')
%% Read time series
[filename,pathname] = uigetfile('*.csv');
data_table = readtable([pathname,filename]);
%% Set parameters
movement_threshold_std = 3;
light_threshold_std = 5;
duration_limit = 40 * 1e-3;
interval_limit = 1000 * 1e-3;
period_after_end = 500 * 1e-3;
dt = mean(diff(data_table.Time), 'omitnan');
%% Detect light events
variables = data_table.Variables;
time = variables(:,1);
data = variables(:,2:end);
light_threshold = mean(data, 1, 'omitnan') + light_threshold_std * std(data, 1, 'omitnan');
light_mask = false(size(time));
for i = 1:numel(time)
    light_mask(i) = all(data(i,:) > light_threshold);
end
light_events = struct();
light_events.onset = find(light_mask);
%% Detect movement events
variable_names = data_table.Properties.VariableNames;
n_variables = numel(variable_names) - 1;
movement_events = struct();
interval_limit_frames = round(interval_limit/dt);
for ivar = 1:n_variables
    varname = variable_names{ivar+1};
    data = data_table.(varname);
    movement_threshold = mean(data, 'omitnan') + movement_threshold_std * std(data, 'omitnan');
    events = find(data(2:end) > movement_threshold & data(1:end-1) < movement_threshold) + 1;
    duration_mask = false(size(events));
    to_mask = false(size(events));
    from_mask = false(size(events));
    duration_frames = zeros(size(events));

    for ievent = 1:numel(events)
        duration_frames(ievent) = event_duration(data, movement_threshold, ...
            interval_limit_frames, events(ievent));
        
        if ievent + duration_frames(ievent) < numel(events)
            next_event = events(ievent + duration_frames(ievent));
        else
            next_event = intmax;
        end
        frames_to_next_event = next_event - events(ievent);
        
        if ievent > 1
            frames_from_previous_event = events(ievent) - ...
                (events(ievent-1) + duration_frames(ievent-1));
        else
            frames_from_previous_event = intmax;
        end
        
        duration_mask(ievent) = duration_frames(ievent) * dt >= duration_limit;
        to_mask(ievent) = frames_to_next_event * dt >= interval_limit;
        from_mask(ievent) = frames_from_previous_event * dt >= interval_limit;
        
    end
    
    % Include events that have (sufficient duration OR insufficient time to
    % next event) AND sufficient time from previous event AND are not light
    % events
    mask = (duration_mask | ~to_mask) & from_mask & ~light_mask(events);
    movement_events.(varname).n_events = sum(mask);
    movement_events.(varname).onset = events(mask);
    movement_events.(varname).duration_frames = duration_frames(mask);
    movement_events.(varname).duration_s = duration_frames(mask) * dt;
    movement_events.(varname).offset = events(mask) ...
        + duration_frames(mask) + round(period_after_end / dt);
end
%% Mark events on time series
figure(1)
clf;
yname = variable_names{2};
plot(data_table.Time, data_table.(yname),'.-')
hold on
threshold = mean(data_table.(yname), 'omitnan') + movement_threshold_std * std(data_table.(yname), 'omitnan');
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
%% Plot events one by one
% figure(2)
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
