function [period,amplitude] = periodicity(events, channel, field, smooth, color)
% function periodicity(events, channel, field, smooth, color)
%
% Perform and plot frequency analysis for events in a selected channel.

if nargin < 4
    smooth = true;
end

if nargin < 5
    color = [0 0 1];
end

t = events.(channel).latency;

if numel(t) < 3
    warning('Periodicity analysis requires (way) more than 2 data points, aborting.')
    period = NaN;
    amplitude = NaN;
    return
end

switch field
    case 'latency'
        y = gradient(events.(channel).latency);
        yl = 'Time between events (s)';
    case 'duration'
        y = events.(channel).duration;
        yl = 'Event duration (s)';
    case 'power'
        y = events.(channel).power;
        yl = 'Power (\muV^2)';
    case 'power_n'
        y = events.(channel).power_n;
        yl = 'Normalized power (\muV^2s^{-1})';
    case default
        error(['Field ',field,' not recognized'])
end

if smooth
    ma_width = ceil(numel(t)/100);
    y_ma = movmean(y,ma_width);
else
    y_ma = y;
end

L = numel(t);

t_uniform = linspace(t(1),t(end),L);
% [ ] handle multiple events with the same latency
y_uniform = interp1(t,y_ma,t_uniform,'linear');

figure()
subplot(2,1,1)
hold on
plot(hours(seconds(t)),y,'Color',color)
plot(hours(seconds(t_uniform)),y_uniform,'r--','linewidth',2)
xlabel('Time (hrs)')
ylabel(yl)
title(['Signal for channel ', channel])

% Approximate frequency of events
Fs = numel(t)/t_uniform(end);

% Do fft over the signal. Code is from 'doc fft'.
fty = fft(y_uniform);
P2 = abs(fty/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L * 3600;

subplot(2,1,2)
semilogx(1./f,P1,'o-','Color',color);
xlabel('Period (hrs)')
ylabel('Amplitude')
title(['Fourier spectrum for channel ', channel])
grid on

% Continuous wavelet analysis. Just use what comes out of the box.
figure()
cwt(y_uniform, hours(1/Fs/3600))
title([get(gca,'title').String, ' for channel ',channel])

% Find the period with the highest amplitude. Ignore the lowest
% frequency in  the spectrum (f == 0.). Could improve this?
% - Add a frequency window to look in
% - Look for peaks only
[amplitude, imax] = max(P1(2:end));
period = 1./f(imax+1);

end