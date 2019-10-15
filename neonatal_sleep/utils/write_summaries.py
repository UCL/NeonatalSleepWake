"""
A script to write the summaries for all experiments in a a directory.

Usage: python write_summaries <path_to_data>
"""

import sys

from ..experiment import ExperimentCollection


def main():
    collection = ExperimentCollection()
    collection.add_directory(sys.argv[1])
    collection.write_summary("summary_all.csv")


if __name__ == "__main__":
    main()
