function plotHypnogram(inputFile, state, firstJump)
%PLOTHYPNOGRAM Make a hynogram for an experiment
%   Usage: PLOTHYPNOGRAM(INPUTFILE, STATE, FIRSTJUMP)
%          PLOTHYPNOGRAM(INPUTFILE, STATE)
%
%   This function creates a hypnogram for the experiment stored in the file
%   INPUTFILE. Some of the data can be excluded from the plot by specifying
%   the STATE argument: the resulting plot will ignore any data before that
%   state is encountered. STATE must be one of "REM", "nREM", "Awake" or
%   "Trans".
%
%   Additionally, if FIRSTJUMP is specified and true,
%   the code will look for a transition to that state, and exclude all data
%   before one is found. If FIRSTJUMP is not specified, or it is false,
%   then the code will look for any occurrence of the state.
%
%   The plot will be saved in EPS format in the current directory, even if
%   that is different from where the input file is located.

if nargin < 3
    firstJump = false;
end

load_results = py.neonatal_sleep.load_file.load_file(inputFile);
data = load_results{1};
metadata = load_results{2};
exp = py.neonatal_sleep.experiment.Experiment(data, metadata);

% Assume that the python interpreter has been set correctly
py.neonatal_sleep.utils.plotting.plot_hypnogram(...
    exp, state, firstJump);
fprintf('Alignments written\n');
end