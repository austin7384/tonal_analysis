# -*- coding: utf-8 -*-
import sqlite3
import pandas as pd

# Export all tables in read_excluding_confidential.db to facilitate future third-party research.
conn = sqlite3.connect('~/tonal_analysis/data/raw/hengel_replication_data.db')
tables = ['Article', 'Author', 'AuthorCorr', 'Children', 'EditorBoard', 'Inst', 'InstCorr', 'JEL', 'NBER', 'NBERCorr', 'ReadStat', 'NBERStat']
for table in tables:
    query = "SELECT * FROM {};".format(table)
    pd.read_sql_query(query, conn).to_csv('0-data/fixed/read_excluding_confidential-csv/{}.csv'.format(table), index=False)
conn.close()

# Connect to read.db database.
conn = sqlite3.connect('0-data/fixed/read.db')

# Export raw data for editorial clusters.
query = "SELECT * FROM EditorBoard;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/editors.csv', index=False)
query = "SELECT ArticleID, Journal, Volume, Issue, Part FROM Article;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/article_editors.csv', index=False)

# Export raw article-level data.
query = """
    SELECT ArticleID, Journal, FirstPage, PubDate
    	FROM Article
    	WHERE Journal <> 'P&P'
    			AND Title NOT LIKE '%corrigendum%'
    			AND Title NOT LIKE '%erratum%'
    			AND Title NOT LIKE '%: a correction%'
    			AND Title NOT LIKE '%: correction%';
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/article_main.csv', index=False)

# Export raw authorcorr data.
query = "SELECT ArticleID, AuthorID FROM Author NATURAL JOIN AuthorCorr;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/authorcorr.csv', index=False)

# Export raw article-level data with author sex.
query = """
    SELECT ArticleID, AuthorID, Journal, FirstPage, PubDate, Female
    	FROM Article
    	NATURAL JOIN (SELECT ArticleID, AuthorID, CASE WHEN Sex='Female' THEN 1 ELSE 0 END AS Female FROM Author NATURAL JOIN AuthorCorr);
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/article_gender.csv', index=False)

# Export raw data for institutional rank.
query = """
    SELECT InstID, CAST(SUBSTR(PubDate, 1, 4) AS INTEGER) AS Year, COUNT(DISTINCT(ArticleID)) AS ArticleN
    FROM Article
    	NATURAL JOIN InstCorr
    	WHERE Journal <> 'P&P'
    		AND Title NOT LIKE '%corrigendum%'
    		AND Title NOT LIKE '%erratum%'
    		AND Title NOT LIKE '%: a correction%'
    		AND Title NOT LIKE '%: correction%'
    GROUP BY InstID, Year;
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/inst_rank.csv', index=False)
query = """
    SELECT InstID, ArticleID, AuthorID, CAST(SUBSTR(PubDate, 1, 4) AS INTEGER) AS Year
    	FROM InstCorr
    	NATURAL JOIN Article;
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/inst_rank_author.csv', index=False)

# Export raw data for publication order.
query = "SELECT ArticleID, Journal, Volume, Issue, FirstPage FROM Article;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/pub_order.csv', index=False)

# Export raw data for native English speakers.
query = """
	SELECT ArticleID, MAX(CASE WHEN nativelanguage='English' THEN 1 ELSE 0 END) AS NativeEnglish
		FROM AuthorCorr
		NATURAL JOIN Author
		GROUP BY ArticleID;
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/english.csv', index=False)

# Export raw data for theory/empirical dummy variables.
query = "SELECT Article.ArticleID AS ArticleID, JEL FROM Article LEFT JOIN JEL ON Article.ArticleID=JEL.ArticleID;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/theory_emp.csv', index=False)

# Export raw primary JEL data.
query = """
    SELECT ArticleID, SUBSTR(JEL, 1, 1) AS JEL
    	FROM JEL
    	NATURAL JOIN Article
    	WHERE Language = 'English';
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/primary_jel.csv', index=False)

# Export raw tertiary JEL data.
query = """
    SELECT ArticleID, JEL
    	FROM JEL
    	NATURAL JOIN Article
    	WHERE Language = 'English';
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/tertiary_jel.csv', index=False)

# Export raw article-level data with P&P.
query = """
    SELECT ArticleID, Journal, Volume, Issue, FirstPage, StatName, PubDate, CiteCount, LastPage,
    CASE WHEN (StatName='flesch_score' OR StatName LIKE '%_count') THEN StatValue ELSE -1 * StatValue END AS _,
    CAST(STRFTIME('%Y', PubDate) AS INTEGER) AS Year
    	FROM Article
    	NATURAL JOIN ReadStat
    	WHERE
    		Language = 'English'
    		AND Title NOT LIKE '%corrigendum%'
    		AND Title NOT LIKE '%erratum%'
    		AND Title NOT LIKE '%: a correction%'
    		AND Title NOT LIKE '%: correction%';
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/article_pp.csv', index=False)

# Export raw article-level data for all top-five journals.
query = """
    SELECT ArticleID, Journal, Volume, Issue, FirstPage, PubDate, CiteCount,
    LastPage, CAST(STRFTIME('%Y', PubDate) AS INTEGER) AS Year
    	FROM Article;
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/article_top5.csv', index=False)

# Export raw NBER data.
query = """
    SELECT ArticleID, NberID, WPDate, StatName,
    CASE WHEN (StatName='flesch_score' OR StatName LIKE '%_count') THEN StatValue ELSE -1 * StatValue END AS nber_
    	FROM NBER
    	NATURAL JOIN NBERCorr
    	NATURAL JOIN NBERStat;
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/nber.csv', index=False)

# Export raw review time data.
query = """
    SELECT ArticleID, PubDate, AuthorCorr.AuthorID AS AuthorID,
    	CAST(STRFTIME('%Y', PubDate) AS INTEGER) AS Year, Received, Accepted, CiteCount,
    	CAST(STRFTIME('%Y', Received) AS INTEGER) AS ReceivedYear,
    	CAST(STRFTIME('%Y', Accepted) AS INTEGER) AS AcceptedYear, FirstPage, LastPage,
    	LastPage - FirstPage AS PageN, (JULIANDAY(Accepted) - JULIANDAY(Received)) / 30 AS ReviewLength,
    	CASE WHEN Children.Year BETWEEN CAST(STRFTIME('%Y', Received) AS INTEGER) AND CAST(STRFTIME('%Y', Accepted) AS INTEGER) THEN 1 ELSE 0 END AS Birth,
    	CAST(CASE WHEN Received-Children.Year>=0 THEN Received-Children.Year ELSE NULL END AS INTEGER) AS ChildReceived,
    	CASE WHEN Accepted-Children.Year>=0 THEN Accepted-Children.Year ELSE NULL END AS ChildAccepted
    		FROM Article
    		NATURAL JOIN AuthorCorr
    		LEFT OUTER JOIN Children ON AuthorCorr.AuthorID=Children.AuthorID
    	WHERE
    		Received IS NOT NULL
    		AND PubDate < '2016-01-01'
    		AND Title NOT LIKE '%corrigendum%'
    		AND Title NOT LIKE '%erratum%'
    		AND Title NOT LIKE '%: a correction%'
    		AND Title NOT LIKE '%: correction%';
"""
pd.read_sql_query(query, conn).to_csv('0-data/generated/time.csv', index=False)

# Export author names for matched pairs (Table J.2).
query = "SELECT AuthorID, AuthorName FROM Author;"
pd.read_sql_query(query, conn).to_csv('0-data/generated/author_names.csv', index=False)

conn.close()

