"""Tests for the methods of the Experiment class."""
import datetime
import filecmp

import pandas as pd
import pytest
import yaml

from ..common import SLEEP_STATE, AlignmentError, SleepStateNotRecognisedError
from ..experiment import Experiment, ExperimentCollection
from ..load_file import load_file


@pytest.fixture(scope="module")
def sample_data():
    """The data and metadata underlying a small test experiment."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['sample_experiment']
    yaml_meta = yaml_contents['meta']
    # Convert the time from a string into a time object
    yaml_meta["Start_time"] = datetime.datetime.strptime(
        yaml_meta["Start_time"], "%H:%M").time()
    data = pd.read_csv(yaml_contents['data'])
    data['Sleep_wake'] = data['Sleep_wake'].astype(SLEEP_STATE)
    return data, yaml_meta


@pytest.fixture(scope="module")
def sample_alignments():
    """The correct alignments of the small test experiment."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['sample_experiment']
    return yaml_contents["alignments"]


@pytest.fixture
def sample_experiment(sample_data):
    """An Experiment object representing the small test experiment."""
    return Experiment(*sample_data)


@pytest.fixture
def no_nrem_experiment():
    """An experiment that does not contain any nREM observations."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['no_nrem_experiment']
    return Experiment(*load_file(yaml_contents['raw']))


@pytest.fixture
def awake_nrem_experiment():
    """An experiment that contains a run of Awake, and a single nREM epoch."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['awake_nrem_experiment']
    data = pd.read_csv(yaml_contents['data'])
    data['Sleep_wake'] = data['Sleep_wake'].astype(SLEEP_STATE)
    return Experiment(data, {})


def test_metadata(sample_experiment, sample_data):
    assert all(getattr(sample_experiment, key) == value
               for key, value in sample_data[1].items())


def test_number_epochs(sample_experiment):
    assert sample_experiment.number_epochs() == 8


def test_count(sample_experiment):
    assert sample_experiment.count("Awake") == 3
    assert sample_experiment.count("REM") == 2
    assert sample_experiment.count("nREM") == 2
    assert sample_experiment.count("Trans") == 1


def test_durations(sample_experiment):
    assert all(sample_experiment.durations("Awake") == [2, 1])
    assert all(sample_experiment.durations("nREM") == [2])
    assert all(sample_experiment.durations("REM") == [1, 1])
    assert all(sample_experiment.durations("Trans") == [1])


def test_count_transitions(sample_experiment):
    # TODO Could be better split in different tests
    assert sample_experiment.count_transitions(["Awake"], ["REM"]) == 1
    assert sample_experiment.count_transitions(["REM"], ["Awake"]) == 1
    # Check no results:
    assert sample_experiment.count_transitions(["nREM"], ["REM"]) == 0
    # Check no symmetry:
    assert sample_experiment.count_transitions(["REM"], ["nREM"]) == 1
    # Multiple start states:
    assert sample_experiment.count_transitions(["Awake", "Trans"], ["REM"]) == 2
    assert sample_experiment.count_transitions(["Trans", "Awake"], ["REM"]) == 2


def test_summary_correct():
    """Check that the summary of some experiments is as expected."""
    files = ["tests/data/sample_experiment.xlsx",
             "tests/data/sample_experiment.xlsx"]
    collection = ExperimentCollection(files)
    collection.write_summary("summary.csv")
    assert filecmp.cmp("summary.csv",
                       "tests/data/summary_correct.csv",
                       shallow=False)


def test_alignment_initial(sample_experiment):
    """Check that an experiment considers all epochs by default."""
    assert sample_experiment._start == 0
    assert sample_experiment._runs_start == 0


def test_alignment_ignore_first_state(sample_experiment):
    """Check that we ignore the first epoch by default when aligning."""
    state = sample_experiment._data.iloc[0, 0]  # the first observed state
    sample_experiment.start_at_state(state)
    assert sample_experiment._start != 0
    assert sample_experiment._runs_start != 0


def test_alignment_match_first_state_if_no_observe(sample_experiment):
    """Check that we can match the first epoch if not requiring observed start."""
    state = sample_experiment._data.iloc[0, 0]
    sample_experiment.start_at_state(state, observed_start=False)
    assert sample_experiment._start == 0
    assert sample_experiment._runs_start == 0


