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
addOptional(params, 'linkaxes', true, @(x) islogical(x));
addOptional(params, 'normalize', true, @(x) islogical(x));
addOptional(params, 'verbose', true, @(x) islogical(x));
parse(params, varargin{:});

stats = struct();

variable_names = data_table.Properties.VariableNames;
if params.Results.visualize
    fig = figure;
    tiledlayout(numel(variable_names)-1, 1)
    ax = [];
end
for iname = 2:numel(variable_names)

    varname = variable_names{iname};

    if events.(varname).n_events == 0
        continue
    end

    if params.Results.verbose

        movement_rate = events.(varname).n_events / ...
            (max(events.(varname).offset) * events.(varname).dt / 3600);
        avg_duration = mean(events.(varname).duration_s);
        min_duration = min(events.(varname).duration_s);
        max_duration = max(events.(varname).duration_s);

        disp([])
        disp(['Series name: ' varname])
        disp(['  Average movements/hour: ' num2str(movement_rate)])
        disp(['  Average movement duration (s): ' num2str(avg_duration)])
        disp(['  Min movement duration (s): ' num2str(min_duration)])
        disp(['  Max movement duration (s): ' num2str(max_duration)])

    end

    baseline_frames = round(params.Results.baseline / events.(varname).dt);
    max_duration = max(events.(varname).duration_frames + 2 * baseline_frames);
    t = (1:max_duration) * events.(varname).dt - params.Results.baseline;
    signal = NaN(max_duration,events.(varname).n_events);

    data = data_table.(varname);

    for ievent = 1:events.(varname).n_events
        ibeg = max(1, events.(varname).onset(ievent)-baseline_frames);
        iend = min(numel(data), events.(varname).offset(ievent)+baseline_frames);
        signal(1:iend-ibeg+1,ievent) = data(ibeg:iend);

        % Normalize the duration of all events to the duration of the
        % longest event. The event signal is interpolated linearly to have
        % the correct number of data points. The baseline time is not
        % included in the interpolation to keep the event onset at t = 0.
        % Since each event has the same length basline, it can just be kept
        % as it is.
        if params.Results.normalize

            i1 = baseline_frames + 1;
            i2 = iend - ibeg + 1 - baseline_frames;

            % Handle overflowing the ends of the time series separately
            if events.(varname).onset(ievent) - baseline_frames < 1
                i1 = events.(varname).onset(ievent);
            end
            if events.(varname).offset(ievent) + baseline_frames > numel(data)
                i2 = iend - ibeg + 1 - (numel(data) - events.(varname).offset(ievent));
            end

            x = i1:i2;
            v = signal(i1:i2,ievent);
            xq = linspace(i1,x(end),max_duration-baseline_frames);
            signal(baseline_frames + 1:end,ievent) = interp1(x,v,xq,'linear');

        end

    end

    stats.(varname).signal = signal;
    stats.(varname).median = median(signal, 2, 'omitnan');
    stats.(varname).mean = mean(signal, 2, 'omitnan');
    stats.(varname).p25 = prctile(signal,25,2);
    stats.(varname).p75 = prctile(signal,75,2);
    stats.(varname).stderr = std(signal, 0, 2, 'omitnan') / sqrt(events.(varname).n_events);

    if params.Results.visualize
        ax(end+1) = nexttile;
        hold on
        % Plot the median as a red line
        plot(t,stats.(varname).median, 'r', 'linewidth',2)
        % Plot +- standarad error as a red shaded area
        fill([t,fliplr(t)],...
            [stats.(varname).median - stats.(varname).stderr; ...
            flipud(stats.(varname).median + stats.(varname).stderr)], ...
            'r','facealpha',0.25,'edgecolor','r')
        t0 = max(t) - baseline_frames * events.(varname).dt;
        % Plot a gray shaded area over the baseline time before and after
        % the event
        patch([min(xlim), 0, 0, min(xlim)],...
            [min(ylim), min(ylim), max(ylim), max(ylim)],...
            'k','facealpha',0.2,'edgecolor','none')
        try
        patch([t0, max(t), max(t), t0],...
            [min(ylim), min(ylim), max(ylim), max(ylim)],...
            'k','facealpha',0.2,'edgecolor','none')
        catch
            keyboard
        end

        if params.Results.normalize
            xlabel('duration (normalized)')
        else
            xlabel('time (s)')
        end
        ylabel('pixel change')
        title(varname)
        grid on
        box on
        axis tight
    end
end

if params.Results.visualize && params.Results.linkaxes
    linkaxes(ax,'x')
end

end
