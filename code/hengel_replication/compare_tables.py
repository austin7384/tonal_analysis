#!/usr/bin/env python3
"""
Compare replication .tex table files against the original paper's .tex files.

Handles replication tables that have an extra "LLM Readability" row added
alongside the original 5 readability measures. Comparison is label-matched:
rows present in the original are found in the replication by variable label,
and their numerical values are compared. LLM-only rows are noted but not flagged
as errors.

Usage (from tonal_analysis root):
    python code/hengel_replication/compare_tables.py [--tolerance FLOAT]

Output:
    outputs/table_comparison_report.md
Exit code:
    0 if all matched, 1 if any differences found
"""

import re
import sys
import argparse
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPLICATION_DIR = Path("outputs/tables/tex")
ORIGINAL_DIRS = [
    Path("/Users/austincoffelt/readability/0-tex/generated"),
    Path("/Users/austincoffelt/readability/0-tex/fixed"),
]
OUTPUT_REPORT = Path("outputs/table_comparison_report.md")
DEFAULT_TOLERANCE = 0.005

# Normalize label synonyms to a canonical form
LABEL_SYNONYMS: dict[str, str] = {
    "no. observations": "no. obs.",
    "no. obs":          "no. obs.",
    "no. obs.":         "no. obs.",
}


# ---------------------------------------------------------------------------
# LaTeX parsing helpers
# ---------------------------------------------------------------------------

def strip_latex_markup(text: str) -> str:
    """Remove LaTeX commands, keeping human-readable text content."""
    # \mrow{width}{text} → text
    text = re.sub(r'\\mrow\{[^}]*\}\{([^}]*)\}', r'\1', text)
    # \crcell[opt]{width}{text} → text
    text = re.sub(r'\\crcell(?:\[[^\]]*\])?\{[^}]*\}\{([^}]*)\}', r'\1', text)
    # \textit{text}, \textbf{text}, etc.
    text = re.sub(r'\\text(?:it|bf|rm|tt|sc)\{([^}]*)\}', r'\1', text)
    # \item, \tiny, \footnotesize, etc. (no argument)
    text = re.sub(r'\\[a-zA-Z@]+(?:\[[^\]]*\])?(?:\{[^}]*\})*', '', text)
    # Remove braces and math delimiters
    text = re.sub(r'[{}$]', '', text)
    return text.strip()


def normalize_label(label: str) -> str:
    """Normalize a row label for matching across files."""
    label = strip_latex_markup(label)
    label = re.sub(r'\s+', ' ', label).strip().lower()
    return LABEL_SYNONYMS.get(label, label)


def extract_cell_values(cells: list[str]) -> list[tuple[float, str]]:
    """
    Extract (number, significance_stars) pairs from a list of table cells.

    Handles: 1.25**, (0.53), 9,117, -0.08
    Empty cells and checkmark cells produce no output.
    """
    combined = ' '.join(cells)
    # Match: optional minus, digits (possibly with thousand-separator commas),
    # optional decimal part, optionally followed by significance stars
    pattern = r'(-?\d{1,3}(?:,\d{3})*(?:\.\d+)?)(\*{0,3})'
    results = []
    for m in re.finditer(pattern, combined):
        num_str = m.group(1).replace(',', '')
        stars = m.group(2)
        results.append((float(num_str), stars))
    return results


# ---------------------------------------------------------------------------
# Row parsing
# ---------------------------------------------------------------------------

def parse_table_rows(content: str) -> list[dict]:
    """
    Parse a .tex file's tabular body into a flat list of row dicts.

    Each dict has:
        label     – normalized label (empty string if no label cell)
        raw_label – human-readable label (stripped of LaTeX markup)
        values    – list of (float, stars) extracted from data cells
        is_se     – True if this is a standard-error row (blank label + parens)
    """
    tabular_match = re.search(
        r'\\begin\{tabular\}[^\n]*\n(.*?)\\end\{tabular\}',
        content, re.DOTALL,
    )
    if not tabular_match:
        return []

    body = tabular_match.group(1)

    # Split rows on \\ (LaTeX row terminator).  Note: \\[-0.1cm] inside cell
    # content also triggers a split; those fragments get filtered out below.
    row_texts = re.split(r'\\\\', body)

    rows: list[dict] = []
    for raw_row in row_texts:
        # Skip rows that are purely structural (rules, cmidrule, etc.)
        if re.search(r'\\(?:toprule|midrule|bottomrule|cmidrule|hline)', raw_row):
            continue
        # Skip header rows with multiple \multicolumn (column span headers)
        if raw_row.count('\\multicolumn') > 1:
            continue

        cells = raw_row.split('&')
        if len(cells) < 2:
            continue

        label_cell = cells[0].strip()
        data_cells = cells[1:]
        data_text = ' '.join(data_cells)

        # A standard-error row has a blank label and parenthesized values
        is_se = (not label_cell and bool(re.search(r'\(', data_text)))

        label = normalize_label(label_cell)
        raw_label = strip_latex_markup(label_cell).strip()
        values = extract_cell_values(data_cells)

        if label or values:
            rows.append({
                'label':     label,
                'raw_label': raw_label,
                'values':    values,
                'is_se':     is_se,
            })

    return rows


