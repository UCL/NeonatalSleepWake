"""
Utilities for creating plots from experimental data.
"""
import sys
from operator import itemgetter

import matplotlib.pyplot as plt
import numpy as np

from ..load_file import load_file
from ..experiment import Experiment


# Assign lower numbers to "deeper" sleep states so they show up lower in plot
states_to_num = {
    state: depth
    for (depth, state)
    in enumerate(["nREM", "Trans", "REM", "Awake"])
}


def plot_hypnogram(exp):
    """Plot a hypnogram corresponding to the given experiment."""
    # FIXME Retrieve this in a better way, taking alignment into account
    runs = exp._runs
    times = list(runs.Start) + [runs.Stop.iloc[-1]]
    # Convert each state to a number for plotting, according to mapping above
    states = [states_to_num[s] for s in runs.From]
    # Duplicate last state for better plotting and use NumPy for convenience
    num_states = np.array(states + [states[-1]])
    # Plot the timeseries and fill in boxes where state is "at least" sleeping
    plt.step(times, num_states, where="post")
    plt.fill_between(times, num_states, 1, where=num_states > 1, step="post")
    # Set the location and label of the y-axis ticks based on the same mapping
    # (the sorting is probably not needed)
    labels, ticks = zip(*sorted(states_to_num.items(), key=itemgetter(1)))
    plt.yticks(ticks=ticks, labels=labels)
    plt.xlabel('Time (epochs)')
    plt.show()


def entry_point():
    # FIXME Make this less rough...
    exp = Experiment(*load_file(sys.argv[1]))
    plot_hypnogram(exp)


if __name__ == "__main__":
    entry_point()
