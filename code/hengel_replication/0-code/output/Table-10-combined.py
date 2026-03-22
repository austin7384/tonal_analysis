"""
Table-10-combined.py

Reads Table-10.tex, Table-10-llm.tex, and Table-10-llm-g3.tex from
outputs/tables/tex/ and produces a single combined table with three panels:
  Panel A: Flesch Reading Ease
  Panel B: LLM Readability
  Panel C: LLM G3 Composite Score
"""

import re
from pathlib import Path

TEX_DIR = Path("~/tonal_analysis/outputs/tables/tex").expanduser()

PANELS = [
    ("Table-10.tex",       "Panel A: Flesch Reading Ease"),
    ("Table-10-llm.tex",   "Panel B: LLM Readability"),
    ("Table-10-llm-g3.tex","Panel C: LLM G3 Composite Score"),
]

NOTE_TEXT = (
    r"Sample 4,289 observations. Panel one displays magnitude of predicted "
    r"\(R_{jP}-R_{jW}\) (the direct effect of peer review) for women and men "
    r"over increasing \(t\). Panel two estimates the marginal effect of an "
    r"article's female ratio (\(\beta_1+\beta_2\times t\)), separately for "
    r"draft papers and published articles. Figures from FGLS estimation "
    r"of~equation~(15), weighted by \(N_{it}\) (see~the data appendix). "
    r"Control variables include citation count (asinh), \(\text{max. }T\) "
    r"(author prominence) and \(\text{max. }t\) (author seniority), native "
    r"speaker and editor and journal-year fixed effects. Standard errors "
    r"clustered by editor and robust to cross-model correlation in parentheses. "
    r"***, ** and * statistically significant at 1\%, 5\% and 10\%, respectively."
)

HEADER_ROW = r"&{\(t=1\)}&{\(t=2\)}&{\(t=3\)}&{\(t=4\text{--}5\)}&{\(t\ge6\)}\\"
COLSPEC    = r"p{3cm}S@{}S@{}S@{}S@{}S@{}S@{}"


def extract_body(tex_path: Path) -> str:
    """Extract tabular body: content between first \\midrule and \\bottomrule."""
    text = tex_path.read_text()
    # Find first \midrule after \toprule
    midrule_pos = text.find(r"\midrule")
    if midrule_pos == -1:
        raise ValueError(f"No \\midrule found in {tex_path}")
    bottom_pos = text.find(r"\bottomrule", midrule_pos)
    if bottom_pos == -1:
        raise ValueError(f"No \\bottomrule found in {tex_path}")
    # Content between first \midrule (exclusive) and \bottomrule (exclusive)
    body = text[midrule_pos + len(r"\midrule"):bottom_pos]
    return body.strip()


def build_combined() -> str:
    panel_blocks = []
    for filename, panel_label in PANELS:
        path = TEX_DIR / filename
        body = extract_body(path)
        ncols = COLSPEC.count("S") + 1  # count data columns + row-label col
        panel_header = (
            f"            \\multicolumn{{6}}{{l}}{{\\textbf{{{panel_label}}}}}\\\\[2pt]\n"
        )
        panel_blocks.append(panel_header + "            " + body.replace("\n", "\n            "))

    combined_body = ("\n            \\midrule\n").join(panel_blocks)

    out = (
        "\\begin{table}[H]\n"
        "    \\footnotesize\n"
        "    \\centering\n"
        "    \\begin{threeparttable}\n"
        "        \\caption{Readability of authors' \\(t\\)th paper (draft and final)}\n"
        "        \\label{table10combined}\n"
        f"        \\begin{{tabular}}{{{COLSPEC}}}\n"
        "            \\toprule\n"
        f"            {HEADER_ROW}\n"
        "            \\midrule\n"
        f"{combined_body}\n"
        "            \\bottomrule\n"
        "        \\end{tabular}\n"
        "        \\begin{tablenotes}\n"
        "            \\tiny\n"
        f"            \\item \\textit{{Notes}}. {NOTE_TEXT}\n"
        "        \\end{tablenotes}\n"
        "    \\end{threeparttable}\n"
        "\\end{table}\n"
    )
    return out


if __name__ == "__main__":
    out_path = TEX_DIR / "Table-10-combined.tex"
    content = build_combined()
    out_path.write_text(content)
    print(f"Written: {out_path}")
