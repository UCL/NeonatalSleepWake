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
params.dt = mean(diff(data.Time), 'omitnan');

light_events = detect_light_events(data, params);
movement_events = detect_movement_events(data, params, light_events);
stats = movement_event_statistics(data, movement_events,...
    'visualize',false,'baseline',0);

reference_n_events = [NaN,2,4,6];

assert(isempty(light_events.onset), ...
    ['Expected no light events, got ' num2str(numel(light_events.onset))]);

for i = 2:4
    y = varnames{i};
    n = reference_n_events(i);
    ns = num2str(n);
    assert(movement_events.(y).n_events == n, ...
        ['Expected ' ns ' events in ' y ', got ' num2str(movement_events.(y).n_events)]);
    assert(all(stats.(y).median < 1), ...
        ['Expected median of ' y ' < 1, got ', num2str(max(stats.(y).median))])
    assert(all(stats.(y).mean < 1), ...
        ['Expected mean of ' y ' < 1, got ', num2str(max(stats.(y).median))])
    assert(all(stats.(y).p25 < stats.(y).median), ...
        ['Expected 25th percentile < median of ' y])
    assert(all(stats.(y).p75 > stats.(y).median), ...
        ['Expected 75th percentile > median of ' y])
end