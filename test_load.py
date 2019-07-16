import glob
import os

import numpy as np
import pandas as pd
import pytest

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
    for filename in glob.iglob(dir_path + "*.xlsx"):
        data, metadata = load_file(filename)
        # Check that we are getting one category and three boolean columns...
        assert all(d == dt for d, dt in zip(data.dtypes, [cat_type] + 3 * [np.dtype(bool)]))
        # ...with the right names...
        assert data.columns == FIELDS[1:]
        # ...and that we don't have any missing values from the conversion
        assert not data.isna().any(axis=None)
        # Check that we haven't missed any metadata columns
        assert all(key in metadata for key in METADATA_COLUMNS)
