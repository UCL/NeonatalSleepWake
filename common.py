"""Shared constants and functionality for loading and processing sleep data."""

import pandas as pd

# A Pandas type to use for sleep-state data
SLEEP_STATE = pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"])
