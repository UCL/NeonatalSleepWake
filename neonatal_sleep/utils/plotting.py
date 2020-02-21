"""
Utilities for creating plots from experimental data.
"""
import sys
from argparse import ArgumentParser
from operator import itemgetter
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

from ..load_file import load_file
from ..experiment import Experiment


# Assign lower numbers to "deeper" sleep states so they show up lower in plot
states_to_num = {
    state: depth + 1
    for (depth, state)
    in enumerate(["nREM", "Trans", "REM", "Awake"])
}
# Approximate matplotlib colours:
# ["royalblue", "darkorange", "darkgrey", "gold"]
colours = ["#4574c7", "#ec7d27", "#a5a5a5", "#febf00"]
patterns = ['/', '+', 'x', '.']


def plot_hypnogram(exp, output_file=None):
    """Plot a hypnogram corresponding to the given experiment."""
    # FIXME Retrieve this in a better way, taking alignment into account
    data = exp._data
    times = list(data.index - 1)
    # Convert each state to a number for plotting, according to mapping above
    states = np.array([states_to_num[s] for s in data.Sleep_wake])
    # Plot the timeseries, topped by a box of different colour for each state
    plt.step(times, states, where="post")
    for i in states_to_num.values():
        # Select the points at which we want to plot the box for this state.
        # For a box to be plotted, both its endpoints need to be selected,
        # so we use the condition "the state is i OR the previous state was i".
        span = np.logical_or(states == i,
                             np.hstack(([False], states[:-1] == i)))
        plt.fill_between(times, states, 0,
                         where=span, step="post",
                         color=colours[i-1], hatch=patterns[i-1])
    # Set the location and label of the y-axis ticks based on the same mapping
    # (the sorting is probably not needed)
    labels, ticks = zip(*sorted(states_to_num.items(), key=itemgetter(1)))
    plt.yticks(ticks=ticks, labels=labels)
    plt.xlabel('Time (epochs)')
    if output_file:
        print(f"Saving hypnogram at {output_file}.")
        plt.savefig(output_file)
    else:
        plt.show()


def entry_point():
    parser = ArgumentParser(
        description="Create a hypnogram from a patient's sleep data")
    parser.add_argument("input", help="The data file (.xlsx) to plot")
    args = parser.parse_args()
    input_path = Path(args.input)
    if input_path.suffix != '.xlsx':
        raise ValueError(f"{input_path.name}: The input file should be "
                          "an .xlsx file")
    exp = Experiment(*load_file(args.input))
    output_file = f"hypnogram_{input_path.stem}.png"
    plot_hypnogram(exp, output_file)


if __name__ == "__main__":
    entry_point()
