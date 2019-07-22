import glob
import os
import warnings

import numpy as np
import pandas as pd
import pytest
import yaml

from load_file import load_file, FIELDS, METADATA_COLUMNS


@pytest.mark.skipif("NEONATAL_TEST_DIR" not in os.environ,
                    reason="Set the NEONATAL_TEST_DIR variable to the location"
                           " of the samples.")
def test_all_load_ok():
    """Check that we can load some files with no problems.

    The test will look for files in the directory pointed to by
    $NEONATAL_TEST_DIR. Very basic check, but useful at an early stage.
    """
    # TODO Get this from the module rather than redefining it
    cat_type = pd.CategoricalDtype(["REM", "nREM", "Awake", "Trans"])
    dir_path = os.environ["NEONATAL_TEST_DIR"]
    real_files = glob.iglob(dir_path + "*.xlsx")
    assert real_files, "No files found!"
    for filename in real_files:
        data, metadata = load_file(filename)
        # Check that we are getting one category and three boolean columns...
        assert all(d == dt for d, dt in zip(data.dtypes, [cat_type] + 3 * [np.dtype(bool)]))
        # ...with the right names...
        assert all(data.columns == FIELDS[1:])
        # ...and that we don't have any missing values from the conversion
        try:
            assert data.notna().all(axis=None)
        except AssertionError:
            warnings.warn(f"Missing data found in {os.path.basename(filename)}")
        # Check that we haven't missed any metadata columns
        assert all(key in metadata for key in METADATA_COLUMNS)


def test_load_correct():
    """Check that loading a sample file gives the expected results."""
    filename = "tests/data/small.xlsx"
    loaded_data, loaded_meta = load_file(filename)
    # TODO Use a proper fixture instead of reading the results here
    with open('tests/data/fixtures.yaml') as data_file:
        expected_data = yaml.safe_load(data_file)[os.path.basename(filename)]
        expected_meta = expected_data.pop('meta')
    assert loaded_data.any(axis=None)
    for field in loaded_meta:
        # Time is a bit harder to check because we cannot represent it as a
        # time object directly in YAML
        if field == "Start_time":
            assert loaded_meta[field].strftime('%H:%M') == expected_meta[field]
        else:
            assert loaded_meta[field] == expected_meta[field]
