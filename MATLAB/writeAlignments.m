function writeAlignments(inputDir, state, firstObserved, outputDir)
%WRITEALIGNMENTS Write alignments of sleep/wake timeseries data
%   Usage: WRITEALIGNMENTS(INPUTDIR, STATE, FIRSTOBSERVED, OUTPUTDIR)
%          WRITEALIGNMENTS(INPUTDIR, STATE, FIRSTOBSERVED)
%          WRITEALIGNMENTS(INPUTDIR, STATE)
%
%   This function looks into the INPUTDIR directory, finds all .xlsx files
%   there, and breaks the data contained therein into sub-series, so that
%   each sub-series starts at the specified STATE (one of 'REM', 'nREM',
%   'Awake' or 'Trans'). The resulting data is written to a file in the
%   directory OUTPUTDIR (if not specified, then the current directory).
%   By default, the series are split at the first transition to the given
%   state, but if FIRSTOBSERVED is true, then the first occurrence of that
%   state is chosen instead.

if nargin < 4
    outputDir = pwd;
    if nargin < 3
        firstObserved = false;
    end
end

% Assume that the python interpreter has been set correctly
py.neonatal_sleep.utils.write_alignment.create_alignments(...
    inputDir, state, firstObserved, outputDir);
fprintf('Alignments written\n');
end