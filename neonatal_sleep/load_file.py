import os
import warnings

import pandas as pd
import xlrd

from .common import SLEEP_STATE

# TODO Put this in a config file for easier editing by anyone
# The data recorded at each epoch
FIELDS = ["30_sec_epoch_no", "Sleep_wake", "Painful_stimulation_yes_no",
          "Somatosensory_stimulation_yes_no", "Held_yes_no"]
# The metadata for each patient
METADATA_COLUMNS = ["Start_time", "Baby_reference", "Neonatal_unit_yes_no",
                    "High_risk_yes_no", "Postnatal_age_days",
                    "Corrected_gestational_age_weeks"]


def validate_sheet(sheet):
    """Check that the sheet is formatted as expected."""
    # Quick (to write) and dirty
    assert sheet.nrows == len(FIELDS),\
        f"Found {sheet.nrows} instead of {len(FIELDS)} rows."
    n_cols = [sheet.row_len(n) for n in range(sheet.nrows)]
    assert n_cols[0] == n_cols[1], "Length of first two rows does not match."
    assert all(
        n_cols[0] == n_col + len(METADATA_COLUMNS)
        for n_col in n_cols[2:]
    ), "Data rows do not have the right number of columns."


def convert_data_types(data):
    """Create a new dataframe with standardised types.

    Converts yes/no columns into booleans, and the sleep state column into
    a categorical type with its fixed set of values."""
    new_data = pd.DataFrame(index=data.index)
    # Convert first column (sleep state) to a category with four values
    new_data[data.columns[0]] = data.iloc[:, 0].astype(SLEEP_STATE)
    # Convert yes/no to True/False. In principle this could be done with the
    # true_values/false_values argument to read_excel, but it doesn't seem to
    # work here (possibly because Pandas does that conversion column-wise, and
    # our columns include non-bool values (e.g. "REM"), which stop the
    # conversion when encountered).
    # TODO Can this be done earlier or simpler?
    for col_name in data.columns[1:]:
        new_data[col_name] = data[col_name].map({"yes": True, "no": False})
    return new_data


def convert_metadata(raw_metadata, datemode):
    """Convert the metadata to appropriate types."""
    metadata = {}
    # Create a time object from the time: the time is loaded as a fraction
    # of a day, but xlrd has convenience methods for interpreting it
    try:
        metadata["Start_time"] = xlrd.xldate_as_datetime(
            raw_metadata["Start_time"].value, datemode).time()
    except TypeError:  # some times may be missing
        metadata["Start_time"] = None
    # Store the baby reference as a string. Note that xlrd reads integers as
    # floats, so we need some conversion to stay close to the original format.
    # Also, some patients have two references in the form X/Y; in those cases,
    # the value will have been read as text already.
    original_value = raw_metadata["Baby_reference"].value
    try:
        reference = int(original_value)
    except ValueError:
        reference = original_value
    metadata["Baby_reference"] = str(reference)
    # Convert boolean attributes (assume everything non-"yes" is False)
    for field in ["Neonatal_unit_yes_no", "High_risk_yes_no"]:
        metadata[field] = raw_metadata[field].value == "yes"
    # Convert number of days/weeks to plain numbers
    metadata["Postnatal_age_days"] = int(
        raw_metadata["Postnatal_age_days"].value)
    metadata["Corrected_gestational_age_weeks"] = float(
        raw_metadata["Corrected_gestational_age_weeks"].value)
    return metadata


def load_file(path):
    """Load the data from the specified Excel workbook."""
    # TODO Can this be done with a context manager?
    print("Loading file", os.path.basename(path))
    book = xlrd.open_workbook(path, ragged_rows=True)
    # Assume there is only one sheet - warn if not!
    if book.nsheets > 1:
        warnings.warn(
            f"Multiple sheets found in {path}! Will only read the first.")
    sheet = book.sheet_by_index(0)
    validate_sheet(sheet)
    n_epochs = min(sheet.row_len(n) for n in range(sheet.nrows)) - 1
    df = pd.read_excel(book, usecols=range(n_epochs+1), index_col=0)
    # The data is stored the other way around from what Pandas would expect.
    # Swap some names around so that they make more sense!
    df.columns.name = df.index.name
    df.index.name = None
    data = df.T
    data.index = pd.RangeIndex(start=1, stop=n_epochs + 1)
    # Convert the values into something more standard than strings
    data = convert_data_types(data)
    # Read metadata from the second row
    metadata = convert_metadata(
        dict(zip(METADATA_COLUMNS, sheet.row(1)[n_epochs+1:])),
        book.datemode)
    return data, metadata
