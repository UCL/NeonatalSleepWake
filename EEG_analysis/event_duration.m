function duration = event_duration(signal, threshold, max_gap, ievent)

duration = 0;

% Count how many frames the signal stays above threshold
while signal(ievent + duration) > threshold
    duration = duration + 1;
end

% Allow signal to go below threshold for max_gap frames
i = 0;
while i <= max_gap && ievent+duration+i < numel(signal)
    i = i + 1;
    if signal(ievent+duration+i) > threshold
        duration = duration + i;
        i = 0;
    end
end

end