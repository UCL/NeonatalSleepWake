function frac = get_deleted_fraction(eeg_data)

type = extractfield(eeg_data.event,'type');
duration = extractfield(eeg_data.event,'duration');

boundary_id = logical(count(type,'boundary'));
boundary_duration = seconds(sum(duration(boundary_id)) / eeg_data.srate);
remaining_duration = seconds(eeg_data.times(end) / 1e3);

frac = boundary_duration/(remaining_duration + boundary_duration);

end