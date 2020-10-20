function events = get_events_by_channel(eeg_data)
% function events = get_events_by_channel(eeg_data)
%
% Separate events in an eeglab data set into structs by their channel
% Inputs:
%    - eeg_data: Data from eeglab .set file
% Outputs:
%    - events: Struct with events by channel.

type = extractfield(eeg_data.event,'type');
latency = extractfield(eeg_data.event,'latency');
duration = extractfield(eeg_data.event,'duration');

events = struct();

for i = 1:numel(eeg_data.chanlocs)
    channel = eeg_data.chanlocs(i).labels;
    burst_type = [channel,'_burst'];
    burst_id = logical(count(type,burst_type));
    
    burst_latency = latency(burst_id) / eeg_data.srate;
    burst_duration = duration(burst_id) / eeg_data.srate;
    
    events.(channel) = struct(...
        'n',sum(burst_id),...
        'latency',burst_latency,'unit_latency','s',...
        'duration',burst_duration,'unit_duration','s');
end

end