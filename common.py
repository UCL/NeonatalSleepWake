"""Shared constants and functionality for loading and processing sleep data."""

import pandas as pd

# A Pandas type to use for sleep-state data
SLEEP_STATE = pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"])


# Errors
class SleepStateNotRecognisedError(ValueError):
    """An exception to raise when an unrecognised sleep state is specified."""
    pass


class AlignmentError(RuntimeError):
    """An exception to raise when an alignment is impossible or fails.

    For example, this may be thrown when a user asks to align on a state that
    does not appear in the data.
    """
    pass
