function light_events = detect_light_events(data_table, params)
% function light_events = detect_light_events(data_table, params)
%
% Detect light events from the data in data_table, by assuming that an
% event with params.light_threshold_std * the standard deviation above the
% mean of the signal which occurs simultaneously in all signals is a light
% event.
%
% Inputs:
%   - data_table: table with Time in the first column and 2 or more signals
%                 in the columns 2:end
%   - params: struct with the field ligth_threshold_std set.
% Outputs:
%   - light_events: struct with the onset (in frames) of detected light
%                   events

variables = data_table.Variables;
time = variables(:,1);
data = variables(:,2:end);
light_threshold = mean(data, 1, 'omitnan') + params.light_threshold_std * std(data, 1, 'omitnan');
light_mask = false(size(time));
if size(data,2) > 1
    for i = 1:numel(time)
        light_mask(i) = all(data(i,:) > light_threshold);
    end
end
light_events = struct();
light_events.onset = find(light_mask);

end