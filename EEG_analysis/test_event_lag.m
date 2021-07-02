source = struct();
target = struct();
source.latency = [1.,2.,3.,4.,5.];
source.n = numel(source.latency);
target.latency = [1.5, 3.5, 9.0];
target.n = numel(target.latency);

lag1 = event_lag(source, target);
lag2 = event_lag(target, source);

ref1 = [0.5, 1.5, 0.5, 5.0, 4.0];
ref2 = [0.5, 0.5];

assert( all(lag1 == ref1) )
assert( all(lag2(1:2) == ref2) && isnan(lag2(3)) )