function events = get_events_by_channel(eeg_data)

type = extractfield(eeg_data.event,'type');
latency = extractfield(eeg_data.event,'latency');
duration = extractfield(eeg_data.event,'duration');

events = struct();

for i = 1:numel(eeg_data.chanlocs)
    channel = eeg_data.chanlocs(i).labels;
    burst_type = [channel,'_burst'];
    burst_id = logical(count(type,burst_type));
    
    burst_latency = latency(burst_id) / (eeg_data.srate * 1e-3);
    burst_duration = duration(burst_id) / (eeg_data.srate * 1e-3);
    
    events.(channel) = struct(...
        'n',sum(burst_id),...
        'latency',burst_latency,'unit_latency','ms',...
        'duration',burst_duration,'unit_duration','ms');
end

end