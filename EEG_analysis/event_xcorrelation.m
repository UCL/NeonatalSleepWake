function [xc,lags] = event_xcorrelation(events, source, target, maxlag, varargin)
%

params = inputParser;
addOptional(params, 'frames', 7, @(x) isnumeric(x));
addOptional(params, 'sds',    3, @(x) isnumeric(x));
parse(params, varargin{:});

tmax = max(events.(source).latency(end), events.(target).latency(end));

npoints = 20;

nt = round(tmax/maxlag*npoints);
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