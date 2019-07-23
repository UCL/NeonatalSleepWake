import os
import warnings

import numpy as np
import pandas as pd

from load_file import load_file


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

    def number_epochs(self):
        return len(self._data)

    def count(self, state):
        """Return how many times a sleep state occurs in this experiment."""
        sleep_states = self._data.iloc[:, 0]
        if state not in sleep_states.dtype.categories:
            raise ValueError(f"Unrecognised sleep state: {state}")
        return (sleep_states == state).sum()

    def durations(self, state):
        """Compute how long the patient spends in the given state each time.

        Returns an array of durations in epochs.
        """
        # Filter only the runs of the state we want
        return self._runs[self._runs.From == state].Duration.values

    def count_transitions(self, from_states, to_states):
        """Return how many transitions occur between the given states."""
        matching = (self._runs.From.isin(from_states)
                    & self._runs.To.isin(to_states))
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
            self._data.Painful_stimulation_yes_no.sum() > 0,
            self._data.Somatosensory_stimulation_yes_no.sum() > 0,
            self._data.Held_yes_no.sum() > 0,
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
        to_indices = self._runs.Duration.cumsum()[:-1]
        self._runs["To"] = self._data.iloc[to_indices, 0].reset_index(drop=True)


class ExperimentCollection:
    """A collection of experiment results and metadata."""
    def __init__(self, filenames=None):
        self._filenames = filenames if filenames else []

    def add_file(self, filename):
        """Add an experiment file to this collection."""
        self._filenames.append(filename)

    def add_directory(self, path):
        """Add all experiment files in the given directory."""
        new_files = [filename
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
            "%REM", "Mean_duration_REM_if_onset_captured",
            "%nREM", "Mean_duration_nREM_if_onset_captured",
            "%Trans", "Mean_duration_Trans_if_onset_captured",
            "%Awake", "Mean_duration_Awake_if_onset_captured",
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