def build_data_entries(rows: list[dict]) -> dict[str, list[dict]]:
    """
    Group flat row list into entries keyed by normalized label.

    Each entry: {'raw_label': str, 'coefs': [(float, stars)], 'ses': [(float, stars)]}

    Returns dict mapping label -> list of entries, to handle tables (like Table-J.3)
    where the same row label appears multiple times across different blocks.

    SE rows (blank label + parens) are attached to the preceding labeled row.
    """
    entries: dict[str, list[dict]] = {}
    current_label: Optional[str] = None
    current_idx: int = -1

    for row in rows:
        if row['label'] and not row['is_se']:
            current_label = row['label']
            if current_label not in entries:
                entries[current_label] = []
            entries[current_label].append({
                'raw_label': row['raw_label'],
                'coefs':     row['values'],
                'ses':       [],
            })
            current_idx = len(entries[current_label]) - 1
        elif row['is_se'] and current_label and current_label in entries:
            entries[current_label][current_idx]['ses'] = row['values']

    return entries


# ---------------------------------------------------------------------------
# Numeric comparison
# ---------------------------------------------------------------------------

def compare_value_lists(
    orig: list[tuple[float, str]],
    repl: list[tuple[float, str]],
    tolerance: float,
) -> list[dict]:
    """Return a list of difference dicts for any mismatched values."""
    diffs: list[dict] = []
    n = min(len(orig), len(repl))
    for i in range(n):
        o_num, o_stars = orig[i]
        r_num, r_stars = repl[i]
        num_diff = abs(o_num - r_num)
        if num_diff > tolerance or o_stars != r_stars:
            diffs.append({
                'col':  i + 1,
                'orig': f"{o_num}{o_stars}",
                'repl': f"{r_num}{r_stars}",
                'diff': num_diff,
            })
    if len(orig) != len(repl):
        diffs.append({
            'col':  'length',
            'orig': str(len(orig)),
            'repl': str(len(repl)),
            'diff': abs(len(orig) - len(repl)),
        })
    return diffs


# ---------------------------------------------------------------------------
# File-level comparison
# ---------------------------------------------------------------------------

def find_original_file(filename: str) -> Optional[Path]:
    for d in ORIGINAL_DIRS:
        p = d / filename
        if p.exists():
            return p
    return None


def compare_pair(repl_path: Path, orig_path: Path, tolerance: float) -> dict:
    """
    Compare one replication .tex file against its original counterpart.

    Returns a result dict with:
        filename, diffs, missing_in_repl, repl_only, orig_label_count
    """
    repl_entries = build_data_entries(parse_table_rows(repl_path.read_text()))
    orig_entries = build_data_entries(parse_table_rows(orig_path.read_text()))

    file_diffs: list[dict] = []
    missing_in_repl: list[str] = []
    repl_only: list[str] = []

    for label, orig_list in orig_entries.items():
        repl_list = repl_entries.get(label, [])
        for i, orig_entry in enumerate(orig_list):
            raw = orig_entry['raw_label'] or label
            if i < len(repl_list):
                repl_entry = repl_list[i]
                coef_diffs = compare_value_lists(orig_entry['coefs'], repl_entry['coefs'], tolerance)
                se_diffs   = compare_value_lists(orig_entry['ses'],   repl_entry['ses'],   tolerance)
                if coef_diffs or se_diffs:
                    display = f"{raw} (occurrence {i + 1})" if len(orig_list) > 1 else raw
                    file_diffs.append({
                        'label':      display,
                        'coef_diffs': coef_diffs,
                        'se_diffs':   se_diffs,
                    })
            else:
                missing_in_repl.append(raw)

    for label, repl_list in repl_entries.items():
        orig_count = len(orig_entries.get(label, []))
        for i, repl_entry in enumerate(repl_list):
            if i >= orig_count:
                repl_only.append(repl_entry['raw_label'] or label)

    orig_label_count = sum(len(v) for v in orig_entries.values())
    return {
        'filename':         repl_path.name,
        'diffs':            file_diffs,
        'missing_in_repl':  missing_in_repl,
        'repl_only':        repl_only,
        'orig_label_count': orig_label_count,
    }


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------

