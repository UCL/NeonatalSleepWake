% Read in data
set_filename = uigetfile('*.set','Select a .set file');
if set_filename == 0
    error('No .set file selected')
end
eeg_data = pop_loadset(set_filename);
%%
channels = extractfield(eeg_data.chanlocs, 'labels');
[index,tf] = listdlg('ListString',channels,'Name','Select channel(s)');
channels = channels(index);
%%
test_process_bursts
events = process_bursts(eeg_data,channels);
%%
% Plot the events by duration as function of time
plot_events(events,'duration',channels);
%%
% Plot the events by power as function of time
plot_events(events,'power',channels);
%%
% Plot the events by power normalised by the duration as a function of time
plot_events(events,'power_n',channels);
%%
for i = 1:numel(channels)
    periodicity(events,channels{i},true);
end