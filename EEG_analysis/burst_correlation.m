%
%
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
%% 
answer = questdlg('Calculate cross correlations? (May be slow)');
do_xcorr= strcmp(answer, 'Yes');
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
    %% Calculate lags & statistics for all bursts
    burst_corr(ifile).all = struct();
    burst_corr(ifile).all = initialise_tables(burst_corr(ifile).all, channels);
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).all.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            burst_corr(ifile).all.mask{i,j} = true(1,events.(channels{i}).n);
            burst_corr(ifile).all = statistics(burst_corr(ifile).all, channels, i, j);
        end
    end
    %% Calculate lags & statistics for max 1.5s lags [Leroy & Terquem 2017]
    burst_corr(ifile).leroy_terquem = struct();
    burst_corr(ifile).leroy_terquem = initialise_tables(burst_corr(ifile).leroy_terquem, channels);
    max_lag_leroy_terquem = 1.5;
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).leroy_terquem.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            burst_corr(ifile).leroy_terquem.mask{i,j} = (burst_corr(ifile).leroy_terquem.lag{i,j} <= max_lag_leroy_terquem);
            burst_corr(ifile).leroy_terquem.lag{i,j}(~mask) = NaN;
            burst_corr(ifile).leroy_terquem = statistics(burst_corr(ifile).leroy_terquem, channels, i, j);
        end
    end
    %% Calculate lags & statistics for max 0.5s between offset and onset [Hartley 2012]
    burst_corr(ifile).hartley = struct();
    burst_corr(ifile).hartley = initialise_tables(burst_corr(ifile).hartley, channels);
    max_lag_hartley = 0.5;
    for i = 1:nc
        for j = 1:nc
            burst_corr(ifile).hartley.lag{i,j} = event_lag(events.(channels{i}), events.(channels{j}));
            burst_corr(ifile).hartley.mask{i,j} = burst_corr(ifile).hartley.lag{i,j} - events.(channels{i}).duration <= max_lag_hartley;
            burst_corr(ifile).hartley.lag{i,j}(~mask) = NaN;
            burst_corr(ifile).hartley = statistics(burst_corr(ifile).hartley, channels, i, j);
        end
    end
    %% Calculate cross-correlations
    if do_xcorr
        maxlag = 1.0;
        for i = 1:nc
            for j = 1:nc
                fields = fieldnames(burst_corr);
                for ifield = 1:numel(fields)
                    [xc,xc_lags] = event_xcorrelation(events, channels{i}, channels{j},...
                        burst_corr(ifile).(fields{ifield}).mask{i,j}, maxlag);
                    burst_corr(ifile).(fields{ifield}).xc{i,j} = xc;
                    burst_corr(ifile).(fields{ifield}).xc_lags{i,j} = xc_lags;
                end
            end
        end
    end
    %% Add columns for period and amplitude to the table
    if exist('full_table','var')
        [id_prefix, id_val] = parse_id_and_prefix(eeg_data);
        fields = fieldnames(burst_corr);
        for ifield = 1:numel(fields)
            for i = 1:nc
                for j = 1:nc
                    source = channels{i};
                    target = channels{j};
                    field_prefix = [fields{ifield} '-' source '-' target '-'];
                    subfields = fieldnames(burst_corr(ifile).(fields{ifield}));
                    for isubfield = 1:numel(subfields)
                        if istable(burst_corr(ifile).(fields{ifield}).(subfields{isubfield}))
                            field_header = [field_prefix subfields{isubfield}];
                            full_table.(field_header)(full_table.(id_prefix) == id_val) = ...
                                burst_corr(ifile).(fields{ifield}).(subfields{isubfield}).(source)(j);
                        end
                    end
                end
            end
        end
    end
end
%% Write excel table
if (exist('full_table','var'))
    [out_file_name,out_path_name] = uiputfile('*.xlsx','Select output file','burst_pattern.xlsx');
    if (ischar(out_path_name) && ischar(out_file_name))
        writetable(full_table,[out_path_name,out_file_name])
    end
end
%% Plot x-correlations
if do_xcorr
    i = 1;
    field = 'hartley';
    lags = burst_corr(i).(field).xc_lags;
    xc = burst_corr(i).(field).xc;
    figure;
    for i = 1:nc
        for j = 1:nc
            subplot(nc,nc,nc*(i-1)+j);
            %plot(lags{i,j} .* dt, xc{i,j}, 'linewidth',2)
            stem(lags{i,j}, xc{i,j})
            title([channels{i} '--' channels{j}])
            %set(gca,'xtick',-maxlag:1:maxlag)
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
inttype = repmat("uint64",1, nc);
s.lag = cell(nc, nc);
s.mask = cell(nc, nc);
s.xc = cell(nc, nc);
s.xc_lags = cell(nc, nc);
s.mean = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.median = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.std = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.p25 = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.p75 = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);
s.count = table('Size',[nc,nc],'VariableTypes',inttype,'VariableNames',channels,'RowNames',channels);
s.fraction = table('Size',[nc,nc],'VariableTypes',doubletype,'VariableNames',channels,'RowNames',channels);

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