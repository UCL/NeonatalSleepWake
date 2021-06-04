function [xc,lags] = event_xcorrelation(events, source, target, maxlag, varargin)
% function [xc,lags] = event_xcorrelation(events, source, target, maxlag, varargin)
%
% Calculates the cross-correlation of two sets of events. Events are
% interpolated onto a time series with uniform time intervals. A gaussian
% peak is inserted at the onset of each event.
%
% Inputs:
%   events: Struct with events by channel. Produced by process_bursts.m or
%           get_events_by_channel.m
%   source: Name of source channel
%   target: Name of target channel
%   maxlag: Maximum lag for cross-correlation (see help xcorr)
% Optional:
%   'frames' (default 7): Width of the gaussian peak in points
%   'sds' (default 3): Steepness of the gaussian peak in standard
%                      deviations
%   'npoints (default 20): Number of points for 0:maxlag
% Outputs:
%   xc: cross-correlation function over the range of lags -maxlag to maxlag
%   lags: vector of lag indices
params = inputParser;
addOptional(params, 'frames', 7, @(x) isnumeric(x));
addOptional(params, 'sds',    3, @(x) isnumeric(x));
addOptional(params, 'npoints',20, @(x) isnumeric(x));
parse(params, varargin{:});

tmax = max(events.(source).latency(end), events.(target).latency(end));

nt = round(tmax/maxlag*params.Results.npoints);
t = linspace(0,tmax,nt);
timeseries = zeros(2,nt);
dt = tmax/nt;
p = gauss(params.Results.frames,params.Results.sds);

for i = 1:events.(source).n
    ievent = find(t >= events.(source).latency(i), 1);
    i1 = max(1,ievent-3);
    i2 = min(ievent+3, nt);
    timeseries(1,i1:i2) = timeseries(1, i1:i2) + p(1:i2-i1+1);
end

for i = 1:events.(target).n
    ievent = find(t >= events.(target).latency(i), 1);
    i1 = max(1,ievent-3);
    i2 = min(ievent+3, nt);
    timeseries(2,i1:i2) = timeseries(2, i1:i2) + p(1:i2-i1+1);
end

[xc, lags] = xcorr(timeseries(1,:), timeseries(2,:), ...
    round(maxlag/dt), 'normalized');
lags = lags .* dt;

end