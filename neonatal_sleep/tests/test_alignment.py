"""Tests about the basic behaviour of aligning to a state."""

import pytest

from neonatal_sleep.common import AlignmentError, SleepStateNotRecognisedError


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
    breakpoints_after_first = sample_experiment._breakpoints[:]
    # Align to nREM and check that the object has changed
    sample_experiment.start_at_state("nREM")
    assert sample_experiment._start != start_after_first
    assert sample_experiment._runs_start != runs_start_after_first
    # Align to REM again and make sure that we get the same results as before
    sample_experiment.start_at_state("REM")
    assert sample_experiment._start == start_after_first
    assert sample_experiment._runs_start == runs_start_after_first
    assert sample_experiment._breakpoints == breakpoints_after_first


def test_alignment_error_if_not_found(no_nrem_experiment):
    """Check for an error if the given state is not observed at all."""
    with pytest.raises(AlignmentError):
        no_nrem_experiment.start_at_state("nREM", observed_start=False)


def test_alignment_error_if_only_found_at_start(awake_nrem_experiment):
    """Check for an error if the given state is only observed at the start."""
    with pytest.raises(AlignmentError):
        awake_nrem_experiment.start_at_state("Awake")


@pytest.mark.parametrize("wrong_name", ["Held", "NotAnActualState"])
def test_alignment_error_if_invalid_state(sample_experiment, wrong_name):
    """Check for an error if an invalid state is specified."""
    with pytest.raises(SleepStateNotRecognisedError):
        sample_experiment.start_at_state(wrong_name)


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
