"""Tests for the methods of the Experiment class."""
import filecmp

import pandas as pd
import pytest
import yaml

from experiment import Experiment, ExperimentCollection
from load_file import load_file


@pytest.fixture(scope="module")
def sample_data():
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['sample_experiment']
    yaml_meta = yaml_contents['meta']
    data = pd.read_csv(yaml_contents['data'])
    data['Sleep_wake'] = data['Sleep_wake'].astype(
        pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"]))
    return data, yaml_meta


@pytest.fixture
def sample_experiment(sample_data):
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
    data['Sleep_wake'] = data['Sleep_wake'].astype(
        pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"]))
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
    with pytest.raises(RuntimeError):
        no_nrem_experiment.start_at_state("nREM", observed_start=False)


def test_alignment_error_if_only_found_at_start(awake_nrem_experiment):
    """Check for an error if the given state is only observed at the start."""
    with pytest.raises(RuntimeError):
        awake_nrem_experiment.start_at_state("Awake")
