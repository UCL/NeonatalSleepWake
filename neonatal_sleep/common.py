"""Shared constants and functionality for loading and processing sleep data."""

import pandas as pd

# A Pandas type to use for sleep-state data
SLEEP_STATE = pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"])


# The list of stimulus types
STIMULI = ['Painful_stimulation', 'Somatosensory_stimulation', 'Held']


# Errors
class SleepStateNotRecognisedError(ValueError):
    """An exception to raise when an unrecognised sleep state is specified."""
    pass


class StimulusNotRecognisedError(ValueError):
    """An exception to raise when an unrecognised stimulus is specified."""
    pass


class AlignmentError(RuntimeError):
    """An exception to raise when an alignment is impossible or fails.

    For example, this may be thrown when a user asks to align on a state that
    does not appear in the data.
    """
    pass


def check_state(state):
    """Check that the given state name is valid, or raise an error."""
    if state not in SLEEP_STATE.categories:
        raise SleepStateNotRecognisedError(
            f"Unrecognised sleep state: {state}")


def check_stimulus(stimulus):
    """Check that the given state name is valid, or raise an error."""
    if stimulus not in STIMULI:
        raise StimulusNotRecognisedError(
            f"Unrecognised stimulus: {stimulus}")
