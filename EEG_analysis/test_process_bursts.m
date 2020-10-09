events = process_bursts('test','T1');
assert(abs(events.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.power)]);
events = process_bursts('test','T2');
assert(abs(events.power - 0.0) < eps, ['Expected 0.0 V^2, got ',num2str(events.power)]);
events = process_bursts('test','T3');
assert(abs(events.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.power)]);
disp('Test passed!')