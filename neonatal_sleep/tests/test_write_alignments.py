"""Tests related to writing the alignments file and the methods involved."""

import difflib
import os

import pytest

from neonatal_sleep.common import AlignmentError
from neonatal_sleep.utils.write_alignment import create_alignments


def test_get_run_error_no_alignment(sample_experiment):
    """Check for an error when no alignments have been created."""
    with pytest.raises(AlignmentError):
        sample_experiment._get_run_for_alignment(0)


def test_get_run_error_not_enough_alignments(awake_nrem_experiment):
    """Check for an error when using an invalid alignment index."""
    awake_nrem_experiment.start_at_state("Awake", observed_start=False)
    # There is only one alignment, with index 0, so this should give an error:
    with pytest.raises(IndexError):
        awake_nrem_experiment._get_run_for_alignment(1)


def test_get_run_correct_limits(sample_experiment, sample_alignments):
    """Check that we get the right run limits in a simple case."""
    correct_alignments = sample_alignments["REM_jump"]
    sample_experiment.start_at_state("REM")
    for (index, alignment) in enumerate(correct_alignments):
        computed_run = sample_experiment._get_run_for_alignment(index)
        assert computed_run.iloc[0].Start == alignment["start_epoch"]
        assert computed_run.iloc[-1].Stop == alignment["stop_epoch"]


def test_get_alignment_time_start(sample_experiment, sample_data):
    """Check for the right start time if aligning at the very first epoch."""
    sample_experiment.start_at_state("Awake", observed_start=False)
    assert (sample_experiment.get_alignment_start_time(0)
            == sample_data[1]["Start_time"])


def test_get_alignment_time(sample_experiment, sample_data, sample_alignments):
    """Check that we get the expected start times for the simple experiment."""
    sample_experiment.start_at_state("REM")
    # Experiment starts at 01:23. The first alignment starts 2 epochs in,
    # the second 6 epochs in. Each epoch is 30 seconds.
    expected_times = ["01:24", "01:26"]
    for index in [0, 1]:
        assert (
            sample_experiment.get_alignment_start_time(index).strftime("%H:%M")
            == expected_times[index]
        )


def test_check_alignment_exists_no_alignment(sample_experiment):
    """Check for an error when checking alignment indices before aligning."""
    # The sample experiment is not aligned to begin with.
    with pytest.raises(AlignmentError):
        sample_experiment._check_alignment_exists(0)


def test_check_alignment_exists_invalid_alignment(sample_experiment):
    """Check that invalid alignment indices give an error when checked."""
    sample_experiment.start_at_state("REM")  # creates 2 alignments
    with pytest.raises(IndexError):
        sample_experiment._check_alignment_exists(2)


def test_check_alignment_exists_valid_alignment(sample_experiment):
    """Check that valid alignment indices don't give an error."""
    sample_experiment.start_at_state("REM")  # creates 2 alignments
    sample_experiment._check_alignment_exists(0)
    sample_experiment._check_alignment_exists(1)


def test_epochs_since_stimulation_invalid_type(sample_experiment):
    """Check for an error when specifying an invalid stimulation type."""
    with pytest.raises(AssertionError):
        sample_experiment.get_epochs_since_stimulation("Wrong_type", 0)


def test_epochs_since_stimulation_none_found(sample_experiment):
    """Check behaviour when there are no stimulations prior to alignment."""
    sample_experiment.start_at_state("REM")
    assert sample_experiment.get_epochs_since_stimulation(
        "Painful_stimulation", 0) is None


def test_epochs_since_stimulation_found(sample_experiment):
    """Check the number of epochs since stimulation for some simple cases."""
    sample_experiment.start_at_state("REM")
    assert sample_experiment.get_epochs_since_stimulation(
        "Painful_stimulation", 1) == 3
    assert sample_experiment.get_epochs_since_stimulation(
        "Somatosensory_stimulation", 1) == 1
    assert sample_experiment.get_epochs_since_stimulation(
        "Held", 1) == 1


@pytest.mark.parametrize("stimulus", ["Painful_stimulation",
                                      "Somatosensory_stimulation",
                                      "Held"])
def test_epochs_since_stimulation_none_at_start(sample_experiment, stimulus):
    """Check that we never see prior stimulation if starting at first epoch."""
    # Align to the very first epoch
    sample_experiment.start_at_state("Awake", observed_start=False)
    assert sample_experiment.get_epochs_since_stimulation(stimulus, 0) is None


def test_epochs_since_stimulation_exclude_simultaneous(awake_nrem_experiment):
    """Check that we exclude stimulations that overlap with the alignment."""
    awake_nrem_experiment.start_at_state("nREM")
    assert awake_nrem_experiment.get_epochs_since_stimulation(
        "Painful_stimulation", 0) is None


@pytest.mark.skipif(not os.environ.get("NEONATAL_TEST_DIR", ""), reason="No data dir")
@pytest.mark.skipif(not os.environ.get("NEONATAL_ALIGNMENTS_REF", ""), reason="No location for reference alignments")
@pytest.mark.parametrize("state", ["REM", "nREM", "Awake", "Trans"])
@pytest.mark.parametrize("first", [True, False])
def test_alignment_regression(tmpdir, state, first):
    print(f"----\n{tmpdir}\n----")
    file_prefix = "alignment_Categorical time series_last modified 06.12.19_"
    filename = file_prefix + f"{'first' if first else 'jump'}_{state}" + ".csv"
    correct_dir = os.environ["NEONATAL_ALIGNMENTS_REF"]
    correct_output = os.path.join(correct_dir, filename)
    assert os.path.exists(correct_output)
    input_dir = os.environ["NEONATAL_TEST_DIR"]
    create_alignments(input_dir, state, first, lead=0, out_directory=tmpdir)
    with open(os.path.join(tmpdir, filename)) as new_file:
        new_lines = new_file.readlines()
    with open(correct_output) as old_file:
        old_lines = old_file.readlines()
    assert not list(difflib.unified_diff(new_lines, old_lines))
