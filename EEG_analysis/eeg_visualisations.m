%% Run tests
runtests('test_process_bursts.m');
%% Set initial values
field_index = 1;
channel_index = 1;
execute_loop = true;
%% Loop over multiple files
while execute_loop
    %% Read in data
    eeg_data = pop_loadset();
    if isempty(eeg_data)
        error('No .set file selected')
    end
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
    co = get(gca,'colororder');
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
    if ~isempty(field)
        for i = 1:numel(channels)
            periodicity(events,channels{i},field,true,co(i,:));
        end
    end
    %% GUI to exit the loop
    % Exit unless the user clicks on 'Yes'
    answer = questdlg('read another file?');
    switch answer
        case 'Yes'
            execute_loop = true;
        otherwise
            execute_loop = false;
    end
    %%
end