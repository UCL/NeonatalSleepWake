N = 4;
npnts = 1000;
x = linspace(0,N*pi, npnts);
y = [sin(x); sin(2*x); sin(3*x)];

data = struct();
events = cell(3,1);

data.setname = 'TEST1';
data.pnts = npnts;
data.nbchan = 3;
data.srate = 20;
data.times = x;
data.data = y;
data.event = [];

for ichn = 1:3
    events{ichn} = pop_detectevent(data,...
        'channels', ichn, ...
        'transform', '@rmsave', ...
        'transwin', [-0.4 0.4], ...
        'threshold', 1.5, ...
        'eventwin', [0.5 20], ...
        'eventdiff', 0.5, ...
        'eventname', ['test' num2str(ichn)]);
end

assert(numel(events{1}.event) == 4)
assert(numel(events{2}.event) == 8)
assert(numel(events{3}.event) == 12)

assert(events{1}.event(1).latency == 38)
assert(events{1}.event(1).duration == 176)
assert(events{2}.event(1).latency == 18)
assert(events{2}.event(1).duration == 91)
assert(events{3}.event(1).latency == 11)
assert(events{3}.event(1).duration == 63)