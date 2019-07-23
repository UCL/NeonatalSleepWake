"""Tests for the methods of the Experiment class."""
import os

import pandas as pd
import pytest
import yaml

from experiment import Experiment


@pytest.fixture(scope="module")
def sample_data():
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_data = yaml.safe_load(data_file)[
            os.path.basename("sample_experiment")]
        yaml_meta = yaml_data.pop('meta', None)
    data = pd.DataFrame(yaml_data)
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

