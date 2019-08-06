"""
A script to write the summaries for all experiments in a a directory.

Usage: python -m NeonatalSleepWake.write_summaries <path_to_data>
"""

import sys

from .experiment import ExperimentCollection

if __name__ == "__main__":
    collection = ExperimentCollection()
    collection.add_directory(sys.argv[1])
    collection.write_summary("summary_all.csv")
