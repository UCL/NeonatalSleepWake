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
doubletype = repmat("double", 1, 4);
celltype = repmat("cell", 1, 4);
burst_corr_data = struct();
burst_corr_data.lag = cell(nc, nc);
burst_corr_data.mean = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
burst_corr_data.median = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
burst_corr_data.var = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
burst_corr_data.std = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
%% Process bursts
events = process_bursts(eeg_data, channels);
%% Calculate lags & statistics
for i = 1:nc
    for j = 1:nc
        burst_corr_data.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
        burst_corr_data.mean.(channels{i})(j) = mean(burst_corr_data.lag{i,j}, 'omitnan');
        burst_corr_data.median.(channels{i})(j) = median(burst_corr_data.lag{i,j}, 'omitnan');
        burst_corr_data.var.(channels{i})(j) = var(burst_corr_data.lag{i,j}, 'omitnan');
        burst_corr_data.std.(channels{i})(j) = std(burst_corr_data.lag{i,j}, 'omitnan');
    end
end