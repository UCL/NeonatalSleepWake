function lag = event_lag(source, target)
% function lag = event_lag(source, target)
%
% Calculate the lag for each event in source to the next following event in
% target.
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