function fig = plot_movement_events(data_table, movement_events, light_events, params)

variable_names = data_table.Properties.VariableNames;
for iname = 2:numel(variable_names)
    yname = variable_names{iname};
    fig = figure();   
    plot(data_table.Time, data_table.(yname),'.-')
    hold on
    threshold = mean(data_table.(yname), 'omitnan') ...
        + params.movement_threshold_std * std(data_table.(yname), 'omitnan');
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

end