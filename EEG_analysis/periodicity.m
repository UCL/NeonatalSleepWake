function [peak_period,peak_amplitude] = periodicity(events, channel, field, varargin)
% function periodicity(events, channel, field, smooth, color)
%
% Perform and plot frequency analysis for events in selected channel.
% Returns the period and amplitude of the signal with the highest amplitude
% found within a predefined period window. Currently set at 0.2 hrs to 5
% hrs.
% Inputs:
%    - events: Struct with events by channel. Produced by process_bursts.m or
%              get_events_by_channel.m
%    - channel: name of channel
%    - field: quantity to analyze/plot, supported options are
%            - 'latency
%            - 'duration'
%            - 'power'
%            - 'power_n'
%  Optional:
%    - window (default [0.2 5]): period range where to look for the peak
%                                amplitude
%    - smooth (default true): smooth data with a moving average before
%      fourier transforming.
%    - color (default [0 0 1]): Color for 1D plots
%    - verbose (default true): switch to enable/disable plots
% Outputs:
%    - peak_period: period (hrs) of the signal with the highest amplitude
%                   within the period window
%    - peak_amplitude: amplitude of the signal with the highst amplitude
%                      within the period window

params = inputParser;
addOptional(params, 'window', [0.2 5.0], @(x) isnumeric(x) && numel(x) == 2);
addOptional(params, 'smooth', true, @(x) islogical(x));
addOptional(params, 'color', [0 0 1]);
addOptional(params, 'verbose', true, @(x) islogical(x));
parse(params, varargin{:});

t = events.(channel).latency;

if numel(t) < 3
    warning(['Could not do periodicity analysis on channel ',...
        channel, ' because of  too few events'])
    peak_period = NaN;
    peak_amplitude = NaN;
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

if params.Results.smooth
    ma_width = ceil(numel(t)/100);
    y_ma = movmean(y,ma_width);
else
    y_ma = y;
end

L = numel(t);

t_uniform = linspace(t(1),t(end),L);
y_uniform = interp1(t,y_ma,t_uniform,'linear');

% Approximate frequency of events
Fs = numel(t)/t_uniform(end);

% Do fft over the signal. Code is from 'doc fft'.
fty = fft(y_uniform);
P2 = abs(fty/L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L * 3600;

% Find the period with the highest amplitude within period_window. 
period = 1./f;
ip = period >= params.Results.window(1) & period <= params.Results.window(2);
windowed_periods = period(ip);

[peak_amplitude, imax] = max(P1(ip));
peak_period = windowed_periods(imax);

if params.Results.verbose
    % Plot fourier spectrum and continuous wavelet analysis
    figure()
    subplot(2,1,1)
    hold on
    plot(hours(seconds(t)),y,'Color',params.Results.color)
    plot(hours(seconds(t_uniform)),y_uniform,'r--','linewidth',2)
    xlabel('Time (hrs)')
    ylabel(yl)
    title(['Signal for channel ', channel])
    
    subplot(2,1,2)
    semilogx(1./f,P1,'o-','Color',params.Results.color);
    xlabel('Period (hrs)')
    ylabel('Amplitude')
    title(['Fourier spectrum for channel ', channel])
    grid on
    
    % Continuous wavelet analysis. Just use what comes out of the box.
    figure()
    cwt(y_uniform, hours(1/Fs/3600))
    title([get(gca,'title').String, ' for channel ',channel])
end

end