data = test_data(100);
events = process_bursts(data,{'T1','T2','T3'});
assert(abs(events.T1.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.T1.power)]);
assert(abs(events.T2.power - 0.0) < eps, ['Expected 0.0 V^2, got ',num2str(events.T2.power)]);
assert(abs(events.T3.power - 0.01) < eps, ['Expected 0.01 V^2, got ',num2str(events.T3.power)]);
disp('Test passed!')