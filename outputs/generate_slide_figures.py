"""
Generate presentation-quality figures for "In a Different Voice" slides.
Warm Professional palette: DeepNavy=#2E4057, Teal=#048A81, WarmOrange=#E85D04,
SoftPurple=#9D4EDD, WarmGray=#6C757D, LightGray=#E9ECEF, Cream=#FBF8F1,
DeepRed=#D62828, Gold=#D4A03A, SoftWhite=#FAFAFA
"""

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
import os

# ── palette ──────────────────────────────────────────────────────────────────
DEEP_NAVY   = "#2E4057"
TEAL        = "#048A81"
WARM_ORANGE = "#E85D04"
SOFT_PURPLE = "#9D4EDD"
WARM_GRAY   = "#6C757D"
LIGHT_GRAY  = "#E9ECEF"
CREAM       = "#FBF8F1"
DEEP_RED    = "#D62828"
GOLD        = "#D4A03A"
SOFT_WHITE  = "#FAFAFA"

OUT = "slides_figures"
os.makedirs(OUT, exist_ok=True)

plt.rcParams.update({
    "font.family":      "sans-serif",
    "font.sans-serif":  ["Helvetica", "Arial", "DejaVu Sans"],
    "text.color":       DEEP_NAVY,
    "axes.labelcolor":  DEEP_NAVY,
    "xtick.color":      DEEP_NAVY,
    "ytick.color":      DEEP_NAVY,
    "axes.spines.top":  False,
    "axes.spines.right":False,
    "axes.edgecolor":   WARM_GRAY,
    "axes.linewidth":   0.8,
    "axes.grid":        False,
})

# =============================================================================
# Figure A: Readability validation
# Binned means (approx) from Figure 1 in paper
# =============================================================================
def fig_readability_validation():
    fig, axes = plt.subplots(1, 2, figsize=(11, 5))
    fig.patch.set_facecolor(SOFT_WHITE)

    ratio = [0.25, 0.50, 0.75, 1.00]

    # Flesch Reading Ease (binned means, from paper Figure 1 a)
    flesch = [38.8, 39.5, 40.8, 42.6]
    # LLM Readability (binned means, from paper Figure 1 b)
    llm    = [6.69, 6.95, 7.25, 7.42]

    for ax, y_vals, label, beta, se, ylabel, color in [
        (axes[0], flesch, "Flesch Reading Ease",  "1.92", "(0.60)", "Flesch Reading Ease", TEAL),
        (axes[1], llm,   "LLM Readability Score", "0.96", "(0.07)", "LLM Readability",     WARM_ORANGE),
    ]:
        ax.set_facecolor(SOFT_WHITE)

        # Regression line
        m, b = np.polyfit(ratio, y_vals, 1)
        x_line = np.linspace(0.15, 1.10, 100)
        ax.plot(x_line, m * x_line + b, color=color, linewidth=2.2, zorder=1)

        # Data points
        ax.scatter(ratio, y_vals, color=color, s=80, zorder=2, edgecolors="white", linewidths=0.8)

        # Beta annotation
        ax.text(0.97, 0.10, f"$\\hat{{\\beta}}$ = {beta}\n({se})",
                transform=ax.transAxes, ha="right", va="bottom",
                fontsize=13, color=DEEP_NAVY)

        ax.set_xlabel("Female author ratio", fontsize=14)
        ax.set_ylabel(ylabel, fontsize=14)
        ax.tick_params(labelsize=12)
        ax.spines["left"].set_color(WARM_GRAY)
        ax.spines["bottom"].set_color(WARM_GRAY)

    axes[0].set_title("(a) Flesch Reading Ease",  fontsize=15, color=DEEP_NAVY, pad=10)
    axes[1].set_title("(b) LLM Readability Score", fontsize=15, color=DEEP_NAVY, pad=10)

    fig.suptitle("Both measures rise with female authorship share",
                 fontsize=16, fontweight="bold", color=DEEP_NAVY, y=1.01)

    fig.tight_layout()
    path = os.path.join(OUT, "fig_readability_validation.pdf")
    fig.savefig(path, bbox_inches="tight", facecolor=SOFT_WHITE)
    plt.close(fig)
    print(f"Saved {path}")


