% This script processes EEG data from eeglab, computes lags and
% cross-correlations between burst events on different channels. The
% results are stored in the burst_corr variable in the workspace and can be
% written into an .xlsx file. To get started, run it and  follow the GUI
% windows that pop up to select parameters, which files to read and where
% to save the output.
% NOTE:
% You can select multiple input files, but only if they are in the same
% directory.
%% Run tests
runtests('test_event_lag.m');
%% Read in data
[in_file_names,in_path_name] = uigetfile('*.set','Select input .set files','multiselect','on');
if ~iscell(in_file_names)
    in_file_names = {in_file_names};
end
%% Read excel table
[filename,pathname] = uigetfile('*.xls*', 'select input excel file');
if (ischar(pathname) && ischar(filename))
    full_table = readtable([pathname,filename], 'UseExcel', true);
end
%% Create table for results
eeg_data = pop_loadset([in_path_name,in_file_names{1}]);
[id_prefix, id_val] = parse_id_and_prefix(eeg_data);
new_table = table(full_table.(id_prefix),'variablenames',{id_prefix});
%% Get parameters for cross-correlations
answer = questdlg('Calculate cross correlations? (May be slow)');
do_xcorr= strcmp(answer, 'Yes');
if (do_xcorr)
    prompt = {'Maximum lag (s)', 'Window length (frames)', 'Steepness (std)'};
    answer = inputdlg(prompt, 'xcorr options',1,{'1.5', '7', '3'});
    maxlag = str2double(answer{1});
    gauss_frames = str2double(answer{2});
    gauss_sds = str2double(answer{3});
end
%% Initialise variables
preset_channels = {'F3','F4','C3','C4'};
nc0 = numel(preset_channels);
channels = {};
burst_corr = struct();
%% Loop over files
for ifile = 1:numel(in_file_names)
    %% Read eeglab dataset
    filename = in_file_names{ifile};
    eeg_data = pop_loadset([in_path_name,filename]);
    %% Select channels
    all_channels = extractfield(eeg_data.chanlocs, 'labels');
    if isempty(channels)
        preset_ids = zeros(1,nc0);
        for i = 1:nc0
            preset_ids(i) = find(strcmp(all_channels, preset_channels{i}));
        end
        [channel_index,~] = listdlg('ListString',all_channels,...
            'PromptString','Select channel(s)',...
            'InitialValue',preset_ids);
        channels = all_channels(channel_index);
        nc = numel(channels);
    else
        for i = 1:nc
            if ~any(strcmp(channels{i}, all_channels))
                error(['Channel ' channels{i} ' not found in ' eeg_data.setname])
            end
        end
    end
    %% Process bursts
    events = process_bursts(eeg_data, channels);
    all_events = struct('latency', []);
    for i = 1:nc
        all_events.latency = [all_events.latency, events.(channels{i}).latency];
    end
    all_events.latency = sort(all_events.latency);
    all_events.n = numel(all_events.latency);
    %% Calculate lags & statistics for all bursts
    burst_corr(ifile).all = struct();
    burst_corr(ifile).all = initialise_tables(burst_corr(ifile).all, channels);
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).all.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            mask = true(1,events.(channels{i}).n);
            burst_corr(ifile).all = statistics(burst_corr(ifile).all, channels, i, j);
        end
        burst_corr(ifile).all.lag{i, nc+1} = event_lag(events.(channels{i}), all_events);
        burst_corr(ifile).all = statistics(burst_corr(ifile).all, channels, i, nc+1);
    end
    %% Calculate lags & statistics for max 1.5s lags [Leroy & Terquem 2017]
    burst_corr(ifile).leroy_terquem = struct();
    burst_corr(ifile).leroy_terquem = initialise_tables(burst_corr(ifile).leroy_terquem, channels);
    max_lag_leroy_terquem = 1.5;
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).leroy_terquem.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            mask = (burst_corr(ifile).leroy_terquem.lag{i,j} <= max_lag_leroy_terquem);
            burst_corr(ifile).leroy_terquem.lag{i,j}(~mask) = NaN;
            burst_corr(ifile).leroy_terquem = statistics(burst_corr(ifile).leroy_terquem, channels, i, j);
        end
        burst_corr(ifile).leroy_terquem.lag{i, nc+1} = event_lag(events.(channels{i}), all_events);
        mask = (burst_corr(ifile).leroy_terquem.lag{i, nc+1} <= max_lag_leroy_terquem);
        burst_corr(ifile).leroy_terquem.lag{i, nc+1}(~mask) = NaN;
        burst_corr(ifile).leroy_terquem = statistics(burst_corr(ifile).leroy_terquem, channels, i, nc+1);
    end
    %% Calculate lags & statistics for max 0.5s between offset and onset [Hartley 2012]
    burst_corr(ifile).hartley = struct();
    burst_corr(ifile).hartley = initialise_tables(burst_corr(ifile).hartley, channels);
    max_lag_hartley = 0.5;
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).hartley.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            mask = burst_corr(ifile).hartley.lag{i,j} - events.(channels{i}).duration <= max_lag_hartley;
            burst_corr(ifile).hartley.lag{i,j}(~mask) = NaN;
            burst_corr(ifile).hartley = statistics(burst_corr(ifile).hartley, channels, i, j);
        end
        burst_corr(ifile).hartley.lag{i, nc+1} = event_lag(events.(channels{i}), all_events);
        mask = burst_corr(ifile).hartley.lag{i, nc+1} - events.(channels{i}).duration <= max_lag_hartley;
        burst_corr(ifile).hartley.lag{i, nc+1}(~mask) = NaN;
        burst_corr(ifile).hartley = statistics(burst_corr(ifile).hartley, channels, i, nc+1);
    end
    %% Calculate cross-correlations
    if do_xcorr
        burst_corr(ifile).all.xc = cell(nc, nc);
        burst_corr(ifile).all.xc_lags = cell(nc, nc);
        for i = 1:nc
            for j = 1:nc
                [xc,xc_lags] = event_xcorrelation(events, channels{i}, ...
                    channels{j}, maxlag, 'frames', gauss_frames, 'sds', gauss_sds);
                burst_corr(ifile).all.xc{i,j} = xc;
                burst_corr(ifile).all.xc_lags{i,j} = xc_lags;
            end
        end
    end
    %% Add columns for period and amplitude to the table
    if exist('full_table','var')
        [id_prefix, id_val] = parse_id_and_prefix(eeg_data);
        fields = fieldnames(burst_corr);
        sources = channels;
        targets = channels;
        targets{nc + 1} = 'any';
        for ifield = 1:numel(fields)
            for i = 1:nc
                for j = 1:nc+1
                    source = sources{i};
                    target = targets{j};
                    field_prefix = [fields{ifield} '-' source '-' target '-'];
                    subfields = fieldnames(burst_corr(ifile).(fields{ifield}));
                    for isubfield = 1:numel(subfields)
                        if istable(burst_corr(ifile).(fields{ifield}).(subfields{isubfield}))
                            field_header = [field_prefix subfields{isubfield}];
                            new_table.(field_header)(new_table.(id_prefix) == id_val) = ...
                                burst_corr(ifile).(fields{ifield}).(subfields{isubfield}).(source)(j);
                        end
                    end
                end
            end
        end
        new_table = standardizeMissing(new_table, 0);
    end
