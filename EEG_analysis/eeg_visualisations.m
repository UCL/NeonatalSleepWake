% Read in data
eeg_data = pop_loadset();
if isempty(eeg_data)
    error('No .set file selected')
end
% [] Run this script in a loop over multiple files
%%
% Channel selection GUI
channels = extractfield(eeg_data.chanlocs, 'labels');
[index,~] = listdlg('ListString',channels,'Name','Select channel(s)');
channels = channels(index);
%%
% Process the data for plotting
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
% Field selection GUI
fields = {'latency','duration','power','power_n'};
[index,~] = listdlg('ListString',fields,...
    'SelectionMode','single',...
    'Name','Select field for frequency analysis');
field = fields{index};
%%
for i = 1:numel(channels)
    periodicity(events,channels{i},field,true);
end