% This script visualizes EEG data from eeglab from selected channels and
% performs periodicity analysis on it. To get started, run it and follow
% the GUI windows that pop up to select which files to read, which channels
% to plot and which variables to analyse for periodicity.

%% Run tests
runtests('test_process_bursts.m');
%% Set initial values
field_index = 1;
channel_index = 1;
execute_loop = true;
eeg_periodicity_data = struct();
num_files = 0;
%% Loop over multiple files
while execute_loop
    %% Read in data
    eeg_data = pop_loadset();
    if isempty(eeg_data)
        error('No .set file selected')
    end
    num_files = num_files + 1;
    %% Channel selection GUI
    channels = extractfield(eeg_data.chanlocs, 'labels');
    [channel_index,~] = listdlg('ListString',channels,...
        'PromptString','Select channel(s)',...
        'InitialValue',channel_index);
    channels = channels(channel_index);
    %% Process the data for plotting. 
    % Do it only once and only for the requested channels to avoid
    % unnecessary work
    events = process_bursts(eeg_data,channels);
    %% Plot the events by duration as function of time
    plot_events(events,'duration',channels);
    % Store color order for use in later plots. Replicate it so we
    % don't run out of colors.
    co = get(gca,'colororder');
    co = repmat(co, ceil(numel(channels)/size(co,1)), 1);
    %% Plot the events by power as function of time
    plot_events(events,'power',channels);
    %% Plot the events by power normalised by the duration as a function of time
    plot_events(events,'power_n',channels);
    %% Field selection GUI
    fields = {'none','latency','duration','power','power_n'};
    [field_index,tf] = listdlg('ListString',fields,...
        'SelectionMode','single',...
        'PromptString','Select field for frequency analysis',...
        'ListSize',[300,300],...
        'InitialValue',field_index);
    if tf == 0 || field_index == 1
        field = [];
    else
        field = fields{field_index};
    end
    %% Plot frequency analysis for selected field&channels
    n = numel(channels);
    period = zeros(n,1);
    amplitude = zeros(n,1);
    if ~isempty(field)
        for i = 1:n
            [period(i),amplitude(i)] = periodicity(events,channels{i},field,'color',co(i,:));
        end
    end
    %% Write output data
    eeg_periodicity_data(num_files).setname = eeg_data.setname;
    expression = '[0-9]+\.*[0-9]*';
    [i1, i2] = regexp(eeg_data.setname,expression);
    id_value = str2double(eeg_periodicity_data(ifile).setname(i1(1):i2(1)));
    assert(isnumeric(id_value) && isfinite(id_value), ...
        ['Failed to parse set ID from set name, got ',id_value, ' instead of a number']);
    eeg_periodicity_data(ifile).id_prefix = eeg_periodicity_data(ifile).setname(1:i1(1) - 1);
    eeg_periodicity_data(ifile).id = id_value;
    eeg_periodicity_data(num_files).nchannels = numel(channels);
    eeg_periodicity_data(num_files).npoints = eeg_data.pnts;
    eeg_periodicity_data(num_files).deleted_fraction = get_deleted_fraction(eeg_data);
    eeg_periodicity_data(num_files).channels = channels;
    eeg_periodicity_data(num_files).period = hours(period);
    eeg_periodicity_data(num_files).amplitude = amplitude;
    [eeg_periodicity_data(num_files).corrcoef_r, ...
        eeg_periodicity_data(num_files).corrcoef_p] = get_corr_coefs(events, channels);
    %% GUI to exit the loop
    % Exit unless the user clicks on 'Yes'
    answer = questdlg('read another file?');
    switch answer
        case 'Yes'
            execute_loop = true;
        otherwise
            execute_loop = false;
    end
end
%% Save output data
[filename,pathname] = uiputfile('*.mat','Select output file','eeg_periodicity.mat');
if filename ~= 0
    save([pathname,filename],'eeg_periodicity_data');
end