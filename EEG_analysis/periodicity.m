function periodicity(events, channel, field, smooth)

if nargin < 4
    smooth = true;
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
plot(hours(seconds(t)),y,'b-',hours(seconds(t_uniform)),y_uniform,'r--')
xlabel('Time (hrs)')
ylabel(yl)

Fs = numel(t)/t_uniform(end);

% Copied from 'doc fft'
fty = fft(y_uniform);
P2 = abs(fty/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L * 1000;

subplot(2,1,2)
semilogx(f,P1,'o-');
xlabel('f (mHz)')
ylabel('Amplitude')

figure()
cwt(y_uniform, Fs)

end