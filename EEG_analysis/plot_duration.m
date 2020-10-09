function fig = plot_duration(filename, types_in, optional_frequency)

% Plot burst durations by type of burst with latency on the x-axis
% Arguments
% filename : name of csv file with burst data
% types_in : cell array of type names
% optional_frequency : [optional] frequency of data sampling (default 250Hz)

if(nargin > 2)
    frequency = optional_frequency;
else
    frequency = 250.0;
end

if iscell(types_in)
    types = types_in;    
elseif ischar(types_in) || isstring(types_in)
    types = {types_in};
else
    error('Types must be a string or a cell array');
end

assert(ischar(filename) || isstring(filename), 'Filename must be a string')

data = readtable(filename);

fig = figure(1);
clf;
hold on

for i = 1:numel(types)
    burst_type = types{i};
    assert(ischar(burst_type) || isstring(burst_type))
    burst_id = logical(count(data.type,burst_type));
    data_slice = data(burst_id,:);
    stem(data_slice.latency / frequency, data_slice.duration / frequency)
end

legend(types)
xlabel('latency (s)')
ylabel('Duration (s)')
box on
grid on

end