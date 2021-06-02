%% Read in data
eeg_data = pop_loadset();
if isempty(eeg_data)
    error('No .set file selected')
end
%% Select channels
channels = extractfield(eeg_data.chanlocs, 'labels');
preset_channels = {'F3','F4','C3','C4'};
nc0 = numel(preset_channels);
preset_ids = zeros(1,nc0);
for i = 1:nc0
    preset_ids(i) = find(strcmp(channels, preset_channels{i}));
end
[channel_index,~] = listdlg('ListString',channels,...
        'PromptString','Select channel(s)',...
        'InitialValue',preset_ids);
channels = channels(channel_index);
nc = numel(channels);
%% Process bursts
events = process_bursts(eeg_data, channels);
%%
tmax = zeros(1,nc);
for i = 1:nc
    tmax(i) = max(events.(channels{i}).latency);
end

nt = 10000;
t = linspace(0,max(tmax),nt);
ievents = zeros(nt,nc);
xc = cell(nc,nc);
lags = cell(nc,nc);
dt = max(tmax)/nt;

for i = 1:nc
    ch = channels{i};
    for j = 1:events.(ch).n
        i1 = find(t >= events.(ch).latency(j), 1);
        i2 = find(t >= events.(ch).latency(j) + events.(ch).duration(j), 1);
        ievents(i1:i2,i) = 1;
    end
end

r = corrcoef(ievents);
maxlag = 3.0;
figure(157);

for i = 1:nc
    for j = 1:nc
        [xc{i,j}, lags{i,j}] = xcorr(ievents(:,i), ievents(:,j), ...
            round(maxlag/dt), 'normalized');
        subplot(nc,nc,nc*(i-1)+j);
        plot(lags{i,j} .* dt, xc{i,j}, 'linewidth',2)
        title([channels{i} '--' channels{j}])
        set(gca,'xtick',-maxlag:1:maxlag)
        if (i == nc)
            xlabel('lag (s)')
        end
        if (j == 1)
            ylabel('normalized cross-corr')
        end
        axis tight
    end
end