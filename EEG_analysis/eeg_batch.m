% This script processes EEG data from eeglab, performs periodicity analysis
% on it and saves the results in a .mat file. To get started, run it and
% follow the GUI windows that pop up to give inputs and/or options. NOTE:
% You can select multiple input files at the beginning, but only if they
% are in the same directory.
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
    i1 = strfind(eeg_periodicity_data(ifile).setname,'BRUK');
    i2 = strfind(eeg_periodicity_data(ifile).setname,'_day');
    eeg_periodicity_data(ifile).BRUK = str2double(eeg_periodicity_data(ifile).setname(i1+4:i2-1));
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