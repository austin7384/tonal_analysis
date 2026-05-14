# Fit the GST-style phrase-ranking lasso (Stage 2, R) for the LLM Readability
# criterion, v2 — residualized on Table-5-llm col. (5) controls. Consumes the
# three staging CSVs written by build_phrase_matrix_residualized.py in
# data/processed/sg_phrase_analysis_residualized/, fits Taddy's Distributed
# Multinomial Regression (Poisson-approximation gamma-lasso, BIC-tuned) with a
# single binary group covariate (top vs. bottom quintile of the residualized
# Readability score), and writes a ranked phrase list to
# outputs/tables/csv/sg_phrase_ranking_readability_residualized.csv.
#
# zeta_j > 0  -> phrase appears more in high-residual-Readability abstracts
# zeta_j < 0  -> phrase appears more in low-residual-Readability abstracts

# ── 1. Package check + install ────────────────────────────────────────────────
required_cran <- c("Matrix", "data.table", "gamlr")

for (pkg in required_cran) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s from CRAN...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

if (!requireNamespace("distrom", quietly = TRUE)) {
  cat("Installing distrom from CRAN...\n")
  ok <- tryCatch({
    install.packages("distrom", repos = "https://cloud.r-project.org")
    requireNamespace("distrom", quietly = TRUE)
  }, error = function(e) FALSE, warning = function(w) FALSE)

  if (!isTRUE(ok)) {
    cat("CRAN install failed; falling back to GitHub (TaddyLab/distrom)...\n")
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes", repos = "https://cloud.r-project.org")
    }
    remotes::install_github("TaddyLab/distrom")
  }
}

for (pkg in c(required_cran, "distrom")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("Package %s could not be installed. Aborting.", pkg))
  }
}

suppressPackageStartupMessages({
  library(Matrix)
  library(data.table)
  library(gamlr)
  library(distrom)
})

cat("Packages OK\n")

# ── 2. Path setup ─────────────────────────────────────────────────────────────
ROOT     <- path.expand("~/tonal_analysis")
IN_DIR   <- file.path(ROOT, "data/processed/sg_phrase_analysis_residualized")
OUT_DIR  <- file.path(ROOT, "outputs/tables/csv")
OUT_FILE <- file.path(OUT_DIR, "sg_phrase_ranking_readability_residualized.csv")

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# ── 3. Load staging data ──────────────────────────────────────────────────────
docs    <- fread(file.path(IN_DIR, "documents.csv"))
phrases <- fread(file.path(IN_DIR, "phrases.csv"))
counts_long <- fread(file.path(IN_DIR, "phrase_counts.csv"))

cat(sprintf("Documents:     %d\n", nrow(docs)))
cat(sprintf("Phrases:       %d\n", nrow(phrases)))
cat(sprintf("Count triples: %d\n", nrow(counts_long)))

# ── 4. Build sparse count matrix ──────────────────────────────────────────────
N_docs <- nrow(docs)
V      <- nrow(phrases)

counts <- sparseMatrix(
  i    = counts_long$doc_idx + 1L,
  j    = counts_long$phrase_idx + 1L,
  x    = counts_long$count,
  dims = c(N_docs, V)
)

cat(sprintf("counts dim:    %d x %d\n", nrow(counts), ncol(counts)))

# ── 5. Fit DMR ────────────────────────────────────────────────────────────────
covars <- data.frame(group = docs$group)

cat("Fitting DMR (this may take a few minutes)...\n")
t0  <- Sys.time()
fit <- dmr(cl = NULL, covars = covars, counts = counts, verb = 1)
t1  <- Sys.time()
cat(sprintf("DMR elapsed:   %s\n",
            format(round(difftime(t1, t0, units = "secs"), 1))))

# ── 6. Extract zeta vector ────────────────────────────────────────────────────
B    <- coef(fit)
zeta <- as.numeric(B["group", ])

cat(sprintf("zeta length:   %d\n", length(zeta)))
stopifnot(length(zeta) == V)

# ── 7. Assemble + sort ranking ────────────────────────────────────────────────
ranking <- data.table(
  phrase_idx  = phrases$phrase_idx,
  phrase      = phrases$phrase,
  n_docs      = phrases$n_docs,
  total_count = phrases$total_count,
  zeta        = zeta
)
ranking[, direction := ifelse(zeta > 0, "high_read",
                       ifelse(zeta < 0, "low_read", "zero"))]
ranking[, abs_zeta := abs(zeta)]
setorder(ranking, -abs_zeta)
ranking[, abs_zeta := NULL]

# ── 8. Write output ───────────────────────────────────────────────────────────
fwrite(ranking, OUT_FILE)
cat(sprintf("Wrote %s (%d rows)\n", OUT_FILE, nrow(ranking)))

# Round-trip sanity check
sum_in  <- sum(phrases$total_count)
sum_out <- sum(ranking$total_count)
cat(sprintf("total_count round-trip: in=%d  out=%d  match=%s\n",
            sum_in, sum_out, identical(sum_in, sum_out)))

cat("Done.\n")
