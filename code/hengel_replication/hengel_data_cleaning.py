# -*- coding: utf-8 -*-
import os
import numpy as np
import pandas as pd

DATA_DIR = os.path.expanduser('~/tonal_analysis/data/raw/hengel_replication_data')
OUT_DIR  = os.path.expanduser('~/tonal_analysis/data/raw/hengel_generated')
os.makedirs(OUT_DIR, exist_ok=True)

def read(name):
    return pd.read_csv(os.path.join(DATA_DIR, f'{name}.csv'))

def out(name):
    return os.path.join(OUT_DIR, f'{name}.csv')

# ── Load all tables ────────────────────────────────────────────────────────────
article      = read('Article')
author       = read('Author')
author_corr  = read('AuthorCorr')
children     = read('Children')
editor_board = read('EditorBoard')
inst_corr    = read('InstCorr')
jel          = read('JEL')
nber         = read('NBER')
nber_corr    = read('NBERCorr')
nber_stat    = read('NBERStat')
read_stat    = read('ReadStat')
llm_eval     = read('LLM_evaluations')
nber_llm     = read('NBER_LLM_evaluations')

# ── Rename LLM criteria to Stata-compatible snake_case names ──────────────────
# Original names contain spaces and special characters (&, /) that are invalid
# in Stata variable names after reshape wide. llm_readability is already valid.
LLM_RENAME = {
    'Modal Verb Strength':            'llm_modal_verb',
    'Hedging Frequency & Type':       'llm_hedging',
    'Qualifier Density':              'llm_qualifier',
    'Acknowledgement of Limitations': 'llm_ack_limits',
    'Caution-Signaling Connectors':   'llm_caution',
    'Assertiveness & Voice':          'llm_assertiveness',
    'Active/Passive Voice Ratio':     'llm_active_passive',
    'Sentence Length & Directness':   'llm_directness',
    'Imperative-Form Occurrence':     'llm_imperative',
    'Pronoun Commitment':             'llm_pronoun',
    'Novelty-Claim Strength':         'llm_novelty',
    'Jargon/Technicality Density':    'llm_jargon',
    'Emotional Valence':              'llm_emotional',
    'Evidence & Citation Usage':      'llm_evidence',
    'Practical/Impact Orientation':   'llm_practical',
    # llm_readability is already correctly named
}
llm_eval = llm_eval.rename(columns=LLM_RENAME)
nber_llm = nber_llm.rename(columns=LLM_RENAME)

# ── Title exclusion filter (used in multiple outputs) ─────────────────────────
EXCL_PATTERNS = ['corrigendum', 'erratum', ': a correction', ': correction']

def filter_titles(df, col='Title'):
    mask = pd.Series(True, index=df.index)
    for pat in EXCL_PATTERNS:
        mask &= ~df[col].str.lower().str.contains(pat, na=False)
    return df[mask]

# ── Sign-flip logic for the underscore column ─────────────────────────────────
# Convention (matching Hengel): higher _ = easier/clearer to read.
#
# Hengel readability scores negated (higher raw = harder):
#   fleschkincaid_score, gunningfog_score, smog_score, dalechall_score
# Not negated (higher raw = easier, or raw counts):
#   flesch_score, *_count
#
# LLM criteria negated (higher raw = harder):
#   Jargon/Technicality Density  (10 = dense undefined jargon)
# LLM criteria NOT negated (higher raw = easier/more direct, or no clear direction):
#   llm_readability              (10 = incredibly easy to understand)
#   Sentence Length & Directness (10 = very short sentences)
#   Active/Passive Voice Ratio   (10 = 90% active voice)
#   Hedging Frequency & Type     (10 = no hedges)
#   Qualifier Density            (10 = no qualifiers)
#   Caution-Signaling Connectors (10 = none)
#   All remaining criteria       (no unambiguous hard/easy direction)
LLM_STAT_NAMES      = set(llm_eval.columns) - {'ArticleID'}
NBER_LLM_STAT_NAMES = set(nber_llm.columns) - {'NberID'}
LLM_NEGATE = {'llm_jargon'}  # Jargon/Technicality Density: higher = denser = harder

