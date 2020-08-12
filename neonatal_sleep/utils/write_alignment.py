"""
A simple script that writes out the aligned data for all experiments
contained in a single directory.
"""

import argparse
import datetime
from functools import reduce
from operator import concat
from pathlib import Path
import textwrap
import warnings

from ..common import (AlignmentError, check_state, check_stimulus,
                      LeadInTooLargeError, SLEEP_STATE,
                      SleepStateNotRecognisedError, STIMULI)
from ..experiment import ExperimentCollection

COLUMN_HEADERS = ["Baby_reference",	"Start_time",
                  "Neonatal_unit_yes_no", "High_risk_yes_no",
                  "Postnatal_age_days", "Corrected_gestational_age_weeks",
                  "No.epochs_this_alignment", "No.epochs_Awake",
                  "No.epochs_REM", "No.epochs_Trans", "No.epochs_nREM",
                  "Painful_stimulation_any_preceding_yes_no",
                  "Painful_stimulation_epochs_prior",
                  "Somatosensory_stimulation_any_preceding_yes_no",
                  "Somatosensory_stimulation_epochs_prior",
                  "Held_any_preceding_yes_no",
                  "Held_epochs_prior"]


def _last_stimulus_information(stimulus, experiment, alignment_index):
    """Report when a stimulus was last seen before an alignment.

    Returns a list [found, epochs], where found is True iff the stimulus has
    been encountered before the specified alignment started, and epochs is
    the number of epochs between the last occurrence of the stimulus and the
    start of the alignment (or 0 if found is False i.e. the stimulus has not
    been encountered).
    """
    epochs_since_stimulation = experiment.get_epochs_since_stimulation(
        stimulus, alignment_index)
    stimulus_found = epochs_since_stimulation is not None
    return [stimulus_found, epochs_since_stimulation if stimulus_found else 0]


def write_aligned_experiment(experiment, start_point, observed_start, lead,
                             output_file):
    """Write all alignments from a single experiment.

    :param experiment: the Experiment to be processed
    :param start_point: the state or stimulus to align to, as a string
    :param observed_start: if True, discard epochs until we see a transition to state
    :param lead: how many epochs before the state/stimulus alignments should start
    :param output_file: file handle to write alignments in
    """
    if start_point in SLEEP_STATE.categories:
        experiment.start_at_state(start_point, observed_start, lead)
    elif start_point in STIMULI:
        experiment.start_at_stimulus(start_point, observed_start, lead)
    all_alignments = experiment.get_alignment_data()
    for (alignment_index, alignment_data) in enumerate(all_alignments):
        # Start counting alignments from 1 rather than 0, for clarity
        reference = f"{experiment.Baby_reference}_alignment_{alignment_index+1}"
        n_epochs, n_columns = alignment_data.shape
        start_time = experiment.get_alignment_start_time(alignment_index)
        # Get the information about the last occurrence of each stimulus
        last_stimulation_info = [
            _last_stimulus_information(stimulus, experiment, alignment_index)
            for stimulus
            in ("Painful_stimulation", "Somatosensory_stimulation", "Held")
        ]
        # Flatten the list to more easily combine it with the other columns
        last_stimulation_info_all = reduce(concat, last_stimulation_info)

        # The row to repeat for every aspect of this alignment
        meta_row = ",".join(map(str,
                                [reference, start_time,
                                 experiment.Neonatal_unit_yes_no,
                                 experiment.High_risk_yes_no,
                                 experiment.Postnatal_age_days,
                                 experiment.Corrected_gestational_age_weeks,
                                 n_epochs,
                                 experiment.count("Awake", alignment_index),
                                 experiment.count("REM", alignment_index),
                                 experiment.count("Trans", alignment_index),
                                 experiment.count("nREM", alignment_index)]
                                + last_stimulation_info_all
                                ))
        for col in range(n_columns):
            # write metadata
            output_file.write(meta_row + ",")
            # write an aspect of the alignment
            output_file.write(alignment_data.columns[col] + ",")
            output_file.write(",".join(alignment_data.iloc[:, col]))
            output_file.write("\n")


