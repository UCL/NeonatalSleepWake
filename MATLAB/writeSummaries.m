function writeSummaries(inputDir)
%WRITESUMMARIES Write summaries of sleep/wake timeseries data
%   Usage: WRITESUMMARIES(INPUTDIR)
%
%   This function looks into the INPUTDIR directory and writes a summary
%   of all  .xlsx files found there, saving it in a file called
%   "summary_all.csv".
%   The summary contains one row for each experiment (file), and includes
%   information about how much time the patient spent in different sleep
%   states in that experiment.

% Assume that the python interpreter has been set correctly
py.neonatal_sleep.utils.write_summaries.main(inputDir);
fprintf('Summaries written\n');
end

