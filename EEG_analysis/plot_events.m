function fig = plot_events(filename, field, channels_in)
% function fig = plot_events(filename, field, channels_in)
%
% Plot burst durations by type of burst with latency on the x-axis
% Arguments
% filename : name of set file
% field : quantity to plot, supported options are
%    - 'duration'
%    - 'power'
%    - 'power_n'
% fields_in : string or cell array of channel names
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

assert(ischar(filename) || isstring(filename), 'Filename must be a string')

fig = figure();
clf;
hold on

for i = 1:numel(channels)
    events = process_bursts(filename, channels{i});
    assert(any(strcmp(field,fieldnames(events))), ['Field ',field,' not found in event data'])
    stem(events.latency, events.(field))
end

legend(channels)
xlabel(['latency [',events.unit_latency,']'])
ylabel([field,' [',events.(['unit_',field]),']'])
box on
grid on

end