def compute_underscore(df, llm_names):
    is_negative = (
        # Hengel readability composites where higher = harder
        (~(df['StatName'] == 'flesch_score') & ~df['StatName'].str.endswith('_count') & ~df['StatName'].isin(llm_names))
        # LLM criteria where higher = harder
        | df['StatName'].isin(LLM_NEGATE)
    )
    return df['StatValue'].where(~is_negative, -df['StatValue'])

# ── Editorial clusters ────────────────────────────────────────────────────────
editor_board.to_csv(out('editors'), index=False)
article[['ArticleID', 'Journal', 'Volume', 'Issue', 'Part']].to_csv(out('article_editors'), index=False)

# ── Article main (no P&P, no errata) ─────────────────────────────────────────
article_main = filter_titles(article[article['Journal'] != 'P&P'])
article_main[['ArticleID', 'Journal', 'FirstPage', 'PubDate']].to_csv(out('article_main'), index=False)

# ── AuthorCorr ────────────────────────────────────────────────────────────────
authorcorr = author[['AuthorID']].merge(author_corr, on='AuthorID')
authorcorr[['ArticleID', 'AuthorID']].to_csv(out('authorcorr'), index=False)

# ── Article gender ────────────────────────────────────────────────────────────
author_sex = author[['AuthorID', 'Sex']].copy()
author_sex['Female'] = (author_sex['Sex'] == 'Female').astype(int)
acorr_sex  = author_corr.merge(author_sex[['AuthorID', 'Female']], on='AuthorID')
article_gender = article.merge(acorr_sex[['ArticleID', 'AuthorID', 'Female']], on='ArticleID')
article_gender[['ArticleID', 'AuthorID', 'Journal', 'FirstPage', 'PubDate', 'Female']].to_csv(out('article_gender'), index=False)

# ── Institutional rank ────────────────────────────────────────────────────────
art_inst = filter_titles(article[article['Journal'] != 'P&P']).merge(inst_corr, on='ArticleID')
art_inst['Year'] = pd.to_datetime(art_inst['PubDate']).dt.year
inst_rank = (art_inst.groupby(['InstID', 'Year'])['ArticleID']
             .nunique().reset_index().rename(columns={'ArticleID': 'ArticleN'}))
inst_rank.to_csv(out('inst_rank'), index=False)

inst_rank_author = inst_corr.merge(article[['ArticleID', 'PubDate']], on='ArticleID')
inst_rank_author['Year'] = pd.to_datetime(inst_rank_author['PubDate']).dt.year
inst_rank_author[['InstID', 'ArticleID', 'AuthorID', 'Year']].to_csv(out('inst_rank_author'), index=False)

# ── Publication order ─────────────────────────────────────────────────────────
article[['ArticleID', 'Journal', 'Volume', 'Issue', 'FirstPage']].to_csv(out('pub_order'), index=False)

# ── Native English speakers ───────────────────────────────────────────────────
author_lang = author[['AuthorID', 'NativeLanguage']].merge(author_corr, on='AuthorID')
author_lang['NativeEnglish'] = (author_lang['NativeLanguage'] == 'English').astype(int)
english = author_lang.groupby('ArticleID')['NativeEnglish'].max().reset_index()
english.to_csv(out('english'), index=False)

# ── Theory/empirical dummy ────────────────────────────────────────────────────
theory_emp = article[['ArticleID']].merge(jel[['ArticleID', 'JEL']], on='ArticleID', how='left')
theory_emp.to_csv(out('theory_emp'), index=False)

# ── Primary JEL (first character) ────────────────────────────────────────────
primary_jel = jel.merge(article[['ArticleID', 'Language']], on='ArticleID').query("Language == 'English'").copy()
primary_jel['JEL'] = primary_jel['JEL'].str[0]
primary_jel[['ArticleID', 'JEL']].to_csv(out('primary_jel'), index=False)

