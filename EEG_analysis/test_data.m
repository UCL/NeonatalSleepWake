function data = test_data(N)

data = struct();

data.times = 1:N;
data.data = [ones(1,N);zeros(1,N);ones(1,N)*-1] * 1e6; % In microvolt

data.event(1).type = 'T1_burst';
data.event(1).latency = 3; % In ms
data.event(1).duration = 10; % In ms

data.event(2).type = 'T2_burst';
data.event(2).latency = 75; % In ms
data.event(2).duration = 10; % In ms

data.event(3).type = 'T3_burst';
data.event(3).latency = 33; % In ms
data.event(3).duration = 10; % In ms

data.chanlocs(1).labels = 'T1';
data.chanlocs(2).labels = 'T2';
data.chanlocs(3).labels = 'T3';

data.srate = 1e3;

end