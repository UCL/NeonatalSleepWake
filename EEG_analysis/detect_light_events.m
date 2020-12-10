function light_events = detect_light_events(data_table, params)

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