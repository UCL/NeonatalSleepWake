function stats = movement_event_statistics(data_table, events, varargin)
% function stats = movement_event_statistics(data_table, events, varargin)
%
% Calculate statistics over a set of events detected by
% movement_time_series.m. By default the median and the mean are calculated
% but others can be added.
% Inputs:
%   - data_table: table with Time in the first column and 2 or more signals
%                 in the columns 2:end
%   - events: struct with data on detected events. Produced by
%             detect_movement_events.m
%   Optional:
%     - visualize (default true): plot the result
%     - baseline (default 1.0): period of time added before the event onset
%     - normalize (default false): normalize all events to unit duration
% Outputs:
%   - stats: struct with the analyzed event signals and the computed
%            statistics

params = inputParser;
addOptional(params, 'baseline', 1.0, @(x) isnumeric(x) && x >= 0);
addOptional(params, 'visualize', true, @(x) islogical(x));
addOptional(params, 'normalize', false, @(x) islogical(x));
parse(params, varargin{:});

stats = struct();

variable_names = data_table.Properties.VariableNames;
if params.Results.visualize
    fig = figure;
end
for iname = 2:numel(variable_names)
    varname = variable_names{iname};
    baseline_frames = round(params.Results.baseline / events.(varname).dt);
    max_duration = max(events.(varname).duration_frames + baseline_frames);
    t = (1:max_duration) * events.(varname).dt - params.Results.baseline;
    signal = NaN(max_duration,events.(varname).n_events);

    data = data_table.(varname);

    for ievent = 1:events.(varname).n_events
        ibeg = max(1, events.(varname).onset(ievent)-baseline_frames);
        iend = min(numel(data), events.(varname).offset(ievent));
        signal(1:iend-ibeg+1,ievent) = data(ibeg:iend);

        if params.Results.normalize

            x = baseline_frames:iend-ibeg+1;
            v = signal(baseline_frames:iend-ibeg+1,ievent);
            xq = linspace(baseline_frames,x(end),max_duration-baseline_frames);
            signal(baseline_frames+1:end,ievent) = interp1(x,v,xq,'linear');

        end

    end

    stats.(varname).signal = signal;
    stats.(varname).median = median(signal, 2, 'omitnan');
    stats.(varname).mean = mean(signal, 2, 'omitnan');
    stats.(varname).p25 = prctile(signal,25,2);
    stats.(varname).p75 = prctile(signal,75,2);
    stats.(varname).stderr = std(signal, 0, 2, 'omitnan') / sqrt(events.(varname).n_events);

    if params.Results.visualize
        subplot(numel(variable_names)-1, 1, iname-1);
        %plot(t,signal, 'b')
        hold on
        plot(t,stats.(varname).median, 'r', 'linewidth',2)
        fill([t,fliplr(t)],...
            [stats.(varname).median - stats.(varname).stderr; ...
            flipud(stats.(varname).median + stats.(varname).stderr)], ...
            'r','facealpha',0.25,'edgecolor','r')
        title(varname)
        if params.Results.normalize
            xlabel('duration (normalized)')
        else
            xlabel('time (s)')
        end
        ylabel('pixel change')
    end
end

end
