function fig = plot_events(events, field, channels_in)
% function fig = plot_events(events, field, channels_in)
%
% Plot burst durations by type of burst with latency on the x-axis
% Inputs:
%    - events: Struct with events by channel. Produced by process_bursts.m or
%          get_events_by_channel.m
%    - field: quantity to plot, supported options are
%            - 'duration'
%            - 'power'
%            - 'power_n'
%    - channels_in: string or cell array of channel names (usually found in
%                   eeg_data.chanlocs.labels)
% Outputs:
%    - fig: figure handle
%
% EXAMPLES:
% plot_events(set_filename,'duration','O2');
% plot_events(set_filename,'power',{'O2','C4'});

channels = format_channels(channels_in);

fig = figure();
clf;
hold on

ph = struct();

for i = 1:numel(channels)
    channel = channels{i};
    assert(any(strcmp(field,fieldnames(events.(channel)))), ...
        ['Field ',field,' not found in event data'])
    t = seconds(events.(channel).latency);
    ph.(channel) = stem(hours(t), events.(channel).(field));
end

legend(channels)
xlabel('Time (hours)')
ylabel([field,' [',events.(channel).(['unit_',field]),']'])
box on
grid on

xlim([0,24])
set(gca,'xtick',0:24)

% In general, the power of bursts at different regions is F<C<O<P. Change
% plotting order so that the smaller bursts, e.g. F, are always plotted at
% the front
order = fliplr('FCOP');
for i = 1:numel(order)
    channel_prefix = order(i);
    channel_ids = find(contains(channels,channel_prefix));
    for j = 1:numel(channel_ids)
        channel_id = channel_ids(j);
        uistack(ph.(channels{channel_id}), 'top')
    end
end

end