@pytest.mark.parametrize("state", ["REM", "nREM", "Awake", "Trans"])
def test_alignment_to_first_transition(sample_experiment, state):
    """Check that we correctly align to any state.

    Specifically, check that the new starting epoch matches the specified
    state, and that it is the first occurrence of that state, except perhaps
    in the beginning (since the first state is ignored by default).
    """
    sample_experiment.start_at_state(state)
    new_start = sample_experiment._start
    assert sample_experiment._data.iloc[new_start, 0] == state
    assert (all(sample_experiment._data.iloc[:new_start, 0] != state)
            or sample_experiment._data.iloc[0, 0] == state)


@pytest.mark.parametrize("state", ["REM", "nREM", "Awake", "Trans"])
def test_alignment_to_first_instance(sample_experiment, state):
    """Check that we can always match the first occurrence of a state.

    Specifically, check that if we explicitly don't require to observe the
    start of a run, we will always get the first occurrence of a state, even
    if that is at the beginning of the data.
    """
    sample_experiment.start_at_state(state, observed_start=False)
    new_start = sample_experiment._start
    assert sample_experiment._data.iloc[new_start, 0] == state
    assert all(sample_experiment._data.iloc[:new_start, 0] != state)


def test_alignment_repeated(sample_experiment):
    """Check that each alignment is independent from previous calls."""
    # Align to REM and record results
    sample_experiment.start_at_state("REM")
    start_after_first = sample_experiment._start
    runs_start_after_first = sample_experiment._runs_start
    # Align to nREM and check that the object has changed
    sample_experiment.start_at_state("nREM")
    assert sample_experiment._start != start_after_first
    assert sample_experiment._runs_start != runs_start_after_first
    # Align to REM again and make sure that we get the same results as before
    sample_experiment.start_at_state("REM")
    assert sample_experiment._start == start_after_first
    assert sample_experiment._runs_start == runs_start_after_first


def test_alignment_error_if_not_found(no_nrem_experiment):
    """Check for an error if the given state is not observed at all."""
    with pytest.raises(AlignmentError):
        no_nrem_experiment.start_at_state("nREM", observed_start=False)


def test_alignment_error_if_only_found_at_start(awake_nrem_experiment):
    """Check for an error if the given state is only observed at the start."""
    with pytest.raises(AlignmentError):
        awake_nrem_experiment.start_at_state("Awake")


def test_alignment_error_if_invalid_state(sample_experiment):
    """Check for an error if an invalid state is specified."""
    with pytest.raises(SleepStateNotRecognisedError):
        sample_experiment.start_at_state("NotAnActualState")


def test_alignment_multiple(sample_experiment, sample_alignments):
    """Check that we get the correct alignments for a simple case."""
    correct_alignments = sample_alignments["REM_jump"]
    sample_experiment.start_at_state("REM")
    data = sample_experiment.get_alignment_data()
    assert isinstance(data, list)
    assert len(data) == len(correct_alignments)
    # Check that the sleep states are reported correctly
    for computed, correct in zip(data, correct_alignments):
        assert (computed.Sleep_wake == correct["states"]).all()
    # Check that we mark the transition for the first epoch of each alignment
    for computed in data:
        # The returned alignments contain all values as strings
        assert computed["State_change_from_preceding_epoch"].iloc[0] == "True"


def test_alignment_first_not_recorded(sample_experiment):
    """Check that we do not record a state change for the very first epoch."""
    sample_experiment.start_at_state("Awake", observed_start=False)
    data = sample_experiment.get_alignment_data()
    assert len(data) == 2
    # The first alignment starts at the first epoch, so the state should not
    # be marked as changed.
    assert data[0]["State_change_from_preceding_epoch"].iloc[0] == "False"
    # But the second alignment should still record a state change at its start.
    assert data[1]["State_change_from_preceding_epoch"].iloc[0] == "True"


def test_get_slice_error_no_alignment(sample_experiment):
    """Check for an error when no alignments have been created."""
    with pytest.raises(AlignmentError):
        sample_experiment._get_slice_for_alignment(0)


def test_get_slice_error_not_enough_alignments(awake_nrem_experiment):
    """Check for an error when using an invalid alignment index."""
    awake_nrem_experiment.start_at_state("Awake", observed_start=False)
    # There is only one alignment, with index 0, so this should give an error:
    with pytest.raises(IndexError):
        awake_nrem_experiment._get_slice_for_alignment(1)


def test_get_slice_correct(sample_experiment, sample_alignments):
    """Check that we get the right slice limits in a simple case."""
    correct_alignments = sample_alignments["REM_jump"]
    sample_experiment.start_at_state("REM")
    for (index, alignment) in enumerate(correct_alignments):
        computed_slice = sample_experiment._get_slice_for_alignment(index)
        assert computed_slice.start == alignment["start_run"]
        assert computed_slice.stop == alignment["stop_run"] + 1


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
