function writeAlignments(inputDir, state, firstObserved, leadIn, outputDir)
%WRITEALIGNMENTS Write alignments of sleep/wake timeseries data
%   Usage: WRITEALIGNMENTS(INPUTDIR, STATE_OR_STIM, FIRSTOBSERVED, LEADIN, OUTPUTDIR)
%          WRITEALIGNMENTS(INPUTDIR, STATE_OR_STIM, FIRSTOBSERVED, LEADIN)
%          WRITEALIGNMENTS(INPUTDIR, STATE_OR_STIM)
%
%   This function looks into the INPUTDIR directory, finds all .xlsx files
%   there, and breaks the data contained therein into sub-series, so that
%   each sub-series starts at the specified state or stimulus
%   (STATE_OR_STIM must be one of 'REM', 'nREM', 'Awake', 'Trans',
%   'Painful_stimulation', 'Somatosensory_stimulation', or 'Held').
%   The resulting data is written to a file in the
%   directory OUTPUTDIR (if not specified, then the current directory).
%   By default, the series are split at the first transition to the given
%   state, but if FIRSTOBSERVED is true, then the first occurrence of that
%   state is chosen instead.
%   To have each sub-series start N epochs before the given state or
%   stimulus occurs, use that as the value of the LEADIN parameter
%   (by default, 0).

if nargin < 5
    outputDir = pwd;
    if nargin < 4
        firstObserved = false;
        if nargin < 3
            leadIn = 0;
        end
    end
end

% Assume that the python interpreter has been set correctly
py.neonatal_sleep.utils.write_alignment.create_alignments(...
    inputDir, state, firstObserved, leadIn, outputDir);
fprintf('Alignments written\n');
end