%% Read excel table
[filename,pathname] = uigetfile('*.xls*');
T = readtable([pathname,filename]);
t = T(:,{'BRUK','Shankaran_num','Cog','Lang_interp','Motor_interpolated'});
% [ ] change t to something more descriptive
t_data = t{:,:};
%% Read data from eeg_visualisations
uiopen('load');
%% Add columns for period and amplitude to the table
n = size(t,1);
% Find unique channel names
c = extractfield(eeg_periodicity_data,'channels');
unique_channels = unique(cat(2,c{:}));
% Create a column for each channel
for i = 1:numel(unique_channels)
    channel = unique_channels{i};
    t.([channel, '_period']) = NaN(n,1);
    t.([channel, '_amplitude']) = NaN(n,1);
end
for i = 1:numel(eeg_periodicity_data)
    data = eeg_periodicity_data(i);
    for j = 1:data.nchannels
        channel = data.channels{j};
        field_p = [channel,'_period'];
        field_a = [channel,'_amplitude'];
        t.(field_p)(t.BRUK == data.BRUK) = hours(data.period(j));
        t.(field_a)(t.BRUK == data.BRUK) = data.amplitude(j);
    end
end
%% TODO: Get correlation coefficients
