"""Tests for the methods of the Experiment class."""
import os

import pandas as pd
import pytest
import yaml

from experiment import Experiment


@pytest.fixture(scope="module")
def test_data():
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_data = yaml.safe_load(data_file)[
            os.path.basename("test_experiment")]
        yaml_meta = yaml_data.pop('meta', None)
    data = pd.DataFrame(yaml_data)
    data['Sleep_wake'] = data['Sleep_wake'].astype(
        pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"]))
    return data, yaml_meta


@pytest.fixture(scope="module")
def test_experiment(test_data):
    return Experiment(*test_data)


def test_metadata(test_experiment, test_data):
    assert all(getattr(test_experiment, key) == value
               for key, value in test_data[1].items())


def test_number_epochs(test_experiment):
    assert test_experiment.number_epochs() == 8


def test_count(test_experiment):
    assert test_experiment.count("Awake") == 3
    assert test_experiment.count("REM") == 2
    assert test_experiment.count("nREM") == 2
    assert test_experiment.count("Trans") == 1


def test_durations(test_experiment):
    assert test_experiment.durations("Awake") == [2, 1]
    assert test_experiment.durations("nREM") == [2]
    assert test_experiment.durations("REM") == [1, 1]
    assert test_experiment.durations("Trans") == [1]


def test_count_transitions(test_experiment):
    # TODO Could be better split in different tests
    assert test_experiment.count_transitions(["Awake"], ["REM"]) == 1
    assert test_experiment.count_transitions(["REM"], ["Awake"]) == 1
    # Check no results:
    assert test_experiment.count_transitions(["nREM"], ["REM"]) == 0
    # Check no symmetry:
    assert test_experiment.count_transitions(["REM"], ["nREM"]) == 1
    # Multiple start states:
    assert test_experiment.count_transitions(["Awake", "Trans"], ["REM"]) == 2
    assert test_experiment.count_transitions(["Trans", "Awake"], ["REM"]) == 2

