% Read in data
%csv_filename = 'BRUK12.csv';
%set_filename = 'data/BRUK19_day4to5_01.37.43_01.37.43_noECG.set';
set_filename = 'data_small/BRUK12_day4_07.27.43_08.35.43.set';
eeg_data = pop_loadset(set_filename);
channels = {'O2','C4'};
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