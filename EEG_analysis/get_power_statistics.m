function [mean_power, median_power] = get_power_statistics(events, channels_in, varargin)
% function [mean_power, median_power] = get_power_statistics(events, channels)
%
% Calculates mean and median of power for each channel
% Inputs:
%    - events: Struct with events by channel. Produced by process_bursts.m or
%              get_events_by_channel.m
%    - channels_in: string or cell array of channel names (usually found in
%                   eeg_data.chanlocs.labels)
%  Optional:
%    - normalised (default false): Use normalised instead of absolute power
% Outputs:
%    - mean_power: Array of mean powers for each channel in channels_in
%    - median_power: Array of median powers for each channel in channels_in

params = inputParser;
addOptional(params, 'normalised', false, @(x) islogical(x));
parse(params, varargin{:});

channels = format_channels(channels_in);

n = numel(channels);
mean_power = zeros(n,1);
median_power = zeros(n,1);

for i = 1:n
    channel = channels{i};
    if params.Results.normalised
        mean_power(i) = mean(events.(channel).power_n);
        median_power(i) = median(events.(channel).power_n);        
    else
        mean_power(i) = mean(events.(channel).power);
        median_power(i) = median(events.(channel).power);
    end
end

end