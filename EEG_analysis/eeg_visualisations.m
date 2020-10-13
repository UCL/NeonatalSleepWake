% Read in data
%csv_filename = 'BRUK12.csv';
set_filename = 'data/BRUK19_day4to5_01.37.43_01.37.43_noECG.set';
eeg_data = pop_loadset(set_filename);
%%
events_by_channel = get_events_by_channel(eeg_data)
%%
events = process_bursts(eeg_data,'O2')
%%
test_process_bursts
%%
% Plot the events by duration as function of time
plot_events(eeg_data,'duration',{'O2','C4'});
%%
% Plot the events by power as function of time
plot_events(eeg_data,'power',{'O2','C4'});
%%
% Plot the events by power normalised by the duration as a function of time
plot_events(eeg_data,'power_n',{'O2','C4'});
%%
periodicity(eeg_data,'F4',true);