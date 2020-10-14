function events = process_bursts(eeg_data, channels_in, events_in)
% function events = process_bursts(eeg_data, channels_in, events_in)
%
% Separates burst events in eeg data by channel, calculates integrated
% power for each event.
% Inputs:
%    - eeg_data: data from eeglab .set file
%    - channels_in: string or cell array of channel names (usually found in
%                   eeg_data.chanlocs.labels)
%    - events_in: (optional) events previously processed by this function
%                 (to avoid reprocessing channels)
% Outputs:
%    - events: struct with substructs for each channel. Each channel struct
%              has the fields 'latency' and 'duration'. In addition,
%              processed channels have the fields 'power' and 'power_n'


% Threshold number of events to display warning and progress bar
lots_of_events = 2e3;

% Handle optional argument
if nargin < 3
    events = get_events_by_channel(eeg_data);
else
    events = events_in;    
end

channels = format_channels(channels_in);

for ic = 1:numel(channels)
    channel = channels{ic};

    % Skip this channel if it has already been processed
    if (isfield(events.(channel),'power') && isfield(events.(channel), 'power_n'))
        continue
    end        
    
    % If we are processing a large number of events, this function can be
    % slow. In that case, give the user a friendly warning and display a
    % progress bar.
    if events.(channel).n > lots_of_events
        warning(['computing the power in ',num2str(events.(channel).n),...
            ' events. This may take a while.'])
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
    
    % Integrate power in each event
    for i = 1:events.(channel).n
        % Find event start and end indices
        i1 = int64(events.(channel).latency(i) * eeg_data.srate);
        i2 = int64((events.(channel).latency(i) + events.(channel).duration(i)) * eeg_data.srate);
        % Approximate integral with the trapezoid rule
        events.(channel).power(i) = trapz(time_series(i1:i2), power_series(i1:i2));
        
        if wb_exists
            waitbar(i/events.(channel).n, wb, ['Processing events for channel ',channel])
        end
    end
    events.(channel).unit_power = '\muV^2';
    
    % Power normalized by event duration
    events.(channel).power_n = events.(channel).power ./ events.(channel).duration;
    events.(channel).unit_power_n = '\muV^2s^{-1}';
    
    if wb_exists
        close(wb)
    end
end

end