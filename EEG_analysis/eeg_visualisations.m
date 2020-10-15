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
            [period(i),amplitude(i)] = periodicity(events,channels{i},field,true,co(i,:));
        end
    end
    %% Write output data
    eeg_periodicity_data(num_files).setname = eeg_data.setname;
    eeg_periodicity_data(num_files).n = numel(channels);
    eeg_periodicity_data(num_files).channels = channels;
    eeg_periodicity_data(num_files).period = hours(period);
    eeg_periodicity_data(num_files).amplitude = amplitude;
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
[file,path] = uiputfile('*.mat','Select output file','eeg_periodicity.mat');
if file ~= 0
    save([path,file],'eeg_periodicity_data');
end