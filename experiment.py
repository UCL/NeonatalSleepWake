import numpy as np


class Experiment:
    """A class to represent the results from an individual patient."""
    def __init__(self, data, metadata):
        self._data = data
        self._metadata = metadata
        # Would this be convenient?
        for key, value in metadata.items():
            setattr(self, key, value)

    def number_epochs(self):
        return len(self._data)

    def count(self, state):
        """Return how many times a sleep state occurs in this experiment."""
        sleep_states = self._data.iloc[:, 0]
        if state not in sleep_states.dtype.categories:
            raise ValueError(f"Unrecognised sleep state: {state}")
        return (sleep_states == state).sum()

    def durations(self, state):
        """Compute how long the patient spends in the given state each time.

        Returns a list of durations in epochs.
        """
        # Find the duration of all consecutive sequences in the dataframe
        # then store them as tuples of (state, duration) in a new series
        # TODO This can be precomputed at creation to avoid repeating it
        self._data["subgroups"] = (self._data.Sleep_wake
                                   != self._data.Sleep_wake.shift(1)
                                   ).cumsum()
        runs = self._data.groupby("subgroups", as_index=False).apply(
            lambda x: (x.iloc[0, 0], len(x)))
        # Filter only the runs of the state we want
        return [length for group_state, length in runs if group_state == state]

    def count_transitions(self, from_states, to_states):
        """Return how many transitions occur between the given states."""
        # TODO This could be more efficient by storing the start and end state
        #      after each run (as in durations)
        temp = np.array([self._data.iloc[:, 0],
                         self._data.iloc[:, 0].shift(-1)]).T
        matching = np.logical_and(
            np.isin(temp[:, 0], from_states),
            np.isin(temp[:, 1], to_states)
        )
        # Only keep real transitions, i.e. when the state changes
        matching = np.logical_and(matching, temp[:, 0] != temp[:, 1])
        # Return the number of transitions found
        return matching.sum()

    def count_held(self):
        return self._data.Held_yes_no.sum()

    def count_painful(self):
        return self._data.Painful_stimulation_yes_no.sum()

    def count_somatosensory(self):
        return self._data.Somatosensory_stimulation_yes_no.sum()
