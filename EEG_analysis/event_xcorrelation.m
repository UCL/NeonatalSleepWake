function [xc,lags] = event_xcorrelation(events, source, target, mask, maxlag)
%

tmax = max(events.(source).latency(end), events.(target).latency(end));

npoints = 20;

nt = round(tmax/maxlag*npoints);
t = linspace(0,tmax,nt);
timeseries = struct();
timeseries.(source) = zeros(1,nt);
timeseries.(target) = zeros(1,nt);
dt = tmax/nt;

for i = 1:events.(source).n
    % Mask the source events by a prescribed condition
    if mask(i)
        ievent = find(t >= events.(source).latency(i), 1);
        timeseries.(source)(ievent) = 1;
    end
end

for i = 1:events.(target).n
    % Find correlations with all target events
    ievent = find(t >= events.(target).latency(i), 1);
    timeseries.(target)(ievent) = 1;
end

%figure(157);

[xc, lags] = xcorr(timeseries.(source), timeseries.(target), ...
    round(maxlag/dt), 'normalized');
lags = lags .* dt;
%        subplot(nc,nc,nc*(i-1)+j);
%         %plot(lags{i,j} .* dt, xc{i,j}, 'linewidth',2)
%         stem(lags{i,j} .* dt, xc{i,j})
%         title([channels{i} '--' channels{j}])
%         set(gca,'xtick',-maxlag:1:maxlag)
%         if (i == nc)
%             xlabel('lag (s)')
%         end
%         if (j == 1)
%             ylabel('normalized cross-corr')
%         end
%         axis tight
end