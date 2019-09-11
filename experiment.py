import os
import warnings

import numpy as np
import pandas as pd

from .common import AlignmentError, check_state
from .load_file import load_file


class Experiment:
    """A class to represent the results from an individual patient."""
    def __init__(self, data, metadata):
        self._data = data
        self._metadata = metadata
        # Would this be convenient?
        for key, value in metadata.items():
            setattr(self, key, value)
        # Precompute some statistics
        self._compute_sojourns()
        # Assume we want to use all the data
        self._start = 0  # which data row to start reading from
        self._runs_start = 0  # which run to start reading from
        self._breakpoints = []  # where to break different alignments

    def number_epochs(self):
        return self._runs[self._runs_start:].Duration.sum()

    def count(self, state):
        """Return how many times a sleep state occurs in this experiment."""
        check_state(state)
        considered_runs = self._runs.iloc[self._runs_start:]
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
                    & self._runs.To.isin(to_states))[self._runs_start:]
        # Return the number of transitions found
        return matching.sum()

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

    def _compute_sojourns(self):
        """Record how long we spend at each state and where we transition to."""
        # Find the duration of all consecutive sequences in the dataframe
        # then store them as tuples of (state, duration) in a new series
        self._data["subgroups"] = (self._data.Sleep_wake
                                   != self._data.Sleep_wake.shift(1)
                                   ).cumsum()
        runs = self._data.groupby("subgroups", as_index=False).apply(
            lambda x: (x.iloc[0, 0], len(x)))
        # Store this in a new dataframe, recording the state and how many
        # epochs were spent in it
        self._runs = pd.DataFrame({
            "From": [x[0] for x in runs],
            "Duration": [x[1] for x in runs]})
        # Now find what the next state is for each of these transitions
        # by checking the state at the total time spent so far
        # (we need reset_index to insert the states in the order given,
        # ignoring their index)
        jump_times = self._runs.Duration.cumsum()
        to_indices = jump_times[:-1]
        self._runs["To"] = self._data.iloc[to_indices, 0].reset_index(drop=True)
        # Also record the start and stop time of each run, for convenience
        # Each run lasts from Start until Stop, inclusive.
        self._runs["Start"] = jump_times.shift(1, fill_value=0)
        self._runs["Stop"] = jump_times - 1

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
        check_state(state)
        # Look into the compiled runs to find all occurrences of the state
        matching_runs = self._runs[self._runs.From == state]
        # Ignore the starting state unless we don't need to observe the start
        if observed_start:
            try:
                matching_runs = matching_runs.drop(index=0)
            except KeyError:  # first state is not the specified one, ignore
                pass
        # Set the start counters, or report an error if the state is not found
        if matching_runs.empty:
            raise AlignmentError(f"State {state} not found in data.")
        else:
            # Store the first and final epoch of each run in a list of tuples
            self._breakpoints = ([
                # Each run ends just before the next one starts...
                (start, next_start - 1)
                for (start, next_start)
                in zip(matching_runs.Start, matching_runs.Start[1:])
                ]
                # ...except for the final one, so add that manually
                + [(matching_runs.Start.iloc[-1], self._runs.Stop.iloc[-1])]
            )
            # TODO Also store the first and last run here, to avoid recomputing
            # it later?
            start_row = self._runs.iloc[:matching_runs.index[0]].Duration.sum()
            self._start_at_epoch(start_row)

    def _start_at_epoch(self, epoch_number):
        """Specify which epoch we should consider at the first.

        Epochs from before epoch_number will be ignored when retrieving
        statistics. Note that epoch_number is taken to be zero-based.
        """
        self._start = epoch_number
        self._runs_start = self._runs[
            self._runs.Duration.cumsum() > epoch_number].index[0]

    def reset(self):
        """Set the starting epoch to the first one."""
        self._start = self._runs_start = 0
        self._breakpoints.clear()

    def get_alignment_data(self):
        """Return a list containing the information to write out alignments.

        Each element of the list is a dataframe corresponding to a subseries of
        the data.
        """
        all_data = []
        for (start, stop) in self._breakpoints:
            # Find which run the start and stop epoch correspond to
            runs_start = self._runs[self._runs.Start == start].index[0]
            runs_stop = self._runs[self._runs.Stop == stop].index[0]
            df = pd.DataFrame()
            df["Sleep_wake"] = self._data.Sleep_wake[start:stop+1]
            # Add the information on state changes
            # Not using != because of an apparent issue with pandas (#28384)
            state_changed = ~(df["Sleep_wake"] == df["Sleep_wake"].shift(1))
            # Don't consider the very first epoch as a state change
            if start == 0:
                state_changed[0] = False
            # To find the state change details, start looking from the run
            # directly before this alignment starts, unless we are at the very
            # first epoch (in which case we will not count this as a change).
            diff_runs_start = runs_start - 1 if start != 0 else runs_start
            df["State_change_from_preceding_epoch"] = state_changed
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
            # Copy remaining columns, except for subgroups
            # TODO Can probably do this better?
            for col in self._data.columns[1:-1]:
                df[col] = self._data[col][start:stop+1]
            all_data.append(df.astype(str))
        return all_data


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
                     for filename in os.listdir(path)
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
