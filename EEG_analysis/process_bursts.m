function events = process_bursts(set_filename, channel)
    
if (exist('pop_loadset','file') == 0)
    eeglab nogui
end

if(strcmp(set_filename,'test'))
    eeg_data = test_data(100);
else
    eeg_data = pop_loadset(set_filename);
end

events_by_channel = get_events_by_channel(eeg_data);

events = events_by_channel.(channel);

channel_list = extractfield(eeg_data.chanlocs,'labels');
channel_id = find(count(channel_list,channel));
voltage_series = eeg_data.data(channel_id,:) * 1e-6; %#ok<*FNDSB> In Volts
power_series = voltage_series.^2;
time_series = eeg_data.times * 1e-3; % In seconds

events.power = zeros(1,events.n);

for i = 1:events.n
    istart = find(time_series >= events.latency(i),1);
    iend = find(time_series >= events.latency(i) + events.duration(i),1);
    events.power(i) = trapz(time_series(istart:iend), ...
        power_series(istart:iend));   
end
events.unit_power = 'V^2';

events.power_n = events.power ./ events.duration;
events.unit_power_n = 'V^2s^{-1}';

end