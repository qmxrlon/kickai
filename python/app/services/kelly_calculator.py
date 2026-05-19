"""
Kelly Criterion Utility
=======================
Fractional Kelly (25%) for conservative stake sizing.
"""

KELLY_FRACTION = 0.25


def kelly_fraction(win_probability: float, decimal_odds: float = 2.0) -> float:
    """
    Calculate fractional Kelly stake as a proportion of bankroll.

    Args:
        win_probability: Estimated probability of winning (0–1)
        decimal_odds:    Bookmaker's decimal odds for the bet (default 2.0 = evens)

    Returns:
        Recommended fraction of bankroll to stake (0–1), clamped to [0, 0.25]
    """
    if decimal_odds <= 1.0 or win_probability <= 0:
        return 0.0

    b = decimal_odds - 1.0          # net odds
    q = 1.0 - win_probability
    full_kelly = (b * win_probability - q) / b
    frac = max(0.0, full_kelly * KELLY_FRACTION)

    # Cap at 25% of bankroll even with very high confidence
    return round(min(frac, 0.25), 4)
