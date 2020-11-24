% Run tests on process_bursts().
% The first three tests test the power integration.
% The fourts test tests duplicate event removal.
% More to be added when necessary.
data = test_data(100);
events = process_bursts(data,{'T1','T2','T3','T4'});
assert(abs(events.T1.power - 1e10)/events.T1.power < eps, ...
    ['Expected 0.01 V^2, got ',num2str(events.T1.power, '%8.4e')]);
assert(abs(events.T2.power - 0.0)/events.T1.power < eps, ...
    ['Expected 0.0 V^2, got ',num2str(events.T2.power, '%8.4e')]);
assert(abs(events.T3.power - 1e10)/events.T1.power < eps, ...
    ['Expected 0.01 V^2, got ',num2str(events.T3.power, '%8.4e')]);
assert(events.T4.n == 1, ['Expected 1 event for T4, got ',num2str(events.T4.n),...
    '. Duplicate events should get removed by remove_duplicate_events()'])