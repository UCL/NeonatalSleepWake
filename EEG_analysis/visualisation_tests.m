%csv_filename = 'BRUK12.csv';
set_filename = 'data/BRUK19_day4to5_01.37.43_01.37.43_noECG.set';
%%
%csv_data = readtable(csv_filename);
eeg_data = pop_loadset(set_filename);
%%
plot_events(eeg_data,'duration',{'O2','C4'});
%%
plot_events(eeg_data,'power',{'O2','C4'});
%%
plot_events(eeg_data,'power_n',{'O2','C4'});
%%
events_by_channel = get_events_by_channel(eeg_data)
%%
events = process_bursts(eeg_data,'O2')
%%
test_process_bursts
%%
periodicity(eeg_data,'O2',true)