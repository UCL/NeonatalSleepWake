function frac = get_deleted_fraction(eeg_data)
% function frac = get_deleted_fraction(eeg_data)
%
% Calculate the fraction of sample points that have been removed due to bad
% data (labeled as "boundary" events).
% Inputs:
%    - eeg_data: data from eeglab .set file
% Outputs:
%    - frac: fraction of deleted sample points

type = extractfield(eeg_data.event,'type');
duration = extractfield(eeg_data.event,'duration');

boundary_id = logical(count(type,'boundary'));
boundary_duration = seconds(sum(duration(boundary_id)) / eeg_data.srate);
remaining_duration = seconds(eeg_data.times(end) / 1e3);

frac = boundary_duration/(remaining_duration + boundary_duration);

end