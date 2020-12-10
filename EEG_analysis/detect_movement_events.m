function movement_events = detect_movement_events(data_table, params, light_events)

movement_events = struct();

variable_names = data_table.Properties.VariableNames;
n_variables = numel(variable_names) - 1;
interval_limit_frames = round(params.interval_limit/params.dt);

% Set mask for filtering out light events
light_mask = false(size(data_table.Time));
light_mask(light_events.onset) = true;

for ivar = 1:n_variables
    varname = variable_names{ivar+1};
    data = data_table.(varname);
    movement_threshold = mean(data, 'omitnan') ...
        + params.movement_threshold_std * std(data, 'omitnan');
    events = find(data(2:end) > movement_threshold & ...
        data(1:end-1) < movement_threshold) + 1;
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
        
        duration_mask(ievent) = duration_frames(ievent) * params.dt >= params.duration_limit;
        to_mask(ievent) = frames_to_next_event * params.dt >= params.interval_limit;
        from_mask(ievent) = frames_from_previous_event * params.dt >= params.interval_limit;
        
    end
    
    % Include events that have (sufficient duration OR insufficient time to
    % next event) AND sufficient time from previous event AND are not light
    % events
    mask = (duration_mask | ~to_mask) & from_mask & ~light_mask(events);
    movement_events.(varname).n_events = sum(mask);
    movement_events.(varname).onset = events(mask);
    movement_events.(varname).duration_frames = duration_frames(mask);
    movement_events.(varname).duration_s = duration_frames(mask) * params.dt;
    movement_events.(varname).offset = events(mask) ...
        + duration_frames(mask) + round(params.period_after_end / params.dt);
end

end