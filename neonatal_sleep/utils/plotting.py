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
top_level = max(states_to_num.values()) + 1
colours = ["red", "blue", "green", "yellow"]


def plot_hypnogram(exp):
    """Plot a hypnogram corresponding to the given experiment."""
    # FIXME Retrieve this in a better way, taking alignment into account
    runs = exp._runs
    times = list(runs.Start) + [runs.Stop.iloc[-1]]
    # Convert each state to a number for plotting, according to mapping above
    states = [states_to_num[s] for s in runs.From]
    # Duplicate last state for better plotting and use NumPy for convenience
    num_states = np.array(states + [states[-1]])
    # Plot the timeseries, topped by a box of different colour for each state
    plt.step(times, num_states, where="post")
    for i in states_to_num.values():
        # Select the points at which we want to plot the box for this state.
        # For a box to be plotted, both its endpoints need to be selected,
        # so we use the condition "the state is i OR the previous state was i".
        span = np.logical_or(num_states == i,
                             np.hstack(([False], num_states[:-1] == i)))
        plt.fill_between(times, num_states, top_level,
                         where=span, step="post",
                         color=colours[i], alpha=0.4)
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
