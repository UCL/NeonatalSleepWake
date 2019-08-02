import pytest

from ..common import check_state, SLEEP_STATE, SleepStateNotRecognisedError


def test_check_state_invalid_state():
    with pytest.raises(SleepStateNotRecognisedError):
        check_state("NotAnActualState")


def test_check_state_valid_states():
    for state_name in SLEEP_STATE.categories:
        check_state(state_name)
