function events = process_bursts(eeg_data, channels_in, events_in)
   
lots_of_events = 2e3;

if nargin < 3
    events = get_events_by_channel(eeg_data);
else
    events = events_in;    
end
    
if nargin < 4
    get_power = true;
end

if iscell(channels_in)
    channels = channels_in;    
elseif ischar(channels_in) || isstring(channels_in)
    channels = {channels_in};
else
    error('Channels must be a string or a cell array');
end

for ic = 1:numel(channels)
    channel = channels{ic};

    % Check if this channel has already been processed
    if (isfield(events.(channel),'power') && isfield(events.(channel), 'power_n'))
        continue
    end        
    
    if events.(channel).n > lots_of_events
        warning(['computing the power in ',num2str(events.(channel).n),...
            ' events.(channel). This may take a while.'])
        wb = waitbar(0, ['Processing events for channel ',channel]);
        wb_exists = true;
    else
        wb_exists = false;
    end
    
    channel_list = extractfield(eeg_data.chanlocs,'labels');
    channel_id = find(count(channel_list,channel));
    voltage_series = eeg_data.data(channel_id,:); %#ok<*FNDSB> In microVolts
    power_series = voltage_series.^2;
    time_series = eeg_data.times * 1e-3; % In seconds
    
    events.(channel).power = zeros(1,events.(channel).n);
        
    for i = 1:events.(channel).n
        idx = time_series >= events.(channel).latency(i) & ...
            time_series <= events.(channel).latency(i) + events.(channel).duration(i);
        events.(channel).power(i) = trapz(time_series(idx), power_series(idx));
        if wb_exists
            waitbar(i/events.(channel).n, wb, ['Processing events for channel ',channel])
        end
    end
    events.(channel).unit_power = '\muV^2';
    
    events.(channel).power_n = events.(channel).power ./ events.(channel).duration;
    events.(channel).unit_power_n = '\muV^2s^{-1}';
    
    if wb_exists
        close(wb)
    end
end

end