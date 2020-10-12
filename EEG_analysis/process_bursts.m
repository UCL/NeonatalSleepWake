function events = process_bursts(eeg_data, channel, get_power)
   
lots_of_events = 1e4;

if nargin < 3
    get_power = true;
end

events_by_channel = get_events_by_channel(eeg_data);

events = events_by_channel.(channel);

if get_power
    
    if events.n > lots_of_events
        warning(['computing the power in ',num2str(events.n),...
            ' events. This may take a while.'])
    end
    
    channel_list = extractfield(eeg_data.chanlocs,'labels');
    channel_id = find(count(channel_list,channel));
    voltage_series = eeg_data.data(channel_id,:) * 1e-6; %#ok<*FNDSB> In Volts
    power_series = voltage_series.^2;
    time_series = eeg_data.times * 1e-3; % In seconds

    events.power = zeros(1,events.n);

    for i = 1:events.n
        idx = time_series >= events.latency(i) & ...
            time_series <= events.latency(i) + events.duration(i);
        events.power(i) = trapz(time_series(idx), power_series(idx));
    end
    events.unit_power = 'V^2';

    events.power_n = events.power ./ events.duration;
    events.unit_power_n = 'V^2s^{-1}';
end

end