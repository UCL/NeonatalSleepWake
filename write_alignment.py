"""
A simple script that writes out the aligned data for all experiments
contained in a single directory.
"""

import argparse
import datetime
from pathlib import Path
import warnings

from .common import SLEEP_STATE, AlignmentError
from .experiment import ExperimentCollection

COLUMN_HEADERS = ["Baby_reference",	"Start_time",
                  "Neonatal_unit_yes_no", "High_risk_yes_no",
                  "Postnatal_age_days", "Corrected_gestational_age_weeks",
                  "No.epochs_this_alignment", "No.epochs_Awake",
                  "No.epochs_REM", "No.epochs_Trans", "No.epochs_nREM"]


def write_aligned_experiment(experiment, state, observed_start, output_file):
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

# Use a meaningful output filename that shows how the alignments were generated
# e.g. alignment_myDirectory_first_REM or alignment_myDirectory_jump_Awake
out_base_name = (f"alignment_{Path(args.directory).name}"
                 f"_{'first' if args.first_occurrence else 'jump'}_{args.state}")
# Write the alignments for all experiments in a single file
out_data_path = Path(args.out_directory, out_base_name + ".csv")
with open(out_data_path, 'w') as output_data_file:
    # Write the header information
    output_data_file.write(",".join(COLUMN_HEADERS) + "\n")
    for exp in collection.experiments():
        try:
            write_aligned_experiment(exp, args.state, not args.first_occurrence,
                                     output_data_file)
        except AlignmentError:
            warnings.warn(f"Could not align data for reference {exp.Baby_reference}")

# And write a small text file describing how the alignment was done.
out_meta_path = Path(args.out_directory, out_base_name + ".txt")
meta_template = """
This file contains contains metadata about the alignments in file
{results_file}.
The data was read from {input_location}.
The alignment was performed by finding {mode} state {state_name}.
This file was generated at {time} on {date}.
"""
now = datetime.datetime.now()
meta_text = meta_template.format(
    results_file=out_data_path.absolute(),
    input_location=Path(args.directory).absolute(),
    mode="occurrences of" if args.first_occurrence else "transitions to",
    state_name=args.state,
    time=now.strftime("%H:%M"),
    date=now.strftime("%d %b %Y")
)
with open(out_meta_path, "w") as output_meta_file:
    output_meta_file.write(meta_text)
