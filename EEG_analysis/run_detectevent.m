%% Run tests
runtests('test_detectevent.m')
%% Read in EEG data
eeg_data = pop_loadset();
%% Select channels
channel_index = 1;
channels = extractfield(eeg_data.chanlocs,'labels');
[channel_index,tf] = listdlg('ListString',channels,...
    'PromptString','Select channel(s)',...
    'InitialValue',channel_index);
nchannels = numel(channel_index);
%% Run pop_detectevent for each channel
% Note: Events longer than 'max' duration will not be detected whatsoever.
promptstr    = { 'Transformation to apply to the data (none is ok)' ...
    'Moving window to apply transformation in s (default all data)' ...
    'Threshold on thansformed data in standard dev.' ...
    'Min and max event duration above threshold (in s)' ...
    'Min time between events (in s)' ...
    'Event type' };
inistr       = { '@rmsave' '-0.4 0.4' '1.5' '0.5 20' '0.5' 'burst' };
result       = inputdlg2(promptstr, 'Detect events -- pop_detectevent()', 1,  inistr, 'pop_detectevent');

for ichan = 1:nchannels

    disp(['processing channel ' channels{channel_index(ichan)}])
    eeg_data = pop_detectevent(eeg_data, ...
        'channels', channel_index(ichan), ...
        'transform', result{1}, ...
        'transwin', str2num(result{2}), ...
        'threshold', str2num(result{3}), ...
        'eventwin', str2num(result{4}), ...
        'eventdiff', str2num(result{5}), ...
        'eventname', [channels{channel_index(ichan)}, '_', result{6}]);
end
%% Save output
[out_file_name,out_path_name] = uiputfile('*.set','Select output file',...
    [eeg_data.setname '_bursts.set']);
pop_saveset(eeg_data,'savemode','twofiles',...
    'filename',out_file_name,...
    'filepath',out_path_name);