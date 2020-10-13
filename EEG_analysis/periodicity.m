function periodicity(eeg_data, channel, smooth)

if nargin < 3
    smooth = true;
end

events = process_bursts(eeg_data, channel, false);

t = events.latency;
y = gradient(events.latency);

if smooth
    ma_width = round(numel(t)/100);
    y_ma = movmean(y,ma_width);
else
    y_ma = y;
end

L = numel(t);

t_uniform = linspace(t(1),t(end),L);
y_uniform = interp1(t,y_ma,t_uniform,'linear');

figure(1)
subplot(2,1,1)
plot(t/3600,y,'b-',t_uniform/3600,y_uniform,'r--')
xlabel('Time (hrs)')
ylabel('Time between events (s)')

Fs = numel(t)/t_uniform(end);

% Copied from 'doc fft'
fty = fft(y_uniform);
P2 = abs(fty/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L * 1000;

figure(1)
subplot(2,1,2)
semilogx(f,P1,'o-');
xlabel('f (mHz)')
ylabel('Amplitude')

figure(2)
subplot(3,1,3)
cwt(y_uniform, Fs)

end