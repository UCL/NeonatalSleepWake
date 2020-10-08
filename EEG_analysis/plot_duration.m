function fig = plot_duration(filename, types_in)

% Plot burst durations by type of burst with latency on the x-axis
% Arguments
% filename : name of csv file with burst data
% types : cell array of type names


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
    burst_id = logical(count(data.type,burst_type));
    data_slice = data(burst_id,:);
    stem(data_slice.latency, data_slice.duration)
end

legend(types)
xlabel('latency (?)')
ylabel('Duration (s)')
box on
grid on

end