# =============================================================================
# Figure B: Mean differences across 16 criteria (standardized)
# Values approximate from Figure 2 in paper
# =============================================================================
def fig_mean_differences():
    # Sorted by magnitude (descending), sign preserved
    criteria = [
        "Readability",
        "Jargon\n(less dense)",
        "Active voice",
        "Pronoun\ncommitment",
        "Directness",
        "Evidence &\ncitation",
        "Ack. limitations",
        "Practical\norientation",
        "Imperative\nform",
        "Novelty\nclaims",
        "Caution\nconnectors",
        "Hedging",
        "Modal verb",
        "Assertiveness",
        "Qualifier\ndensity",
        "Emotional\nvalence",
    ]
    diffs = [0.55, 0.48, 0.44, 0.40, 0.38, 0.35,
             0.18, 0.12, -0.03, -0.05, -0.03, -0.02,
             0.02, 0.02, 0.02, -0.02]
    # Approximate 95% CI half-widths
    ci   = [0.06, 0.07, 0.07, 0.08, 0.07, 0.07,
            0.07, 0.06, 0.02, 0.07, 0.08, 0.07,
            0.08, 0.06, 0.07, 0.02]

    n = len(criteria)
    y = np.arange(n)

    # Colour: teal for positive, deep red for negative
    colors = [TEAL if d >= 0 else DEEP_RED for d in diffs]

    fig, ax = plt.subplots(figsize=(10, 8))
    fig.patch.set_facecolor(SOFT_WHITE)
    ax.set_facecolor(SOFT_WHITE)

    bars = ax.barh(y, diffs, color=colors, height=0.6, zorder=2)
    ax.errorbar(diffs, y, xerr=ci, fmt="none",
                color=DEEP_NAVY, capsize=3, linewidth=1.2, zorder=3)

    ax.axvline(0, color=DEEP_NAVY, linewidth=0.8, zorder=1)

    ax.set_yticks(y)
    ax.set_yticklabels(criteria, fontsize=11)
    ax.set_xlabel("Female − Male difference (standardized)", fontsize=13)
    ax.set_xlim(-0.25, 0.75)
    ax.tick_params(axis="x", labelsize=12)

    # Divider between "moves" and "doesn't move"
    ax.axhline(7.5, color=WARM_GRAY, linewidth=0.8, linestyle="--", zorder=1)
    ax.text(0.70, 7.6, "Tone dimensions (below)", fontsize=10, color=WARM_GRAY,
            ha="right", va="bottom")

    # Panel labels
    ax.text(0.70, 9.5, "Clarity &\npresentation",
            fontsize=11, color=TEAL, ha="right", va="center", fontweight="bold")
    ax.text(0.70, 3.5, "Tone &\naffect",
            fontsize=11, color=WARM_GRAY, ha="right", va="center", fontweight="bold")

    fig.suptitle("Female-majority teams differ in clarity, not in confidence or emotion",
                 fontsize=14, fontweight="bold", color=DEEP_NAVY, y=1.01)

    fig.tight_layout()
    path = os.path.join(OUT, "fig_mean_differences.pdf")
    fig.savefig(path, bbox_inches="tight", facecolor=SOFT_WHITE)
    plt.close(fig)
    print(f"Saved {path}")


