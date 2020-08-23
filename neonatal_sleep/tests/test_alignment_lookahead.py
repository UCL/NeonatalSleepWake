"""Tests about specifying a number of epochs before the start of alignments."""

import pytest

from neonatal_sleep.common import LeadInTooLargeError


def test_alignment_zero_lookahead_invariable(sample_experiment):
    """Check that a 'look_ahead' value of 0 does nothing when aligning."""
    state = "REM"
    sample_experiment.start_at_state(state)
    base_alignments = sample_experiment.get_alignment_data()
    sample_experiment.start_at_state(state, look_ahead=0)
    new_alignments = sample_experiment.get_alignment_data()
    assert all(
        (new == base).all().all()
        for (new, base) in zip(new_alignments, base_alignments)
    )
    assert sample_experiment.lookahead_discards == 0


def test_alignment_lookahead_correct(sample_experiment, sample_alignments):
    """Check look_ahead behaves as expected for a simple experiment."""
    epochs_before = 1
    state = "REM"
    base_alignments = sample_alignments[state + "_jump"]
    sample_experiment.start_at_state(state, True, epochs_before)
    alignments = sample_experiment.get_alignment_data()
    # There should be just as many alignments as with no look-ahead
    assert len(alignments) == len(base_alignments)
    assert sample_experiment.lookahead_discards == 0
    # Each alignmnent should include all states in the base alignment,
    # plus epochs_before additional epochs at the start
    for computed, base in zip(alignments, base_alignments):
        assert len(computed) == len(base["states"]) + epochs_before
        assert (computed.Sleep_wake.iloc[epochs_before:] == base["states"]).all()


def test_alignment_skipped_if_lookahead_too_large(sample_experiment,
                                                  sample_alignments):
    """Check that too large a lead-in time makes us skip an alignment."""
    epochs_before = 3
    state = "REM"
    base_alignments = sample_alignments[state + "_jump"]
    sample_experiment.start_at_state(state, True, epochs_before)
    alignments = sample_experiment.get_alignment_data()
    # In this experiment, the first alignment starts 2 epochs in. Since we
    # use a look-ahead of 3, the first alignment should be skipped...
    assert len(alignments) == len(base_alignments) - 1
    assert sample_experiment.lookahead_discards == 1
    # ...but the remaining ones should be unaffected (apart from the lead-in)
    for computed, base in zip(alignments[1:], base_alignments):
        assert len(computed) == len(base["states"]) + epochs_before
        assert (computed.Sleep_wake.iloc[epochs_before:] == base["states"]).all()


def test_alignment_error_if_lookahead_too_large_for_all(sample_experiment):
    """Check that we get an error if the lead-in excludes all alignments."""
    epochs_before = 4  # nREM has only 1 run, starting 3 epochs in
    with pytest.raises(LeadInTooLargeError):
        sample_experiment.start_at_state("nREM", look_ahead=epochs_before)
