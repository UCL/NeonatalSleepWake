# NeonatalSleepWake

## EEG_analysis

### Installation

To use the scripts and functions in EEG_analysis, clone this git repository (click the big green button on the top right of this page). Then, in Matlab, add the path to the EEG_analysis directory into the path variable with the `addpath` function.

### Dependencies

These scripts require MATLAB 2019b or later.

### Usage

The user should mostly interact with the scripts [eeg_visualisations.m](EEG_analysis/eeg_visualisations.m), [eeg_batch.m](EEG_analysis/eeg_batch.m) and [development_outcome_correlation.m](EEG_analysis/development_outcome_correlation.m). See the comments in each file or use the `help` function in MATLAB for more details on their purpose. The scripts can be launched on the command line, or in the editor. They will open GUI windows when user input is required.

For more information on each script and function, use the `help` function in MATLAB. For example: `help eeg_batch` or `help periodicity`.

#### Workflow

1. Run [eeg_visualisations.m](EEG_analysis/eeg_visualisations.m) or [eeg_batch.m](EEG_analysis/eeg_batch.m) to process data in [eeglab file(s)](https://liveuclac.sharepoint.com/:f:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/test_data?csf=1&web=1&e=NeHgjF). [eeg_visualisations.m](EEG_analysis/eeg_visualisations.m) will produce visualisations from each file while [eeg_batch.m](EEG_analysis/eeg_batch.m) will go through multiple files more quickly. When the script has finished, it will ask you to save the data to a `.mat` file.

2. Run [development_outcome_correlation.m](EEG_analysis/development_outcome_correlation.m) to produce a table that combines the results from the previous step with outcome scores read in from an [MS Excel file](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/BRUK_anonymised_num.xlsx?d=w937f7d45efe542d2ba6fa6156d8baee7&csf=1&web=1&e=7FDbLa). The output will be saved into another MS Excel file with a row for each child and a column for each channel/variable combination.


#### Example files

- [eeglab file(s)](https://liveuclac.sharepoint.com/:f:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/test_data?csf=1&web=1&e=NeHgjF)
- [Development outcome Excel file](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/BRUK_anonymised_num.xlsx?d=w937f7d45efe542d2ba6fa6156d8baee7&csf=1&web=1&e=7FDbLa)
- [Combined Excel file](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/test_data/outcome_table.xlsx?d=w65b5c8e8b9fb4f73bf681d51636cbd63&csf=1&web=1&e=yjdwIL)

#### eeg_visualisations.m

This script plots 

- a [stem plot](https://uk.mathworks.com/help/matlab/ref/stem.html) of the duration, power and normalised power of all events for the chosen channel(s)
- a [fft spectrum](https://uk.mathworks.com/help/matlab/ref/fft.html) for the selected variable (latency, duration, power, normalised power) for the chosen channel(s)
- a [cwt scalogram](https://uk.mathworks.com/help/wavelet/ref/cwt.html) for the selected variable for the chosen channel(s)

It will loop over multiple files if selected by the user. The results will be saved in a MATLAB struct into a `.mat` file at the end.

#### eeg_batch.m

This scripts loops over multiple files, processes events from all channels and performs the same analysis as [eeg_visualisations.m](EEG_analysis/eeg_visualisations.m) but does not display the plots. The results will be saved in a MATLAB struct into a `.mat` file at the end.

#### development_outcome_correlation.m

This script combines the results saved by [eeg_batch.m](EEG_analysis/eeg_batch.m) with outcome scores read in from an [MS Excel file](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/BRUK_anonymised_num.xlsx?d=w937f7d45efe542d2ba6fa6156d8baee7&csf=1&web=1&e=7FDbLa). The output will be saved into another MS Excel file with a row for each child and a column for each channel/variable combination.

*TODO*: The correlation matrix is not yet computed automatically. It could be done with something like `corrcoef(X,Y,'rows','complete')`. For now it is left to the user to do manually.