def write_report(
    results: list[dict],
    repl_only_files: list[str],
    output_path: Path,
) -> int:
    """Write a Markdown comparison report. Returns number of files with diffs."""
    n_compared    = len(results)
    n_with_diffs  = sum(1 for r in results if r['diffs'] or r['missing_in_repl'])
    n_exact       = n_compared - n_with_diffs

    lines: list[str] = [
        "# Table Comparison Report",
        "",
        "## Summary",
        f"- **Files compared**: {n_compared}",
        f"- **Files matched exactly**: {n_exact}",
        f"- **Files with differences**: {n_with_diffs}",
        f"- **Replication-only files** (no original counterpart): {len(repl_only_files)}",
        "",
    ]

    if n_with_diffs > 0:
        lines += ["## Files with Differences", ""]
        for r in sorted(results, key=lambda x: x['filename']):
            if not r['diffs'] and not r['missing_in_repl']:
                continue
            lines.append(f"### {r['filename']}")
            lines.append("")
            if r['missing_in_repl']:
                labels = ', '.join(f"`{l}`" for l in r['missing_in_repl'])
                lines.append(f"**Rows in original missing from replication**: {labels}")
                lines.append("")
            if r['repl_only']:
                labels = ', '.join(f"`{l}`" for l in r['repl_only'])
                lines.append(f"**Rows only in replication** (LLM additions, not flagged): {labels}")
                lines.append("")
            for d in r['diffs']:
                lines.append(f"**Row: `{d['label']}`**")
                lines.append("")
                if d['coef_diffs']:
                    lines.append("Coefficient differences:")
                    lines.append("| Col | Original | Replication | Diff |")
                    lines.append("|-----|----------|-------------|------|")
                    for diff in d['coef_diffs']:
                        lines.append(
                            f"| {diff['col']} | `{diff['orig']}` | `{diff['repl']}` | {diff['diff']:.4f} |"
                        )
                    lines.append("")
                if d['se_diffs']:
                    lines.append("Standard error differences:")
                    lines.append("| Col | Original | Replication | Diff |")
                    lines.append("|-----|----------|-------------|------|")
                    for diff in d['se_diffs']:
                        lines.append(
                            f"| {diff['col']} | `{diff['orig']}` | `{diff['repl']}` | {diff['diff']:.4f} |"
                        )
                    lines.append("")
    else:
        lines += ["## Result", "", "All compared files matched exactly.", ""]

    lines += [
        "---",
        "",
        "## Replication-Only Files (No Original Counterpart)",
        "",
    ]
    for f in sorted(repl_only_files):
        lines.append(f"- `{f}`")
    lines.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text('\n'.join(lines))
    return n_with_diffs


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compare replication .tex tables against original paper tables."
    )
    parser.add_argument(
        "--tolerance", type=float, default=DEFAULT_TOLERANCE,
        help=f"Max allowed numeric difference (default: {DEFAULT_TOLERANCE})",
    )
    args = parser.parse_args()

    if not REPLICATION_DIR.exists():
        print(f"ERROR: Replication directory not found: {REPLICATION_DIR}", file=sys.stderr)
        sys.exit(2)

    repl_files = sorted(REPLICATION_DIR.glob("Table-*.tex"))
    results: list[dict] = []
    repl_only_files: list[str] = []

    for repl_path in repl_files:
        orig_path = find_original_file(repl_path.name)
        if orig_path is None:
            repl_only_files.append(repl_path.name)
        else:
            results.append(compare_pair(repl_path, orig_path, args.tolerance))

    n_with_diffs = write_report(results, repl_only_files, OUTPUT_REPORT)

    print(f"Compared {len(results)} file pairs against originals.")
    print(f"  Exact matches:             {len(results) - n_with_diffs}")
    print(f"  Files with differences:    {n_with_diffs}")
    print(f"  Replication-only files:    {len(repl_only_files)}")
    print(f"\nReport written to: {OUTPUT_REPORT}")

    sys.exit(1 if n_with_diffs > 0 else 0)


if __name__ == "__main__":
    main()
