"""
summary_table.py
Generates outputs/tables/tex/Table-S.1.tex: article and NBER working paper
counts by journal, drawn directly from hengel_replication_data.db.
"""
import sqlite3
from pathlib import Path

ROOT = Path(__file__).parents[2]
DB   = ROOT / "data" / "raw" / "hengel_replication_data.db"
OUT  = ROOT / "outputs" / "tables" / "tex" / "Table-S.1.tex"

# Journal display order and LaTeX labels
JOURNAL_ORDER = ["AER", "ECA", "JPE", "QJE", "RES", "P&P"]
JOURNAL_LABEL = {
    "AER": r"\textit{AER}",
    "ECA": r"\textit{ECA}",
    "JPE": r"\textit{JPE}",
    "QJE": r"\textit{QJE}",
    "RES": r"\textit{RES}",
    "P&P": r"\textit{P\&P}",
}

def fetch_counts(db_path):
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    cur.execute("SELECT Journal, COUNT(*) FROM Article GROUP BY Journal")
    articles = dict(cur.fetchall())

    cur.execute("""
        SELECT a.Journal, COUNT(DISTINCT nc.ArticleID)
        FROM Article a
        LEFT JOIN NBERCorr nc ON a.ArticleID = nc.ArticleID
        GROUP BY a.Journal
    """)
    nber = dict(cur.fetchall())

    con.close()
    return articles, nber

def build_latex(rows):
    def fmt(n):
        return f"{n:>5}"

    data_lines = []
    for label, art, nb in rows[:-1]:   # journal rows
        data_lines.append(f"        {label:<16} & {fmt(art)} & {fmt(nb)} \\\\")

    # Total row (preceded by a midrule)
    total_label, total_art, total_nb = rows[-1]
    total_line = f"        {total_label:<16} & {fmt(total_art)} & {fmt(total_nb)} \\\\"

    body = "\n".join(data_lines)

    return rf"""
\begin{{table}}[H]
    \footnotesize
    \centering
    \begin{{threeparttable}}
        \caption{{Article and NBER working paper counts, by journal}}
        \label{{table-s1}}
        \sisetup{{table-figures-decimal=0}}
        \begin{{tabular}}{{lSS}}
            \toprule
            {{Journal}} & {{Articles}} & {{NBER articles}} \\
            \midrule
{body}
            \midrule
{total_line}
            \bottomrule
        \end{{tabular}}
        \begin{{tablenotes}}
            \tiny
            \item \textit{{Notes}}. Counts are from the full Hengel replication database.
            NBER articles are published articles matched to at least one NBER working paper.
            \textit{{AER}}, \textit{{ECA}}, \textit{{JPE}}, and \textit{{QJE}} constitute
            the main analysis sample of 9,117 articles.
            \textit{{RES}} and \textit{{P\&P}} are excluded from the main analysis.
        \end{{tablenotes}}
    \end{{threeparttable}}
\end{{table}}
""".lstrip("\n")

def main():
    articles, nber = fetch_counts(DB)

    rows = []
    for j in JOURNAL_ORDER:
        rows.append((JOURNAL_LABEL[j], articles.get(j, 0), nber.get(j, 0)))

    total_art = sum(r[1] for r in rows)
    total_nb  = sum(r[2] for r in rows)
    rows.append(("Total", total_art, total_nb))

    latex = build_latex(rows)
    OUT.write_text(latex)
    print(f"Written: {OUT}")

    # Quick sanity check
    for label, art, nb in rows:
        print(f"  {label:20s} articles={art:>6,}  nber={nb:>5,}")

if __name__ == "__main__":
    main()
