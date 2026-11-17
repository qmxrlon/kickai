import pytest

from app.services.kelly_calculator import kelly_fraction


def test_no_edge_means_no_stake():
    # 50 % at even odds has zero expected value
    assert kelly_fraction(0.5, 2.0) == 0.0


def test_positive_edge_uses_quarter_kelly():
    # Full Kelly: (1 * 0.6 - 0.4) / 1 = 0.2 → 25 % of that = 0.05
    assert kelly_fraction(0.6, 2.0) == pytest.approx(0.05)


def test_negative_edge_is_clamped_to_zero():
    assert kelly_fraction(0.3, 2.0) == 0.0


@pytest.mark.parametrize("prob, odds", [(0.0, 2.0), (-0.1, 2.0), (0.7, 1.0), (0.7, 0.5)])
def test_invalid_inputs_return_zero(prob, odds):
    assert kelly_fraction(prob, odds) == 0.0


def test_stake_is_capped():
    assert kelly_fraction(0.999, 100.0) <= 0.25
