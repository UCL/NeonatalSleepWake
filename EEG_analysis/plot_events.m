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

for i = 1:numel(channels)
    channel = channels{i};
    assert(any(strcmp(field,fieldnames(events.(channel)))), ...
        ['Field ',field,' not found in event data'])
    t = seconds(events.(channel).latency);
    stem(hours(t), events.(channel).(field))
end

legend(channels)
xlabel('Time (hours)')
ylabel([field,' [',events.(channel).(['unit_',field]),']'])
box on
grid on

xlim([0,24])
set(gca,'xtick',0:24)

end