end
%% Write excel table
if (exist('full_table','var'))
    out_table = join(full_table, new_table);
    [out_file_name,out_path_name] = uiputfile('*.xlsx','Select output file','burst_pattern.xlsx');
    if (ischar(out_path_name) && ischar(out_file_name))
        writetable(out_table,[out_path_name,out_file_name])
    end
end
%% Calculate average x-correlations and plot
if do_xcorr
    field = 'all';
    lags = cell(nc,nc);
    xc = cell(nc,nc);
    %lags = burst_corr(1).(field).xc_lags;
    %xc = burst_corr(1).(field).xc;
    for ifile = 1:numel(burst_corr)
        for i = 1:nc
            for j = 1:nc
                lags{i,j}(ifile,:) = burst_corr(ifile).(field).xc_lags{i,j};
                xc{i,j}(ifile,:) = burst_corr(ifile).(field).xc{i,j};
            end
        end
    end

    figure;
    for i = 1:nc
        for j = 1:nc
            subplot(nc,nc,nc*(i-1)+j);
            stem(mean(lags{i,j},1), mean(xc{i,j},1))
            title([channels{i} '--' channels{j}])
            if (i == nc)
                xlabel('lag (s)')
            end
            if (j == 1)
                ylabel('normalized cross-corr')
            end
            axis tight
        end
    end
end
%%
function s = initialise_tables(s,channels)
nc = numel(channels);
doubletype = repmat("double", 1, nc);
inttype = repmat("int64",1, nc);
s.lag = cell(nc, nc);
rownames = channels;
rownames{nc+1} = 'any';
s.mean = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.median = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.std = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.p25 = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.p75 = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.count = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);
s.fraction = table('Size',[nc+1,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',rownames);

end

function s = statistics(s, channels, i, j)
s.mean.(channels{i})(j) = mean(s.lag{i,j}, 'omitnan');
s.median.(channels{i})(j) = median(s.lag{i,j}, 'omitnan');
s.std.(channels{i})(j) = std(s.lag{i,j}, 'omitnan');
s.p25.(channels{i})(j) = prctile(s.lag{i,j}, 25);
s.p75.(channels{i})(j) = prctile(s.lag{i,j}, 75);
s.count.(channels{i})(j) = sum(isfinite(s.lag{i,j}));
s.fraction.(channels{i})(j) = sum(isfinite(s.lag{i,j}))/numel(s.lag{i,j});
end