# =============================================================================
# Figure C: Regression coefficients (key criteria, col 1 full sample)
# From Tables 11 and 12
# =============================================================================
def fig_regression_coefficients():
    labels = [
        "Jargon (less dense)",
        "Evidence & citation",
        "Readability",
        "Directness",
        "Ack. limitations",
        "Active voice",
        "Hedging",
        "Assertiveness",
        "Qualifier density",
        "Emotional valence",
        "Novelty claims",
    ]
    coefs = [ 0.52,  0.44,  0.36,  0.27,  0.23,  0.07,
             -0.21, -0.08, -0.02, -0.02, -0.32]
    ses   = [ 0.11,  0.09,  0.07,  0.10,  0.12,  0.10,
              0.11,  0.08,  0.10,  0.02,  0.10]
    sig   = [True,  True,  True,  True,  True,  False,
             True,  False, False, False, True]

    ci95 = [1.96 * s for s in ses]
    n = len(labels)
    y = np.arange(n)

    colors = []
    for c, s in zip(coefs, sig):
        if not s:
            colors.append(WARM_GRAY)
        elif c > 0:
            colors.append(TEAL)
        else:
            colors.append(DEEP_RED)

    fig, ax = plt.subplots(figsize=(9, 7))
    fig.patch.set_facecolor(SOFT_WHITE)
    ax.set_facecolor(SOFT_WHITE)

    for i, (c, ci, col) in enumerate(zip(coefs, ci95, colors)):
        ax.plot([c - ci, c + ci], [i, i], color=col, linewidth=2.0, zorder=2,
                alpha=0.6)
        ax.scatter([c], [i], color=col, s=60, zorder=3, edgecolors="white",
                   linewidths=0.6)

    ax.axvline(0, color=DEEP_NAVY, linewidth=0.9, zorder=1)

    ax.set_yticks(y)
    ax.set_yticklabels(labels, fontsize=12)
    ax.set_xlabel("OLS coefficient on female author ratio", fontsize=13)
    ax.tick_params(axis="x", labelsize=12)
    ax.set_xlim(-0.65, 0.80)

    # Divider between sig and null
    ax.axhline(5.5, color=WARM_GRAY, linewidth=0.8, linestyle="--")

    # Legend
    sig_patch  = mpatches.Patch(color=TEAL,      label="Significant (p<0.10)")
    insig_patch= mpatches.Patch(color=WARM_GRAY, label="Not significant")
    neg_patch  = mpatches.Patch(color=DEEP_RED,  label="Significant, negative")
    ax.legend(handles=[sig_patch, neg_patch, insig_patch],
              fontsize=11, frameon=False, loc="lower right")

    fig.suptitle("Five robust differences: readability, jargon, directness, evidence, novelty",
                 fontsize=13, fontweight="bold", color=DEEP_NAVY, y=1.01)

    fig.tight_layout()
    path = os.path.join(OUT, "fig_regression_coefficients.pdf")
    fig.savefig(path, bbox_inches="tight", facecolor=SOFT_WHITE)
    plt.close(fig)
    print(f"Saved {path}")


# =============================================================================
# Figure D: Robustness — LLM readability coefficient across 6 specifications
# From Tables 6–10 (col 1) in the paper
# =============================================================================
def fig_robustness():
    specs = [
        "Female ratio\n(main)",
        "Majority\nfemale",
        "Any female\nauthor",
        "100\\% female",
        "Solo\nfemale",
        "Senior\nfemale",
    ]
    coefs = [0.36, 0.27, 0.26, 0.35, 0.37, 0.38]
    ses   = [0.07, 0.05, 0.05, 0.08, 0.10, 0.08]
    ci95  = [1.96 * s for s in ses]

    x = np.arange(len(specs))

    fig, ax = plt.subplots(figsize=(10, 5))
    fig.patch.set_facecolor(SOFT_WHITE)
    ax.set_facecolor(SOFT_WHITE)

    ax.bar(x, coefs, color=TEAL, width=0.5, zorder=2, alpha=0.85)
    ax.errorbar(x, coefs, yerr=ci95, fmt="none",
                color=DEEP_NAVY, capsize=4, linewidth=1.4, zorder=3)

    ax.axhline(0, color=DEEP_NAVY, linewidth=0.8)
    ax.set_xticks(x)
    ax.set_xticklabels(specs, fontsize=12)
    ax.set_ylabel("LLM readability coefficient", fontsize=13)
    ax.tick_params(axis="y", labelsize=12)
    ax.set_ylim(-0.05, 0.60)

    fig.suptitle("LLM readability result holds across six authorship definitions",
                 fontsize=14, fontweight="bold", color=DEEP_NAVY, y=1.01)

    fig.tight_layout()
    path = os.path.join(OUT, "fig_robustness.pdf")
    fig.savefig(path, bbox_inches="tight", facecolor=SOFT_WHITE)
    plt.close(fig)
    print(f"Saved {path}")


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    fig_readability_validation()
    fig_mean_differences()
    fig_regression_coefficients()
    fig_robustness()
    print("All figures saved to", os.path.abspath(OUT))
