# NeonatalSleepWake

## EEG_analysis

### Installation

To use the scripts and functions in EEG_analysis, clone this git repository (click the big green button on the top right of this page). Then, in Matlab, add the path to the EEG_analysis directory into the path variable with the `addpath` function.

### Dependencies

These scripts require MATLAB 2019b or later. They require [eeglab](https://sccn.ucsd.edu/eeglab/index.php) to be installed and the installation directory added to the MATLAB path.

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

## Video Time Series analysis

### Usage

The user should mostly intereact with the scripts [movement_time_series.m](EEG_analysis/movement_time_series.m) and [multi_movement_time_series.m](EEG_analysis/multi_movement_time_series.m). See the comments in each file or use the `help` function in MATLAB for more details on their purpose. The scripts can be launched on the command line, or in the editor. They will open GUI windows when user input is required.

#### Workflow 1

1. Run [movement_time_series.m](EEG_analysis/movement_time_series.m) to process data processed from a video recording in [a csv file](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/December%202020/Video%20time%20series/Video%20time%20series%20from%20%27clean%27%20videos/311103/Final%20time%20series%20for%20movements/VCD_311103_c_0.5thres_sum.csv?d=w5698ff9a41054cbf922658e040dcf723&csf=1&web=1&e=HHjkNP).
2. Some automatic tests will run first, you can ignore those as long as it says "1 Passed, 0 Failed, 0 Incomplete"
3. You first select a csv file to read through a dialog box
4. You then select the parameters for the detection through a dialog box.
- The default parameters are already set, so you can just click 'ok' if you don't want to change anything
- In each field, you can either set a single value OR one value per "real" (non-control) time series. You should get warnings if you set the wrong number of parameters.
5. The script will then plot two (sets of) figures
- The time series and detected events
- The median of all detected events with the standard error shown by a shaded red area. In these plots, all events will be normalized to the duration of the longest event and some time before and after the event will be included in a gray shaded area.		
- If there is a time series with the word 'control' in the label in the csv file, it will be interpreted as a noise signal and subtracted from the "body" time series. The data in the control is normalized with the ratio of the means of the series and the control. The first control series in the table will be used by default (but you can change this)
6. Summary statistics from the detected events will be printed on screen.
7. You then read an eeglab data set to import the events into
8. You then select where to write the eeglab dataset with the imported events.

#### Workflow 2

1. Run [multi_movement_time_series.m](EEG_analysis/multi_movement_time_series.m) to process data processed from a video recording in [multiple csv files](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/December%202020/Video%20time%20series/Video%20time%20series%20from%20%27clean%27%20videos/311103/Final%20time%20series%20for%20movements/VCD_311103_c_0.5thres_sum.csv?d=w5698ff9a41054cbf922658e040dcf723&csf=1&web=1&e=HHjkNP).
2. Some automatic tests will run first, you can ignore those as long as it says "1 Passed, 0 Failed, 0 Incomplete"
3. You first select one or more csv files to read through a dialog box. Due to features of Matlab, these have to be in the same directory.
4. You then select the parameters for the detection through a dialog box.
- The default parameters are already set, so you can just click 'ok' if you don't want to change anything
- In each field, you can either set a single value OR one value per "real" (non-control) time series. You should get warnings if you set the wrong number of parameters.
5. The script will then plot a figure of the median of all detected events with the standard error shown by a shaded red area. In these plots, all events will be normalized to the duration of the longest event and some time before and after the event will be included in a gray shaded area.
6. Summary statistics from the detected events will be printed on screen.

#### Example files

- [csv files](https://liveuclac.sharepoint.com/:x:/r/sites/NeonatalSleepWakeModelling/Shared%20Documents/Tuomas/December%202020/Video%20time%20series/Video%20time%20series%20from%20%27clean%27%20videos/311103/Final%20time%20series%20for%20movements/VCD_311103_c_0.5thres_sum.csv?d=w5698ff9a41054cbf922658e040dcf723&csf=1&web=1&e=HHjkNP)

#### movement_time_series.m

This script processes time series that contain pixel change rates processed from video clips. It detects movement events and light events and plots the time series with the events highlighted. It then plots the median of all events normalized to the same start and end time, and displays statistical information about the events.

#### multi_movement_time_series.m

This script processes multiple time series that contain pixel change rates processed from video clips. It detects movement events and light events. It then plots the median of all events normalized to the same start and end time, and displays statistical information about the events.