# ── Tertiary JEL ──────────────────────────────────────────────────────────────
tertiary_jel = jel.merge(article[['ArticleID', 'Language']], on='ArticleID').query("Language == 'English'")
tertiary_jel[['ArticleID', 'JEL']].to_csv(out('tertiary_jel'), index=False)

# ── article_pp: readability stats + LLM evaluations (long format) ─────────────
llm_long      = llm_eval.melt(id_vars='ArticleID', var_name='StatName', value_name='StatValue')
read_stat_all = pd.concat([read_stat, llm_long], ignore_index=True)

art_filtered = filter_titles(article[article['Language'] == 'English'])
article_pp   = art_filtered.merge(read_stat_all, on='ArticleID')
article_pp['_']    = compute_underscore(article_pp, LLM_STAT_NAMES)
article_pp['Year'] = pd.to_datetime(article_pp['PubDate']).dt.year
article_pp[['ArticleID', 'Journal', 'Volume', 'Issue', 'FirstPage', 'StatName',
            'PubDate', 'CiteCount', 'LastPage', '_', 'Year']].to_csv(out('article_pp'), index=False)

# ── article_top5 ──────────────────────────────────────────────────────────────
article_top5 = article.copy()
article_top5['Year'] = pd.to_datetime(article_top5['PubDate']).dt.year
article_top5[['ArticleID', 'Journal', 'Volume', 'Issue', 'FirstPage',
              'PubDate', 'CiteCount', 'LastPage', 'Year']].to_csv(out('article_top5'), index=False)

# ── NBER: readability stats + LLM evaluations (long format) ──────────────────
nber_llm_long  = nber_llm.melt(id_vars='NberID', var_name='StatName', value_name='StatValue')
nber_stat_all  = pd.concat([nber_stat, nber_llm_long], ignore_index=True)

nber_merged       = nber.merge(nber_corr, on='NberID').merge(nber_stat_all, on='NberID')
nber_merged['nber_'] = compute_underscore(nber_merged, NBER_LLM_STAT_NAMES)
nber_merged[['ArticleID', 'NberID', 'WPDate', 'StatName', 'nber_']].to_csv(out('nber'), index=False)

# ── Review time ───────────────────────────────────────────────────────────────
art_time = article[article['Received'].notna() & (article['PubDate'] < '2016-01-01')]
art_time = filter_titles(art_time)

time_df = art_time.merge(author_corr[['ArticleID', 'AuthorID']], on='ArticleID')
# Rename Children.Year to avoid collision with the computed Year column
time_df = time_df.merge(children[['AuthorID', 'Year']].rename(columns={'Year': 'ChildYear'}),
                        on='AuthorID', how='left')

time_df['Year']         = pd.to_datetime(time_df['PubDate']).dt.year
time_df['ReceivedYear'] = pd.to_datetime(time_df['Received']).dt.year
time_df['AcceptedYear'] = pd.to_datetime(time_df['Accepted']).dt.year
time_df['PageN']        = time_df['LastPage'] - time_df['FirstPage']
time_df['ReviewLength'] = (pd.to_datetime(time_df['Accepted']) - pd.to_datetime(time_df['Received'])).dt.days / 30

cy = time_df['ChildYear']
time_df['Birth'] = (cy.notna() & cy.between(time_df['ReceivedYear'], time_df['AcceptedYear'])).astype(int)
time_df['ChildReceived'] = (time_df['ReceivedYear'] - cy).where((time_df['ReceivedYear'] - cy) >= 0)
time_df['ChildAccepted'] = (time_df['AcceptedYear'] - cy).where((time_df['AcceptedYear'] - cy) >= 0)

time_df[['ArticleID', 'PubDate', 'AuthorID', 'Year', 'Received', 'Accepted', 'CiteCount',
         'ReceivedYear', 'AcceptedYear', 'FirstPage', 'LastPage', 'PageN', 'ReviewLength',
         'Birth', 'ChildReceived', 'ChildAccepted']].to_csv(out('time'), index=False)

# ── Author names ──────────────────────────────────────────────────────────────
author[['AuthorID', 'AuthorName']].to_csv(out('author_names'), index=False)
