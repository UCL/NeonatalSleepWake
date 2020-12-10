function stats = movement_event_statistics(data_table, events, visualize)

stats = struct();

variable_names = data_table.Properties.VariableNames;
for iname = 2:numel(variable_names)
    varname = variable_names{iname};
        
    max_duration = max(events.(varname).duration_frames);
    t = (1:max_duration) * events.(varname).dt;
    signal = NaN(max_duration,events.(varname).n_events);
    
    data = data_table.(varname);
    
    for ievent = 1:events.(varname).n_events
       
        signal(1:events.(varname).duration_frames(ievent),ievent) = ...
            data(events.(varname).onset(ievent):events.(varname).offset(ievent));
    
    end

    stats.(varname).signal = signal;
    stats.(varname).median = median(signal, 2, 'omitnan');
    stats.(varname).mean = mean(signal, 2, 'omitnan');
    stats.(varname).p25 = prctile(signal,25,2);
    stats.(varname).p75 = prctile(signal,75,2);

    if visualize
        figure;
        plot(t,signal, 'b')
        hold on
        plot(t,stats.(varname).median, 'r', 'linewidth',2)
        plot(t,stats.(varname).p25, 'r--', 'linewidth', 2)
        plot(t,stats.(varname).p75, 'r--', 'linewidth', 2)
        title(varname)
        xlabel('time (s)')
        ylabel('pixel change')
    end
end

end