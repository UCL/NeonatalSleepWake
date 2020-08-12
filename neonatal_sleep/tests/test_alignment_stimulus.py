"""Tests about aligning to a stimulus."""

import pytest

from neonatal_sleep.common import StimulusNotRecognisedError


def _compare_stimulus_alignments(computed_all, expected_all, stimulus):
    assert isinstance(computed_all, list)
    assert len(computed_all) == len(expected_all)
    # Check that the sleep states and limits are reported correctly
    for computed, correct in zip(computed_all, expected_all):
        assert (computed.Sleep_wake == correct["states"]).all()
        # Epochs in index are 1-based but fixture data is 0-based
        assert computed.index[0] == correct["start_epoch"] + 1
        assert computed.index[-1] == correct["stop_epoch"] + 1
    # Check that each alignment starts with an occurrence of the stimulus
    for computed in computed_all:
        # The returned alignments contain all values as strings
        assert computed[f"{stimulus}_yes_no"].iloc[0] == "True"


def test_alignment_to_stimulus_jump(stimulus_experiment, stimulus_alignments):
    """Check that aligning to the start of a stimulus works as expected."""
    correct_alignments = stimulus_alignments["Painful_stimulation_jump"]
    stimulus_experiment.start_at_stimulus("Painful_stimulation")
    data = stimulus_experiment.get_alignment_data()
    _compare_stimulus_alignments(data, correct_alignments,
                                 "Painful_stimulation")


def test_alignment_to_stimulus_first(stimulus_experiment, stimulus_alignments):
    """Check that aligning to a stimulus occurrence works as expected."""
    correct_alignments = stimulus_alignments["Painful_stimulation_first"]
    stimulus_experiment.start_at_stimulus("Painful_stimulation",
                                          observed_start=False)
    data = stimulus_experiment.get_alignment_data()
    _compare_stimulus_alignments(data, correct_alignments,
                                 "Painful_stimulation")


@pytest.mark.parametrize("wrong_name", ["REM", "random_name"])
def test_alignment_error_if_invalid_stimulus(stimulus_experiment, wrong_name):
    """Check for an error if an invalid stimulus is specified for alignment."""
    with pytest.raises(StimulusNotRecognisedError):
        stimulus_experiment.start_at_stimulus(wrong_name)
