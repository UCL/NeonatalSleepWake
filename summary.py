import os
import warnings

import numpy as np

from experiment import Experiment
from load_file import load_file

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
                summary = self._summarise(exp)
                out_file.write(",".join(str(element) for element in summary))
                out_file.write("\n")

    def _summarise(self, exp):
        """Get the summary information from a single experiment."""
        summary = [
            exp.Baby_reference, exp.Start_time, exp.Neonatal_unit_yes_no,
            exp.High_risk_yes_no, exp.Postnatal_age_days,
            exp.Corrected_gestational_age_weeks
        ]
        # Time spent in each state
        # TODO Currently counts all durations, regardless of onset captured
        sleep_states = ["REM", "nREM", "Trans", "Awake"]
        sleep_states_no_trans = ["REM", "nREM", "Awake"]
        for state in sleep_states:
            percent_time = exp.count(state) / exp.number_epochs()
            mean_duration = np.mean(exp.durations(state))
            summary.extend([percent_time, mean_duration])
        # State changes
        summary.append(exp.count_transitions(sleep_states, sleep_states))
        summary.append(exp.count_transitions(sleep_states_no_trans,
                                             sleep_states_no_trans))
        # Remaining summary data
        summary.append(exp.number_epochs())
        summary.extend([
            exp.count_painful() > 0,
            exp.count_somatosensory() > 0,
            exp.count_held() > 0,
        ])
        return summary
