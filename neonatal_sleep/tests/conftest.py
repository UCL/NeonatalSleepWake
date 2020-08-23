"""Fixtures used in the tests, some shared."""

import datetime

import pandas as pd
import pytest
import yaml

from neonatal_sleep.common import SLEEP_STATE
from neonatal_sleep.experiment import Experiment
from neonatal_sleep.load_file import load_file


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
    # Real data indices start from 1
    data.index = data.index + 1
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
    # Real data indices start from 1
    data.index = data.index + 1
    return Experiment(data, {})


@pytest.fixture(scope="module")
def stimulus_alignments():
    """The correct alignments of the stimulus experiment."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['stimulus_experiment']
    return yaml_contents["alignments"]


@pytest.fixture
def stimulus_experiment():
    """An Experiment object representing the small test experiment."""
    with open('tests/data/fixtures.yaml') as data_file:
        yaml_contents = yaml.safe_load(data_file)['stimulus_experiment']
    data = pd.read_csv(yaml_contents['data'])
    data['Sleep_wake'] = data['Sleep_wake'].astype(SLEEP_STATE)
    # Real data indices start from 1
    data.index = data.index + 1
    return Experiment(data, {})
