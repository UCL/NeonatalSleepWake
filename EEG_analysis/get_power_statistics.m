function [mean_power, median_power] = get_power_statistics(events, channels)
% function [mean_power, median_power] = get_power_statistics(events, channels)
%
% Calculates mean and median of power for each channel

n = numel(channels);
mean_power = zeros(n,1);
median_power = zeros(n,1);

for i = 1:n
    channel = channels{i};
    mean_power(i) = mean(events.(channel).power);
    median_power(i) = median(events.(channel).power);
end

end