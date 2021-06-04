function lag = event_lag(source, target)
% function lag = event_lag(source, target)
%
% Calculate the lag for each event in source to the next following event in
% target.
%
% Inputs:
%   source: Struct with events for one channel. Sub-structure of the struct
%           produced by process_bursts.m or get_events_by_channel.m
%   target: Struct with events for one channel. Sub-structure of the struct
%           produced by process_bursts.m or get_events_by_channel.m
% Outputs:
%   lag: Vector of lags with one element for each event in source
lag = zeros(1,source.n);

j = 1;
for i = 1:source.n
    while (j < target.n && target.latency(j) <= source.latency(i))
        j = min(target.n,j + 1);
    end
    if (target.latency(j) > source.latency(i))
        lag(i) = target.latency(j) - source.latency(i);
    else
        lag(i) = NaN;
    end
end

end