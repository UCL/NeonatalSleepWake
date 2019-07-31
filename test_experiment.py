"""Tests for the methods of the Experiment class."""
import filecmp

import pandas as pd
import pytest
import yaml

from experiment import Experiment, ExperimentCollection


@pytest.fixture(scope="module")
def sample_data():
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['sample_experiment']
    yaml_meta = yaml_contents['meta']
    data = pd.read_csv(yaml_contents['data'])
    data['Sleep_wake'] = data['Sleep_wake'].astype(
        pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"]))
    return data, yaml_meta


@pytest.fixture(scope="module")
def sample_experiment(sample_data):
    return Experiment(*sample_data)


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


def test_alignment_state_at_start(sample_experiment):
    """Check that we ignore the first epoch by default when aligning."""
    sample_experiment.start_at_state("Awake")
    assert sample_experiment._start == 7
    assert sample_experiment._runs_start == 5
    assert (sample_experiment._data.iloc[sample_experiment._start, 0]
            == "Awake")


def test_alignment_state_at_start_no_observe(sample_experiment):
    """Check that we can match the first epoch if not requiring observed start."""
    sample_experiment.start_at_state("Awake", observed_start=False)
    assert sample_experiment._start == 0
    assert sample_experiment._runs_start == 0
    assert (sample_experiment._data.iloc[sample_experiment._start, 0]
            == "Awake")


def test_alignment_middle(sample_experiment):
    """Check that we correctly align to states not in the beginning."""
    sample_experiment.start_at_state("REM")
    new_start = sample_experiment._start
    assert new_start == 2
    assert sample_experiment._runs_start == 1
    assert sample_experiment._data.iloc[new_start, 0] == "REM"
    assert all(sample_experiment._data.iloc[:new_start, 0] != "REM")
