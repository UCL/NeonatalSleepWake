% This script processes EEG data from eeglab, performs periodicity analysis
% on it and saves the results in a .mat file. To get started, run it and
% follow the GUI windows that pop up to select which variable to analyse
% for periodicity, which files to read and where to save the output.
% NOTE: 
% You can select multiple input files, but only if they are in the same
% directory.

%% Run tests
runtests('test_process_bursts.m');
%% Get initial values
eeg_periodicity_data = struct();
fields = {'latency','duration','power','power_n'};
[field_index,tf] = listdlg('ListString',fields,...
    'SelectionMode','single',...
    'PromptString','Select field for frequency analysis',...
    'ListSize',[300,300]);
if tf == 0
    error('No field selected')
else
    field = fields{field_index};
end
%% Get file names for I/O
[in_file_names,in_path_name] = uigetfile('*.set','Select input files','multiselect','on');
[out_file_name,out_path_name] = uiputfile('*.mat','Select output file','eeg_periodicity.mat');
if ~iscell(in_file_names)
    in_file_names = {in_file_names};
end
for ifile = 1:numel(in_file_names)
    %% Read file
    filename = in_file_names{ifile};
    eeg_data = pop_loadset([in_path_name,filename]);
    channels = extractfield(eeg_data.chanlocs,'labels');
    %% Process events
    events = process_bursts(eeg_data,channels);
    
    %% Do periodicity analysis
    n = numel(channels);
    period = zeros(n,1);
    amplitude = zeros(n,1);   
    for i = 1:n
        [period(i),amplitude(i)] = periodicity(events,channels{i},field,'verbose',false,'window',[0.2 5.0]);
    end
    
    %% Write output data
    eeg_periodicity_data(ifile).setname = eeg_data.setname;
    % To parse the dataset identifier and its prefix, we use regexp to look
    % for the first (int or float) number in the set name. Once it's found,
    % check that it's a finite number and take everything before it as the
    % prefix. 
    expression = '[0-9]+\.*[0-9]*';
    [i1, i2] = regexp(eeg_data.setname,expression);
    id_value = str2double(eeg_periodicity_data(ifile).setname(i1(1):i2(1)));
    assert(isnumeric(id_value) && isfinite(id_value), ...
        ['Failed to parse set ID from set name, got ',id_value, ' instead of a number']);
    eeg_periodicity_data(ifile).id_prefix = eeg_periodicity_data(ifile).setname(1:i1(1) - 1);
    eeg_periodicity_data(ifile).id = id_value;
    %
    eeg_periodicity_data(ifile).nchannels = numel(channels);
    eeg_periodicity_data(ifile).npoints = eeg_data.pnts;
    eeg_periodicity_data(ifile).deleted_fraction = get_deleted_fraction(eeg_data);
    eeg_periodicity_data(ifile).channels = channels;
    eeg_periodicity_data(ifile).period = hours(period);
    eeg_periodicity_data(ifile).amplitude = amplitude;
    [eeg_periodicity_data(ifile).corrcoef_r, ...
        eeg_periodicity_data(ifile).corrcoef_p] = get_corr_coefs(events, channels);
    [eeg_periodicity_data(ifile).mean_power,...
        eeg_periodicity_data(ifile).median_power] = ...
        get_power_statistics(events, channels, 'normalised', true);
    eeg_periodicity_data(ifile).power_statistics_type = 'normalised';

end
%% Write output in a file
if out_file_name ~= 0
    save([out_path_name,out_file_name],'eeg_periodicity_data');
end