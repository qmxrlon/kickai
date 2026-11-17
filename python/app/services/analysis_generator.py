"""
AI Match Analysis Generator
============================
Generates human-readable German-language match analysis text
based on prediction results and team context.
"""

from typing import Any


class AnalysisGenerator:
    def generate(self, request: Any, result: dict[str, Any]) -> str:
        home = request.home_team_name
        away = request.away_team_name

        hw = result["home_win_prob"]
        dp = result["draw_prob"]
        aw = result["away_win_prob"]
        conf = result["confidence_score"]
        xgh  = result.get("xg_home", 0)
        xga  = result.get("xg_away", 0)
        btts = result.get("btts_prob", 0)
        mu   = result.get("predicted_goals", 0)

        # Determine tone
        dominant = home if hw > aw else away
        underdog  = away if hw > aw else home
        fav_prob  = max(hw, aw)

        # Confidence label
        if conf >= 70:   conf_label = "hoher"
        elif conf >= 50: conf_label = "mittlerer"
        else:             conf_label = "geringer"

        over25 = result.get("over_under_probs", {}).get("over_25_prob", 0) or 0

        lines = [
            f"**{home} vs {away}**",
            "",
            f"Unser Modell bewertet dieses Spiel mit {conf_label} Konfidenz ({conf:.0f}%).",
            "",
            f"Die Wahrscheinlichkeit eines **Heimsieges** liegt bei {hw*100:.0f}%, ein **Unentschieden** "
            f"bei {dp*100:.0f}% und ein **Auswärtssieg** bei {aw*100:.0f}%.",
            "",
        ]

        if fav_prob > 0.55:
            lines.append(
                f"{dominant} ist als Favorit eingestuft und hat statistisch deutlich mehr Chancen "
                f"auf einen Sieg als {underdog}."
            )
        else:
            lines.append(
                "Dieses Spiel ist statistisch sehr ausgeglichen — beide Teams haben realistische Siegchancen."
            )

        lines += [
            "",
            f"Die Expected-Goals-Prognose beträgt **{xgh:.2f} xG** für {home} und **{xga:.2f} xG** für {away}, "
            f"was einer Gesamterwartung von **{mu:.1f} Toren** entspricht.",
            "",
        ]

        if over25 > 0.6:
            lines.append(
                f"Mit einer Wahrscheinlichkeit von {over25*100:.0f}% für Over 2,5 Tore "
                "ist eine torreiche Partie zu erwarten."
            )
        elif over25 < 0.4:
            lines.append(f"Das Modell tendiert zu einer torarmen Begegnung (Under 2,5: {(1-over25)*100:.0f}%).")

        if btts > 0.6:
            lines.append(f"Mit {btts*100:.0f}% Wahrscheinlichkeit treffen beide Teams (BTTS Ja).")
        elif btts < 0.35:
            lines.append(f"Mindestens eines der Teams dürfte kein Tor erzielen (BTTS Nein: {(1-btts)*100:.0f}%).")

        lines += [
            "",
            f"*KI-Empfehlung: {result.get('recommended_bet', '–')}*",
            "",
            "_Diese Analyse basiert ausschließlich auf statistischen Modellen "
            "und stellt keine Wettempfehlung im rechtlichen Sinne dar._",
        ]

        return "\n".join(lines)
