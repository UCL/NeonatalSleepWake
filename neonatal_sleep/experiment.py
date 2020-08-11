import datetime
import os
import warnings

import numpy as np
import pandas as pd

from .common import AlignmentError, check_state, check_stimulus
from .load_file import load_file


class Experiment:
    """A class to represent the results from an individual patient.

    An Experiment is created by passing it the underlying data and metadata.
    However, most of the information it provides is retrieved by considering
    the data in chunks called runs, representing a set of continuous epochs
    spent in the same state. These runs are computed when the experiment is
    first created.

    Experiments are designed so that they can be aligned to a desired state
    (see the `start_at_state` method for more options for doing so).
    This means splitting the data into sub-series, such that each series starts
    with the specified state. Doing this may result in some of the early epochs
    being ignored (until the desired state is encountered). Once the alignment
    has been performed, statistics about the experimental data can be obtained
    through a number of methods (`count`, `durations`, etc). These accept an
    `alignment` argument to choose which sub-series of the data to consider.
    Alignments are counted starting with 0 for the first sub-series. If no
    `alignment` is specified, then the statistics returned refer to all subsets
    combined (but still excluding any states ignored by the alignment process).

    It is also possible to query the full dataset, without any alignment, in
    which case all epochs are considered. This can be achieved by not calling
    `start_at_state()`, or by calling `reset()` to undo any previous alignment.
    """
    def __init__(self, data, metadata):
        self._data = data
        self._metadata = metadata
        # Would this be convenient?
        for key, value in metadata.items():
            setattr(self, key, value)
        # Assume epochs last for 30 seconds
        self.epoch_duration_seconds = 30
        # Precompute some statistics
        self._runs = self._compute_sojourns(0, len(self._data))
        # Assume we want to use all the data
        self._start = 0  # which data row to start reading from
        self._runs_start = 0  # which run to start reading from
        self._breakpoints = []  # where to break different alignments
        self._alignment_runs = []  # the runs for each alignment

    def number_epochs(self, alignment=None):
        """Return how many epochs are contained in this experiment.

        Can optionally consider only a subset of the data through the
        alignment argument, otherwise all data will be considered
        (excluding any that has been ignored through an alignment process).

        :param alignment: the index of a subseries to consider, as a zero-base
        integer, or None to consider the whole data.
        """
        return self._get_run_for_alignment(alignment).Duration.sum()

    def count(self, state, alignment=None):
        """Return how many times a sleep state occurs in this experiment."""
        check_state(state)
        considered_runs = self._get_run_for_alignment(alignment)
        return considered_runs[considered_runs.From == state].Duration.sum()

    def durations(self, state):
        """Compute how long the patient spends in the given state each time.

        Returns an array of durations in epochs.
        """
        check_state(state)
        # Filter only the runs of the state we want...
        runs = self._runs[self._runs.From == state].Duration
        # ...and only from the time of interest onwards
        return runs[self._runs_start:].values

    def count_transitions(self, from_states, to_states):
        """Return how many transitions occur between the given states.

        :param from_states: starting state names, as a list of strings
        :param to_states: target state names, as a list of strings
        """
        for state in from_states + to_states:
            check_state(state)
        matching = (self._runs.From.isin(from_states)
                    & self._runs.To.isin(to_states))
        # Return the number of transitions found in the region of interest
        return matching[self._runs_start:].sum()

    def summarise(self):
        """Get a summary of the information from this experiment."""
        summary = [
            self.Baby_reference, self.Start_time, self.Neonatal_unit_yes_no,
            self.High_risk_yes_no, self.Postnatal_age_days,
            self.Corrected_gestational_age_weeks
        ]
        # Time spent in each state
        # TODO Currently counts all durations, regardless of onset captured
        sleep_states = ["REM", "nREM", "Trans", "Awake"]
        sleep_states_no_trans = ["REM", "nREM", "Awake"]
        for state in sleep_states:
            percent_time = self.count(state) / self.number_epochs()
            mean_duration = np.mean(self.durations(state))
            summary.extend([percent_time, mean_duration])
        # State changes
        summary.append(self.count_transitions(sleep_states, sleep_states))
        summary.append(self.count_transitions(sleep_states_no_trans,
                                              sleep_states_no_trans))
        # Remaining summary data
        summary.append(self.number_epochs())
        summary.extend([
            self._data.Painful_stimulation_yes_no[self._runs_start:].sum() > 0,
            self._data.Somatosensory_stimulation_yes_no[self._runs_start:].sum() > 0,
            self._data.Held_yes_no[self._runs_start:].sum() > 0,
        ])
        return summary

    def _compute_sojourns(self, first_row, last_row):
        """Record how long we spend at each state and where we transition to.

        For an interval of interest, group together runs of the same sleep
        state, and record how long each of these last. Also record the state to
        which we jump, and the first and last epoch of each run.

        :first_row: the starting epoch of the interval to consider (zero-based)
        :last_row: the last epoch to consider (zero-based, inclusive)
        :return: a DataFrame containing aggregations of sleep states.
        """
        # Find the duration of all consecutive sequences in the dataframe
        # then store them as tuples of (state, duration) in a new series
        data = self._data[first_row:(last_row + 1)].copy()
        data["subgroups"] = (data.Sleep_wake != data.Sleep_wake.shift(1)).cumsum()
        runs = data.groupby("subgroups", as_index=False).apply(
            lambda x: (x.iloc[0, 0], len(x)))
        # Store this in a new dataframe, recording the state and how many
        # epochs were spent in it
        runs = pd.DataFrame({
            "From": [x[0] for x in runs],
            "Duration": [x[1] for x in runs]})
        # Now find what the next state is for each of these transitions
        # by checking the state at the total time spent so far
        # (we need reset_index to insert the states in the order given,
        # ignoring their index)
        jump_times = runs.Duration.cumsum()
        to_indices = jump_times[:-1]
        runs["To"] = data.iloc[to_indices, 0].reset_index(drop=True)
        # Also record the start and stop time of each run, for convenience
        # Each run lasts from Start until Stop, inclusive.
        # The jump_times are relative to the start of the interval, so we
        # need to add the first epoch to get absolute "times" (epoch numbers).
        runs["Start"] = first_row + jump_times.shift(1, fill_value=0)
        runs["Stop"] = first_row + jump_times - 1
        return runs

    def start_at_state(self, state, observed_start=True):
        """Shift the data so that it starts at the specified state.

        Epochs before this state is found will be ignored when retrieving
        statistics. If observed_start is True, epochs will be ignored until a
        transition to the given state is found. Otherwise, the first occurrence
        of the state will be taken as the start, even if it is the first epoch
        observed (and we therefore can't know how long the patient had been in
        that state already).

        Internally, this will find the appropriate points to "break" the data
        into sub-series, such that each series starts with the specified state
        and runs until its next occurrence.

        This method throws an AlignmentError if the specified alignment is not
        possible, such as if the desired starting state does not appear in the
        data. It throws SleepStateNotRecognisedError if an invalid state name
        is passed.

        :param state: the name of the state as a string (e.g. Awake, nREM)
        :param observed_start: if True, require that we know when the given
        has started, otherwise use its first occurrence
        :raises: AlignmentError, SleepStateNotRecognisedError
        """
        # Abort if state is not recognised
        check_state(state)
        # Find all instances of the given state
        matching_states = self._data.Sleep_wake == state
        # If there are none, report that and abort
        if not matching_states.any():
            raise AlignmentError(f"State {state} not found in data.")
        error_message = f"No transition to state {state} found in data."
        self._create_alignments(matching_states, observed_start, error_message)

    def start_at_stimulus(self, stimulus, observed_start=True):
        """Shift the data so that it starts at the specified stimulus.

        Epochs before this stimulus is found will be ignored when retrieving
        statistics. If observed_start is True, epochs will be ignored until a
        the start of the stimulus can be determined. Otherwise, the first
        occurrence of the stimulus will be taken as the start, even if it is
        the first epoch observed (and we therefore can't know how long the
        stimulus had lasted by then).

        Internally, this will find the appropriate points to "break" the data
        into sub-series, such that each series starts with the specified
        stimulus and runs until its next occurrence.

        This method throws an AlignmentError if the specified alignment is not
        possible, such as if the desired stimulus does not appear in the
        data. It throws StimulusNotRecognisedError if an invalid stimulus
        name is passed.

        :param stimulus: the name of the stimulus as a string (e.g. Held)
        :param observed_start: if True, require that we know when the given
        stimulus has started, otherwise use its first occurrence
        :raises: AlignmentError, SleepStateNotRecognisedError
        """
        # Abort if stimulus is not recognised
        check_stimulus(stimulus)
        column_name = f"{stimulus}_yes_no"
        # Find all instances of the given stimulus
        matching = self._data[column_name] == True
        # If there are none, report that and abort
        if not matching.any():
            raise AlignmentError(f"Stimulus {stimulus} not found in data.")
        error_message = (f"No occurrence of {stimulus} with a clear start "
                         f"found in data.")
        self._create_alignments(matching, observed_start, error_message)

    def _create_alignments(self, matching, observed_start, error_message):
        """Do the heavy lifting for creating alignments.

        :param matching: a boolean Series indicating which epochs should be chosen
        :param observed_start: see start_at_state / start_at_stimulus
        :param error_message: the message to accompany the error if no alignment
                              is possible
        """
        # Forget any previous alignment
        self._breakpoints.clear()
        self._alignment_runs.clear()
        # Group the epochs in question into contiguous runs of a sleep state
        # - Get the indices of all instances (adjust so epochs start from 0)
        inds = self._data[matching].index - 1
        # - Start the first run from the first index
        state_runs = []
        current_start = inds[0]
        current_index = inds[0]
        # - For each other index:
        for index in inds[1:]:
            # - If it differs by exactly 1 from the last number, add it
            if index == current_index + 1:
                current_index = index
            # - Otherwise, end the previous run
            #   and start a new one from this index
            else:
                state_runs.append((current_start, index - 1))
                current_start = current_index = index
        # - End the last run at the last observation
        state_runs.append((current_start, self._data.index[-1] - 1))
        # If we require knowing the start of a run but the first run starts
        # at the first observation, then discard it
        if observed_start and state_runs[0][0] == 0:
            state_runs.pop(0)
            # - If no runs remain, report that and abort
            if not state_runs:
                raise AlignmentError(error_message)
        # For each run:
        for (start, stop) in state_runs:
            # - Record the starting and stopping epoch of the alignment
            self._breakpoints.append((start, stop))
            # - Aggregate sleep states during the alignment
            subseries = self._compute_sojourns(start, stop)
            # - Store that aggregate so it can be retrieved by the index of the run
            self._alignment_runs.append(subseries)
        # Record the overall start of the alignment
        self._start_at_epoch(state_runs[0][0])

    def _start_at_epoch(self, epoch_number):
        """Specify which epoch we should consider at the first.

        Epochs from before epoch_number will be ignored when retrieving
        statistics. Note that epoch_number is taken to be zero-based.
        """
        self._start = epoch_number
        self._runs_start = self._runs[
            self._runs.Duration.cumsum() > epoch_number].index[0]

    def _get_run_for_alignment(self, alignment):
        """Retrieve the runs that a given alignment encompasses."""
        if alignment is None:
            return self._runs
        self._check_alignment_exists(alignment)
        return self._alignment_runs[alignment]

    def reset(self):
        """Set the starting epoch to the first one."""
        self._start = self._runs_start = 0
        self._breakpoints.clear()
        self._alignment_runs.clear()

    def get_full_data_since_onset(self):
        """Get the data from the first epoch onwards, after alignment.

        This will leave out any data before the specified onset,
        but will include the data from all sub-series from then onwards.

        If no alignment has been performed, this will returned all data.
        """
        return self._data.iloc[self._start:]

    def get_alignment_data(self):
        """Return a list containing the information to write out alignments.

        Each element of the list is a dataframe corresponding to a subseries of
        the data.
        """
        all_data = []
        for (start, stop) in self._breakpoints:
            df = pd.DataFrame()
            df["Sleep_wake"] = self._data.Sleep_wake[start:stop+1]
            # Add the information on state changes
            # Not using != because of an apparent issue with pandas (#28384)
            state_changed = ~(df["Sleep_wake"] == df["Sleep_wake"].shift(1))
            # Don't consider the very first epoch as a state change
            if start == 0:
                state_changed.iloc[0] = False
            df["State_change_from_preceding_epoch"] = state_changed
            # Find which run the start and stop epoch correspond to
            runs_start = self._runs[self._runs.Start >= start].index[0]
            runs_stop = self._runs[self._runs.Stop >= stop].index[0]
            # To find the state change details, start looking from the run
            # directly before this alignment starts, unless we are at the very
            # first epoch (in which case we will not count this as a change).
            diff_runs_start = runs_start - 1 if start != 0 else runs_start
            df["Details_state_change"] = [""] * df.shape[0]
            state_change_details = [f"{row.From}_{row.To}"
                                    for row
                                    # Exclude the last run (from last state to NaN)
                                    in self._runs[diff_runs_start:runs_stop].itertuples()]
            df.loc[state_changed, "Details_state_change"] = state_change_details
            df["How_many_epochs_of_preceding_state_before_state_change"] = [""] * df.shape[0]
            # The below needs to be a list because otherwise the indexing is messed up
            # TODO Can this be done directly with the Series somehow?
            df.loc[state_changed, "How_many_epochs_of_preceding_state_before_state_change"] = \
                list(self._runs[diff_runs_start:runs_stop].Duration)
            # Copy remaining columns
            # TODO Can probably do this better?
            for col in self._data.columns[1:]:
                df[col] = self._data[col][start:stop+1]
            all_data.append(df.astype(str))
        return all_data

    def get_alignment_start_time(self, alignment_index):
        """Get the time that the specified alignment started."""
        # Check that the requested alignment exists
        self._check_alignment_exists(alignment_index)
        # Calculate how many seconds have passed since the experiment started
        epochs_before_alignment = int(self._get_run_for_alignment(alignment_index)
                                   .iloc[0].Start)
        offset = datetime.timedelta(
            seconds=epochs_before_alignment*self.epoch_duration_seconds)
        # We can only add time differences to full datetime objects,
        # so use a dummy date (today), and then just drop the date part
        base_datetime = datetime.datetime.combine(datetime.datetime.today(),
                                                  self.Start_time)
        return (base_datetime + offset).time()

    def get_epochs_since_stimulation(self, stimulus_type, alignment_index):
        """Return the time since the last stimulation before an alignment.

        This will search for the latest instance of stimulation of the given
        kind prior to a particular alignment starting. Any stimulation at the
        same time as the start of the alignment is disregarded. If no instances
        are found, then None is returned.

        :param stimulus_type: the kind of stimulation e.g. Painful_stimulation
        :param alignment_index: 0-based index of the alignment in question
        :returns: the number of epochs since stimulation, or None if none found
        """
        # Check that the arguments are meaningful...
        assert stimulus_type in ["Painful_stimulation",
                                 "Somatosensory_stimulation",
                                 "Held"], f"Invalid stimulus: {stimulus_type}"
        self._check_alignment_exists(alignment_index)
        # Find the last instance of stimulation before the alignment started
        col_name = f"{stimulus_type}_yes_no"
        start = self._breakpoints[alignment_index][0]
        indices = np.flatnonzero(self._data.iloc[:start][col_name])
        if indices.size == 0:
            return None
        else:  # number of epochs between last stimulus and start of alignment
            return start - indices[-1]

    def _check_alignment_exists(self, alignment_index):
        """Throw an error if the given index does not match a valid alignment.

        :raises AlignmentError: if alignment has not been performed
        :raises IndexError: if the index surpasses the number of alignments
        """
        if not self._breakpoints:
            raise AlignmentError("No alignments found.")
        if alignment_index >= len(self._breakpoints):
            raise IndexError(f"Invalid alignment index: {alignment_index}")


