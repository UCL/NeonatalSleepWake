function fig = plot_events(events, field, channels_in)
% function fig = plot_events(events, field, channels_in)
%
% Plot burst durations by type of burst with latency on the x-axis
% Arguments
% events : Struct with events by channel. Produced by process_bursts.m or
%          get_events_by_channel.m
% field : quantity to plot, supported options are
%         - 'duration'
%         - 'power'
%         - 'power_n'
% channels_in : string or cell array of channel names
%
% EXAMPLES:
% plot_events(set_filename,'duration','O2');
% plot_events(set_filename,'power',{'O2','C4'});

if iscell(channels_in)
    channels = channels_in;    
elseif ischar(channels_in) || isstring(channels_in)
    channels = {channels_in};
else
    error('Types must be a string or a cell array');
end

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
switch field
    case 'duration'
        %add configs here
    case 'power'
        set(gca, 'YScale','log')
        ylim([0, 400])
    case 'power_n'
        ylim([0, 100])
        set(gca, 'YScale','log')
end

end