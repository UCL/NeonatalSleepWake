function fig = plot_movement_events(data_table, movement_events, light_events, params)
% function fig = plot_movement_events(data_table, movement_events, light_events, params)
%
% Plot time series and events detected from it by detect_movement_events.m
%
% Inputs:
%  - data_table:
%  - movement_events:
%  - light_events:
%  - params:
% Outputs:
%   - fig: figure handle

fig = figure();
variable_names = data_table.Properties.VariableNames;
for iname = 2:numel(variable_names)
    varname = variable_names{iname};
    subplot(numel(variable_names)-1, 1, iname-1);
    plot(data_table.Time, data_table.(varname),'.-')
    hold on
    threshold = mean(data_table.(varname), 'omitnan') ...
        + params.movement_threshold_std * std(data_table.(varname), 'omitnan');
    plot(data_table.Time, ones(size(data_table,1),1) * threshold, 'r--')
    plot(data_table.Time(movement_events.(varname).onset), ...
        data_table.(varname)(movement_events.(varname).onset), 'ro', 'markersize',10,'linewidth',2)
    plot(data_table.Time(light_events.onset), ...
        data_table.(varname)(light_events.onset), 'm*', 'markersize',10,'linewidth',2)
    for i = 1:movement_events.(varname).n_events
        ibeg = max(1,movement_events.(varname).onset(i) - 1);
        iend = min(numel(data_table.Time), movement_events.(varname).offset(i));
        area(data_table.Time(ibeg:iend), data_table.(varname)(ibeg:iend), ...
            'edgecolor','none','facecolor','r','facealpha',0.5)
    end
    xlabel('Time (s)')
    ylabel('Change in pixel intensity')
    title(varname)
    legend('Time series','Movement threshold','Movement event onset','Light event','Movement event')
end

end