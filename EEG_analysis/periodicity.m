function periodicity(events, channel, field, smooth, color)
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
    ma_width = round(numel(t)/100);
    y_ma = movmean(y,ma_width);
else
    y_ma = y;
end

L = numel(t);

t_uniform = linspace(t(1),t(end),L);
y_uniform = interp1(t,y_ma,t_uniform,'linear');

figure()
subplot(2,1,1)
hold on
plot(hours(seconds(t)),y,'Color',color)
plot(hours(seconds(t_uniform)),y_uniform,'r--')
xlabel('Time (hrs)')
ylabel(yl)
title(channel)

Fs = numel(t)/t_uniform(end);

% Copied from 'doc fft'
fty = fft(y_uniform);
P2 = abs(fty/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L * 3600;

subplot(2,1,2)
semilogx(f,P1,'o-','Color',color);
xlabel('f (1/hr)')
ylabel('Amplitude')

figure()
cwt(y_uniform, Fs)

end