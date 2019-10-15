"""
A script to write the summaries for all experiments in a a directory.

Usage: python write_summaries <path_to_data>
"""

import sys

from ..experiment import ExperimentCollection


def main(in_directory):
    """Write a summary of the files contained in the given directory."""
    collection = ExperimentCollection()
    collection.add_directory(in_directory)
    collection.write_summary("summary_all.csv")


def entry_point():
    """Convenience function for calling as a script."""
    main(sys.argv[1])


if __name__ == "__main__":
    entry_point()
