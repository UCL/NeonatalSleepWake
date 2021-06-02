%
%
%% Run tests
runtests('test_event_lag.m');
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
%% Initialise variables
nc = numel(channels);
burst_corr = struct();
%% Process bursts
events = process_bursts(eeg_data, channels);
%% Calculate lags & statistics for all bursts
burst_corr.all = struct();
burst_corr.all.lag = cell(nc, nc);
burst_corr.all = initialise_tables(burst_corr.all, channels);
for i = 1:nc
    for j = 1:nc
        burst_corr.all.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
        burst_corr.all = statistics(burst_corr.all, channels, i, j);
    end
end
%% Calculate lags & statistics for max 1.5s lags [Leroy & Terquem 2017]
burst_corr.leroy_terquem = struct();
burst_corr.leroy_terquem.lag = cell(nc,nc);
burst_corr.leroy_terquem = initialise_tables(burst_corr.leroy_terquem, channels);
max_lag_leroy_terquem = 1.5;
for i = 1:nc
    for j = 1:nc
        burst_corr.leroy_terquem.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
        mask = (burst_corr.leroy_terquem.lag{i,j} <= max_lag_leroy_terquem);
        burst_corr.leroy_terquem.lag{i,j}(~mask) = NaN;
        burst_corr.leroy_terquem = statistics(burst_corr.leroy_terquem, channels, i, j);
    end
end
%% Calculate lags & statistics for max 0.5s between offset and onset [Hartley 2012]
burst_corr.hartley = struct();
burst_corr.hartley.lag = cell(nc,nc);
burst_corr.hartley = initialise_tables(burst_corr.hartley, channels);
max_lag_hartley = 0.5;
for i = 1:nc
    for j = 1:nc
        burst_corr.hartley.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
        mask = burst_corr.hartley.lag{i,j} - events.(channels{i}).duration <= max_lag_hartley;
        burst_corr.hartley.lag{i,j}(~mask) = NaN;
        burst_corr.hartley = statistics(burst_corr.hartley, channels, i, j);
    end
end
%%
function s = initialise_tables(s,channels)
nc = numel(channels);
doubletype = repmat("double", 1, 4);
s.mean = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.median = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.std = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.p25 = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.p75 = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
end

function s = statistics(s, channels, i, j)
s.mean.(channels{i})(j) = mean(s.lag{i,j}, 'omitnan');
s.median.(channels{i})(j) = median(s.lag{i,j}, 'omitnan');
s.std.(channels{i})(j) = std(s.lag{i,j}, 'omitnan');
s.p25.(channels{i})(j) = prctile(s.lag{i,j}, 25);
s.p75.(channels{i})(j) = prctile(s.lag{i,j}, 75);
end