class ExperimentCollection:
    """A collection of experiment results and metadata."""
    def __init__(self, filenames=None):
        self._filenames = filenames if filenames else []

    def add_file(self, filename):
        """Add an experiment file to this collection."""
        self._filenames.append(filename)

    def add_directory(self, path):
        """Add all experiment files in the given directory."""
        new_files = [os.path.join(path, filename)
                     for filename in sorted(os.listdir(path))
                     if filename.endswith('.xlsx')]
        if not new_files:
            warnings.warn(f"No Excel files found in {path}.")
        else:
            self._filenames.extend(new_files)

    def write_summary(self, filename):
        """Create a new file with a summary of the collected experiments."""
        col_names = [
            "Baby_reference", "Start_time",
            "Neonatal_unit_yes_no", "High_risk_yes_no",
            "Postnatal_age_days",
            "Corrected_gestational_age_weeks",
            "%REM", "Mean_duration_REM_epochs",
            "%nREM", "Mean_duration_nREM_epochs",
            "%Trans", "Mean_duration_Trans_epochs",
            "%Awake", "Mean_duration_Awake_epochs",
            "No.state_changes_including_all_4_states",
            "No.state_changes_restricted_Awake_REM_nREM",
            "No.epochs", "Painful_stimulation_any_yes_no",
            "Somatosensory_stimulation_any_yes_no",
            "Held_any_yes_no"
        ]
        with open(filename, 'w') as out_file:
            out_file.write(",".join(col_names) + "\n")
            for exp_file in self._filenames:
                exp = Experiment(*load_file(exp_file))
                summary = exp.summarise()
                out_file.write(",".join(str(element) for element in summary))
                out_file.write("\n")

    def experiments(self):
        """Get a generator to iterate over the experiments contained here.

        Note: this will load each experiment, not just return the filenames,
        so it may be slow.
        """
        for exp_file in self._filenames:
            yield Experiment(*load_file(exp_file))
