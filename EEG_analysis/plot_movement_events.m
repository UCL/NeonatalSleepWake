function fig = plot_movement_events(data_table, movement_events, light_events, params)
% function fig = plot_movement_events(data_table, movement_events, light_events, params)
%
% Plot time series and events detected from it by detect_movement_events.m
%
% Inputs:
%   - data_table: table with Time in the first column and 2 or more signals
%                 in the columns 2:end
%   - movement_events: struct with data on detected events. Produced by
%             detect_movement_events.m
%   - light_events: struct with onsets of detected light events. Produced
%                   by detect_light_events.
%   - params: Parameters from get_params_for_movement_time_series
% Outputs:
%   - fig: figure handle

variable_names = data_table.Properties.VariableNames;
n_variables = numel(variable_names) - 1;
fig = figure();
tiledlayout(n_variables, 1);
ax = [];
for ivar = 1:n_variables

    local_params = get_local_params(params, ivar, n_variables);
    varname = variable_names{ivar+1};
    ax(end+1) = nexttile;
    plot(data_table.Time, data_table.(varname),'.-')
    hold on
    threshold = mean(data_table.(varname), 'omitnan') ...
        + local_params.movement_threshold_std * std(data_table.(varname), 'omitnan');
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
    if numel(light_events.onset) > 0
        legend('Time series','Movement threshold','Movement event onset','Light event','Movement event',...
            'location','eastoutside');
    else
        legend('Time series','Movement threshold','Movement event onset','Movement event',...
            'location','eastoutside');
    end
end

linkaxes(ax,'x');

end