def create_alignments(directory, state, first_observed, lead, out_directory):
    """Write alignments for all files in a directory, along with metadata.

    :param directory: where to search for experiment files
    :param state: the state or stimulus to align to, as a string
    :param first_observed: if False, discard epochs until we see a transition to state
    :param lead: how many epochs before the state/stimulus to start the alignments
    :param out_directory: path for storing the output files
    """
    # This is not necessary when using the command-line interface, but MATLAB
    # will pass numbers to this function as floats by default.
    lead = int(lead)
    # Make sure we are aligning to a valid sleep state or stimulus name
    align_to_state = True
    try:
        check_state(state)
    except SleepStateNotRecognisedError:
        check_stimulus(state)
        align_to_state = False

    collection = ExperimentCollection()
    collection.add_directory(directory)

    # Use a meaningful output filename that shows how the alignments were generated
    # e.g. alignment_myDirectory_first_REM or alignment_myDirectory_jump_Awake
    out_base_name = (f"alignment_{Path(directory).name}"
                     f"_{'first' if first_observed else 'jump'}_{state}"
                     ) + ("" if lead == 0 else f"_{lead}_before")
    # Write the alignments for all experiments in a single file
    out_data_path = Path(out_directory, out_base_name + ".csv")
    failed_files = 0  # how many files we couldn't align
    lead_in_failures = 0  # how many we discarded due to too high lead-in time
    lead_in_discards = 0  # how many series we discarded due to the same reason
    with open(out_data_path, 'w') as output_data_file:
        # Write the header information
        output_data_file.write(",".join(COLUMN_HEADERS) + "\n")
        for exp in collection.experiments():
            try:
                write_aligned_experiment(exp, state, not first_observed, lead,
                                         output_data_file)
                lead_in_discards += exp.lookahead_discards
            except AlignmentError as error:
                warnings.warn(
                    f"Could not align data for reference {exp.Baby_reference}: {error}")
                failed_files += 1
                if type(error) is LeadInTooLargeError:
                    lead_in_failures += 1

    # And write a small text file describing how the alignment was done.
    out_meta_path = Path(out_directory, out_base_name + ".txt")
    meta_template = """
    This file contains contains metadata about the alignments in file
    {results_file}.
    The data was read from {input_location}.
    The alignment was performed by finding {mode} {kind} {starting_point},
    with a lead-in time of {lead_in} epoch(s).
    There were {number_failures} files which could not be aligned.
    {number_lead_in_failures} of these were because the lead-in time was too high.
    A further {number_lead_in_discards} subseries were discarded for the same reason.
    This file was generated at {time} on {date}.
    """
    now = datetime.datetime.now()
    meta_text = textwrap.dedent(meta_template).format(
        results_file=out_data_path.absolute(),
        input_location=Path(directory).absolute(),
        mode="occurrences of" if first_observed else "transitions to",
        kind="state" if align_to_state else "stimulus",
        starting_point=state,
        lead_in=lead,
        number_failures=failed_files,
        number_lead_in_failures=lead_in_failures,
        number_lead_in_discards=lead_in_discards,
        time=now.strftime("%H:%M"),
        date=now.strftime("%d %b %Y")
    )
    with open(out_meta_path, "w") as output_meta_file:
        output_meta_file.write(meta_text)


def entry_point():
    """A convenience function to write alignments from the command line."""
    parser = argparse.ArgumentParser(
        description='Write out aligned data.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('directory', help='the path to the data files')
    parser.add_argument('state', choices=list(SLEEP_STATE.categories) + STIMULI,
                        help='the first state or stimulus to align to')
    parser.add_argument('--lead', type=int, default=0,
                        help='how many epochs before the state/stimulus '
                             'each alignment should start')
    parser.add_argument('--first-occurrence', action='store_true',
                        help='use the first occurrence of the state/stimulus, '
                             'rather than the first transition to it')
    parser.add_argument('--out_directory', default='.',
                        help='the directory to write results to')
    args = parser.parse_args()

    create_alignments(args.directory,
                      args.state,
                      args.first_occurrence,
                      args.lead,
                      args.out_directory)


if __name__ == "__main__":
    entry_point()
