function [prefix,id] = parse_id_and_prefix(eeg_data)

% To parse the dataset identifier and its prefix, we use regexp to look
% for the first (int or float) number in the set name. Once it's found,
% check that it's a finite number and take everything before it as the
% prefix.
expression = '[0-9]+\.*[0-9]*';
[i1, i2] = regexp(eeg_data.setname,expression);
id = str2double(eeg_data.setname(i1(1):i2(1)));
assert(isnumeric(id) && isfinite(id), ...
    ['Failed to parse set ID from set name, got ',id, ' instead of a number']);
prefix = eeg_data.setname(1:i1(1) - 1);