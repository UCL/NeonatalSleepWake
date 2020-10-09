function events = power_per_burst(set_filename, channel)
    
if (exist('pop_loadset','file') == 0)
    eeglab nogui
end

eeg_data = pop_loadset(set_filename);
events_by_channel = get_events_by_channel(eeg_data);

events = events_by_channel.(channel);

channel_list = extractfield(eeg_data.chanlocs,'labels');
channel_id = find(count(channel_list,channel));
voltage_series = eeg_data.data(channel_id,:); %#ok<*FNDSB>
power_series = voltage_series.^2;

events.power = zeros(1,events.n);

for i = 1:events.n
    istart = find(eeg_data.times >= events.latency(i),1);
    iend = find(eeg_data.times >= events.latency(i) + events.duration(i),1);
    events.power(i) = trapz(eeg_data.times(istart:iend) * 1e-3, ...
        power_series(istart:iend));
end
events.unit_power = '(microV)^2';

end