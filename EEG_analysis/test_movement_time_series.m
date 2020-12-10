N = 4;
npnts = 1000;
x = linspace(0,N*pi, npnts);
y1 = sin(x);
y2 = sin(2*x);
y3 = sin(3*x);

varnames = {'Time','y1','y2','y3'};

data = table(x',y1',y2',y3', 'VariableNames',varnames);

params = struct();
params.movement_threshold_std = 1;
params.light_threshold_std = 2;
params.duration_limit = 40 * 1e-3;
params.interval_limit = 10 * 1e-3;
params.period_after_end = 50 * 1e-3;
params.dt = mean(diff(data_table.Time), 'omitnan');

light_events = detect_light_events(data, params);
movement_events = detect_movement_events(data, params, light_events);

assert(isempty(light_events.onset), ['Expected no light events, got ' num2str(numel(light_events.onset))]);
assert(movement_events.y1.n_events == 2, ['Expected 2 events in y1, got ' num2str(movement_events.y1.n_events)]);
assert(movement_events.y2.n_events == 4, ['Expected 4 events in y2, got ' num2str(movement_events.y2.n_events)]);
assert(movement_events.y3.n_events == 6, ['Expected 6 events in y3, got ' num2str(movement_events.y3.n_events)]);