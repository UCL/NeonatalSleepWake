data = test_data(100);
events = process_bursts(data,'T1');
assert(abs(events.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.power)]);
events = process_bursts(data,'T2');
assert(abs(events.power - 0.0) < eps, ['Expected 0.0 V^2, got ',num2str(events.power)]);
events = process_bursts(data,'T3');
assert(abs(events.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.power)]);
disp('Test passed!')