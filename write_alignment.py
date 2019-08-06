"""
A simple script that writes out the aligned data for all experiments
contained in a single directory.
"""

import argparse
import os
import warnings

from .common import SLEEP_STATE, AlignmentError
from .experiment import ExperimentCollection

COLUMN_HEADERS = ["Baby_reference",	"Start_time",
                  "Neonatal_unit_yes_no", "High_risk_yes_no",
                  "Postnatal_age_days", "Corrected_gestational_age_weeks",
                  "No.epochs_this_alignment", "Presence_Awake",
                  "Presence_REM", "Presence_Trans", "Presence_nREM"]


def write_aligned_experiment(experiment, state, observed_start, output_filename):
    experiment.start_at_state(state, observed_start)
    alignment_data = experiment.get_alignment_data()
    n_epochs, n_columns = alignment_data.shape
    # The row to repeat for every aspect of this alignment
    meta_row = ",".join(map(str,
                            [experiment.Baby_reference, experiment.Start_time,
                             experiment.Neonatal_unit_yes_no,
                             experiment.High_risk_yes_no,
                             experiment.Postnatal_age_days,
                             experiment.Corrected_gestational_age_weeks,
                             n_epochs,
                             experiment.count("Awake"), experiment.count("REM"),
                             experiment.count("Trans"), experiment.count("nREM")],
                            ))
    with open(output_filename, 'w') as output_file:
        # write header
        output_file.write(",".join(COLUMN_HEADERS) + "\n")
        for col in range(n_columns):
            # write metadata
            output_file.write(meta_row + ",")
            # write an aspect of the alignment
            output_file.write(alignment_data.columns[col] + ",")
            output_file.write(",".join(alignment_data.iloc[:, col]))
            output_file.write("\n")


parser = argparse.ArgumentParser(
    description='Write out aligned data.',
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('directory', help='the path to the data files')
parser.add_argument('state', choices=SLEEP_STATE.categories,
                    help='the first state to align to')
parser.add_argument('--first-occurrence', action='store_true',
                    help='use the first occurrence of the state, '
                         'rather than the first transition to it')
parser.add_argument('--out_directory', default='.',
                    help='the directory to write results to')
args = parser.parse_args()

collection = ExperimentCollection()
collection.add_directory(args.directory)
for exp in collection.experiments():
    # Some references include /. Remove it to avoid filename problems.
    clean_ref = exp.Baby_reference.replace("/", "")
    out_path = os.path.join(args.out_directory, f"alignment_{clean_ref}.csv")
    try:
        write_aligned_experiment(exp, args.state, not args.first_occurrence,
                                 out_path)
    except AlignmentError:
        warnings.warn(f"Could not align data for reference {exp.Baby_reference}")

