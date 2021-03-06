function data = test_data(N)
% function data = test_data(N)
%
% Create an eeglab-like data structure for testing.
% Inputs:
%    - N: number of points in time series
% Outputs
%    - data: eeglab-like data structure

data = struct();

data.srate = 1e3;

data.times = 1:N; % in ms
data.data = [ones(1,N);zeros(1,N);ones(1,N)*-1;ones(1,N)] * 1e6; % In microvolt

data.event(1).type = 'T1_burst';
data.event(1).latency = 3; % In sampling points
data.event(1).duration = 10; % In sampling points

data.event(2).type = 'T2_burst';
data.event(2).latency = 75; % In sampling points
data.event(2).duration = 10; % In sampling points

data.event(3).type = 'T3_burst';
data.event(3).latency = 33; % In sampling points
data.event(3).duration = 10; % In sampling points

data.event(4).type = 'T4_burst';
data.event(4).latency = 33; % In sampling points
data.event(4).duration = 10; % In sampling points

data.event(5).type = 'T4_burst';
data.event(5).latency = 33; % In sampling points
data.event(5).duration = 7; % In sampling points

data.chanlocs(1).labels = 'T1';
data.chanlocs(2).labels = 'T2';
data.chanlocs(3).labels = 'T3';
data.chanlocs(4).labels = 'T4';

end