function events = remove_duplicate_events(events)
% function events = remove_duplicate_events(events)
%
% Remove duplicate (= events with identical latency) events from a data
% set. Assumes only pairs of identical events are found. Removes the event
% with the shorter duration.
% Inputs:
%    - events: Struct with events by channel. Produced by process_bursts.m or
%          get_events_by_channel.m
% Outputs:
%    - events: Struct with events by channel with duplicates removed.
channels = fieldnames(events);
array_fields = {'latency','duration','power','power_n'};

for i = 1:numel(channels)
    channel = channels{i};
    diffs = diff(events.(channel).latency);
    if min(diffs) < eps   

        [~,all_ids,~] = uniquetol(events.(channel).latency, 'outputallindices',true);
        unique_ids = zeros(numel(all_ids),1);
        
        for j = 1:numel(all_ids)
            if numel(all_ids{j}) > 1
                [~,imax] = max(events.(channel).duration(all_ids{j}));
                unique_ids(j) = all_ids{j}(imax);
            else
                unique_ids(j) = all_ids{j};
            end
        end
        
        for j = 1:numel(array_fields)
            field = array_fields{j};
            if isfield(events.(channel),field)
                events.(channel).(field) = events.(channel).(field)(unique_ids);
            end
        end
        events.(channel).n = numel(unique_ids);

    end
end

end